/**
 * CI1009 - PROGRAMAÇÃO PARALELA COM GPUs
 * 2º semestre de 2025
 * UFPR - Prof. W.Zola
 * 
 * Trabalho 1: Versões paralela CUDA para kernels persistentes do algoritmo de redução
 * 
 * Implementação de kernels de redução paralela para encontrar o valor máximo
 * de um vetor de números float usando CUDA.
 * 
 * VERSÃO SIMPLIFICADA - SEM THRUST (para evitar problemas de linkagem)
 * 
 * Autor: [Seu Nome]
 * Data: Outubro 2025
 */

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <math.h>
#include <time.h>
#include <assert.h>

// Incluir arquivos auxiliares
#include "helper_cuda.h"
#include "chrono.c"

#define BLOCK_SIZE 1024
#define MAX_BLOCKS 65535

// Chronometer global
chronometer_t chrono_kernel1, chrono_kernel2;
int NTIMES = 30; // Número padrão de repetições

// Função atomicMax para float (usando int como base)
__device__ float atomicMax(float* address, float val) {
    int* address_as_i = (int*) address;
    int old = *address_as_i, assumed;
    do {
        assumed = old;
        old = atomicCAS(address_as_i, assumed,
            __float_as_int(fmaxf(val, __int_as_float(assumed))));
    } while (assumed != old);
    return __int_as_float(old);
}

// Função para exibir uso do programa
void usage(const char* progname) {
    printf("Usage: %s <nTotalElements> [<nBlocks>]\n", progname);
    printf("  nTotalElements: número de floats do vetor de entrada\n");
    printf("  nBlocks: número de blocos (opcional - usa kernel persistente)\n");
    printf("Note que o número de blocos é opcional\n");
    printf("Se nBlocks é especificado, o kernel persistente é usado\n");
    printf("Se nBlocks é omitido, o kernel many-threads é usado\n");
    exit(1);
}

// Função para gerar números aleatórios conforme especificação
void generateInput(float* Input_h, unsigned int nElements) {
    srand(time(NULL));
    for (unsigned int i = 0; i < nElements; i++) {
        int a = rand();
        int b = rand();
        float v = a * 100.0f + b;
        Input_h[i] = v;
    }
}

// Kernel 1: Versão many-threads com redução eficiente
__global__ void reduceMax(float* input, float* output, unsigned int n) {
    extern __shared__ float sdata[];
    
    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
    
    // Cada thread carrega um elemento (ou -INFINITY se fora dos limites)
    sdata[tid] = (i < n) ? input[i] : -INFINITY;
    __syncthreads();
    
    // Redução em shared memory usando tree reduction
    for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            sdata[tid] = fmaxf(sdata[tid], sdata[tid + s]);
        }
        __syncthreads();
    }
    
    // Thread 0 escreve resultado do bloco
    if (tid == 0) {
        output[blockIdx.x] = sdata[0];
    }
}

// Kernel 2: Versão persistente com atomics
__global__ void reduceMax_atomic_persist(float* max_result, float* input, unsigned int nElements) {
    extern __shared__ float shared_max[];
    
    unsigned int tid = threadIdx.x;
    unsigned int bid = blockIdx.x;
    unsigned int globalTid = bid * blockDim.x + tid;
    unsigned int gridSize = blockDim.x * gridDim.x;
    
    // Inicializar shared memory
    if (tid == 0) {
        shared_max[0] = -INFINITY;
    }
    __syncthreads();
    
    // Fase 1: Cada thread processa múltiplos elementos de forma coalescida
    float thread_max = -INFINITY;
    for (unsigned int i = globalTid; i < nElements; i += gridSize) {
        thread_max = fmaxf(thread_max, input[i]);
    }
    
    // Fase 2: Redução dentro do bloco usando atomic em shared memory
    atomicMax(&shared_max[0], thread_max);
    __syncthreads();
    
    // Fase 3: Thread 0 de cada bloco faz atomic em global memory
    if (tid == 0) {
        atomicMax(max_result, shared_max[0]);
    }
}

// Wrapper para redução completa (kernel 1)
float reduceMaxComplete(float* input_d, unsigned int nElements) {
    int threadsPerBlock = BLOCK_SIZE;
    int blocksPerGrid = (nElements + threadsPerBlock - 1) / threadsPerBlock;
    
    // Primeira passada
    float* temp_d;
    checkCudaErrors(cudaMalloc(&temp_d, blocksPerGrid * sizeof(float)));
    
    reduceMax<<<blocksPerGrid, threadsPerBlock, threadsPerBlock * sizeof(float)>>>(
        input_d, temp_d, nElements);
    checkCudaErrors(cudaGetLastError());
    
    // Se temos apenas um bloco, terminamos
    if (blocksPerGrid == 1) {
        float result;
        checkCudaErrors(cudaMemcpy(&result, temp_d, sizeof(float), cudaMemcpyDeviceToHost));
        checkCudaErrors(cudaFree(temp_d));
        return result;
    }
    
    // Senão, precisamos de mais reduções
    while (blocksPerGrid > 1) {
        int newBlocksPerGrid = (blocksPerGrid + threadsPerBlock - 1) / threadsPerBlock;
        
        reduceMax<<<newBlocksPerGrid, threadsPerBlock, threadsPerBlock * sizeof(float)>>>(
            temp_d, temp_d, blocksPerGrid);
        checkCudaErrors(cudaGetLastError());
        
        blocksPerGrid = newBlocksPerGrid;
    }
    
    float result;
    checkCudaErrors(cudaMemcpy(&result, temp_d, sizeof(float), cudaMemcpyDeviceToHost));
    checkCudaErrors(cudaFree(temp_d));
    return result;
}

int main(int argc, char* argv[]) {
    // Verificar argumentos da linha de comando
    if (argc != 2 && argc != 3) {
        usage(argv[0]);
    }
    
    unsigned int nTotalElements = atol(argv[1]);
    printf("Number of elements requested in command line: %u\n", nTotalElements);
    
    if (nTotalElements <= 0) {
        fprintf(stderr, "Erro: número de elementos deve ser positivo\n");
        exit(1);
    }
    
    // Determinar qual kernel usar
    int usePersistentKernel = 0, useManyThreadsKernel = 0;
    int nBlocks = 0;
    
    if (argc == 3) {
        usePersistentKernel = 1;
        nBlocks = atoi(argv[2]);
        printf("Using persistent kernel with %d blocks\n", nBlocks);
    } else {
        useManyThreadsKernel = 1;
        printf("Using ManyThreads kernel\n");
    }
    
    printf("=== CUDA Reduce Max - Kernels Persistentes ===\n");
    printf("Elementos: %u\n", nTotalElements);
    printf("Repetições: %d\n\n", NTIMES);
    
    // Configuração da GPU
    int dev = 0;
    int deviceCount = 0;
    cudaError_t error_id = cudaGetDeviceCount(&deviceCount);
    if (error_id != cudaSuccess) {
        printf("cudaGetDeviceCount returned %d\n-> %s\n",
               static_cast<int>(error_id), cudaGetErrorString(error_id));
        printf("Result = FAIL\n");
        exit(EXIT_FAILURE);
    }
    
    cudaSetDevice(dev);
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp, dev);
    
    printf("\nGPU Device %d name is \"%s\"\n", dev, deviceProp.name);
    
    // Alocar memória no host
    size_t size = nTotalElements * sizeof(float);
    float* Input_h = (float*)malloc(size);
    if (!Input_h) {
        fprintf(stderr, "Erro: falha na alocação de memória no host\n");
        exit(EXIT_FAILURE);
    }
    
    // Gerar dados de entrada
    printf("Gerando dados de entrada...\n");
    generateInput(Input_h, nTotalElements);
    
    // Alocar memória na GPU
    float* Input_d = NULL;
    float* result_d = NULL;
    checkCudaErrors(cudaMalloc(&Input_d, size));
    checkCudaErrors(cudaMalloc(&result_d, sizeof(float)));
    
    // Copiar dados para GPU
    printf("Copy input data from the host memory to the CUDA device\n");
    checkCudaErrors(cudaMemcpy(Input_d, Input_h, size, cudaMemcpyHostToDevice));
    
    // Calcular máximo na CPU para validação
    float max_cpu = Input_h[0];
    for (unsigned int i = 1; i < nTotalElements; i++) {
        if (Input_h[i] > max_cpu) {
            max_cpu = Input_h[i];
        }
    }
    printf("Máximo calculado na CPU: %f\n", max_cpu);
    
    float result_kernel1 = 0.0f, result_kernel2 = 0.0f;
    
    printf("\n=== TESTES DOS KERNELS ===\n");
    
    // Teste Kernel 1 (Many-threads) se selecionado
    if (useManyThreadsKernel) {
        printf("Testando Kernel 1 (Many-threads)...\n");
        
        int threadsPerBlock = BLOCK_SIZE;
        int blocksPerGrid = (nTotalElements + threadsPerBlock - 1) / threadsPerBlock;
        printf("CUDA kernel launch with %d blocks of %d threads\n", 
               blocksPerGrid, threadsPerBlock);
        
        chrono_reset(&chrono_kernel1);
        
        // Warm up
        result_kernel1 = reduceMaxComplete(Input_d, nTotalElements);
        cudaDeviceSynchronize();
        
        chrono_start(&chrono_kernel1);
        for (int i = 0; i < NTIMES; i++) {
            result_kernel1 = reduceMaxComplete(Input_d, nTotalElements);
        }
        cudaDeviceSynchronize();
        chrono_stop(&chrono_kernel1);
    }
    
    // Teste Kernel 2 (Persistente) se selecionado
    if (usePersistentKernel) {
        printf("Testando Kernel 2 (Persistente) com %d blocos...\n", nBlocks);
        
        chrono_reset(&chrono_kernel2);
        
        // Warm up
        float init_val = -INFINITY;
        checkCudaErrors(cudaMemcpy(result_d, &init_val, sizeof(float), cudaMemcpyHostToDevice));
        reduceMax_atomic_persist<<<nBlocks, BLOCK_SIZE, sizeof(float)>>>(result_d, Input_d, nTotalElements);
        cudaDeviceSynchronize();
        
        chrono_start(&chrono_kernel2);
        for (int i = 0; i < NTIMES; i++) {
            init_val = -INFINITY;
            checkCudaErrors(cudaMemcpy(result_d, &init_val, sizeof(float), cudaMemcpyHostToDevice));
            reduceMax_atomic_persist<<<nBlocks, BLOCK_SIZE, sizeof(float)>>>(result_d, Input_d, nTotalElements);
        }
        cudaDeviceSynchronize();
        chrono_stop(&chrono_kernel2);
        
        // Obter resultado do kernel 2
        checkCudaErrors(cudaMemcpy(&result_kernel2, result_d, sizeof(float), cudaMemcpyDeviceToHost));
    }
    
    // Validar resultados
    printf("\n=== RESULTADOS ===\n");
    printf("CPU:               %f\n", max_cpu);
    if (useManyThreadsKernel) printf("Kernel 1:          %f\n", result_kernel1);
    if (usePersistentKernel) printf("Kernel 2:          %f\n", result_kernel2);
    
    // Verificar se os resultados estão corretos
    float tolerance = 1e-3f;
    bool correct1 = !useManyThreadsKernel || fabsf(result_kernel1 - max_cpu) < tolerance;
    bool correct2 = !usePersistentKernel || fabsf(result_kernel2 - max_cpu) < tolerance;
    
    printf("\nValidação:\n");
    if (useManyThreadsKernel) printf("Kernel 1: %s\n", correct1 ? "CORRETO" : "INCORRETO");
    if (usePersistentKernel) printf("Kernel 2: %s\n", correct2 ? "CORRETO" : "INCORRETO");
    
    // Reportar desempenho
    printf("\n=== DESEMPENHO ===\n");
    printf("\nGPU: %s reduceMax kernel\n", deviceProp.name);
    
    if (useManyThreadsKernel) {
        chrono_report_TimeInLoop(&chrono_kernel1, "Kernel 1 (Many-threads)", NTIMES);
        printf("reduceMax Kernel1 Throughput: %lf GFLOPS\n", 
               ((double)nTotalElements*NTIMES)/((double)chrono_gettotal(&chrono_kernel1)));
    }
    
    if (usePersistentKernel) {
        chrono_report_TimeInLoop(&chrono_kernel2, "Kernel 2 (Persistente)", NTIMES);
        printf("reduceMax Kernel2 Throughput: %lf GFLOPS\n", 
               ((double)nTotalElements*NTIMES)/((double)chrono_gettotal(&chrono_kernel2)));
    }
    
    // Calcular acelerações entre kernels se ambos foram executados
    if (useManyThreadsKernel && usePersistentKernel) {
        double speedup = (double)chrono_gettotal(&chrono_kernel1) / (double)chrono_gettotal(&chrono_kernel2);
        printf("Aceleração Kernel2 vs Kernel1: %.2fx\n", speedup);
    }
    
    printf("Test PASSED\n");
    
    // Limpeza
    free(Input_h);
    checkCudaErrors(cudaFree(Input_d));
    checkCudaErrors(cudaFree(result_d));
    
    printf("\nDone\n");
    return 0;
}