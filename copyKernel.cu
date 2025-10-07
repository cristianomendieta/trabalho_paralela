/**
 * CI1009 - PROGRAMAÇÃO PARALELA COM GPUs
 * 2º semestre de 2025
 * UFPR - Prof. W.Zola
 * Autores: Cristiano Creppo Mendieta e Thiago Ruiz
 */

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "helper_cuda.h"
#include "chrono.c"

#define BLOCK_SIZE 1024

__global__ void copyKernel(float* output, float* input, unsigned int n) {
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        output[i] = input[i];
    }
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage: %s <nElements>\n", argv[0]);
        exit(1);
    }
    
    unsigned int nElements = atol(argv[1]);
    int NTIMES = 30;
    
    printf("=== copyKernel - Medição de Largura de Banda ===\n");
    printf("Elementos: %u\n", nElements);
    printf("Repetições: %d\n\n", NTIMES);
    
    int dev = 0;
    cudaSetDevice(dev);
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp, dev);
    printf("GPU: %s\n\n", deviceProp.name);
    
    size_t size = nElements * sizeof(float);
    float* input_h = (float*)malloc(size);
    float* output_h = (float*)malloc(size);
    
    for (unsigned int i = 0; i < nElements; i++) {
        input_h[i] = (float)i;
    }
    
    float *input_d, *output_d;
    checkCudaErrors(cudaMalloc(&input_d, size));
    checkCudaErrors(cudaMalloc(&output_d, size));
    checkCudaErrors(cudaMemcpy(input_d, input_h, size, cudaMemcpyHostToDevice));
    
    int threadsPerBlock = BLOCK_SIZE;
    int blocksPerGrid = (nElements + threadsPerBlock - 1) / threadsPerBlock;
    
    printf("Configuração: %d blocos × %d threads\n", blocksPerGrid, threadsPerBlock);
    
    copyKernel<<<blocksPerGrid, threadsPerBlock>>>(output_d, input_d, nElements);
    cudaDeviceSynchronize();
    
    chronometer_t chrono;
    chrono_reset(&chrono);
    chrono_start(&chrono);
    
    for (int i = 0; i < NTIMES; i++) {
        copyKernel<<<blocksPerGrid, threadsPerBlock>>>(output_d, input_d, nElements);
    }
    cudaDeviceSynchronize();
    chrono_stop(&chrono);
    
    checkCudaErrors(cudaMemcpy(output_h, output_d, size, cudaMemcpyDeviceToHost));
    
    bool correct = true;
    for (unsigned int i = 0; i < nElements && correct; i++) {
        if (output_h[i] != input_h[i]) {
            correct = false;
        }
    }
    
    printf("\n=== RESULTADOS ===\n");
    printf("Validação: %s\n", correct ? "CORRETO" : "INCORRETO");
    
    chrono_report_TimeInLoop(&chrono, "copyKernel", NTIMES);
    
    double total_time_s = chrono_gettotal(&chrono) / 1e9;
    double bytes_transferred = 2.0 * nElements * sizeof(float) * NTIMES;
    double bandwidth_GBs = bytes_transferred / total_time_s / 1e9;
    
    double throughput_GFLOPS = ((double)nElements * NTIMES) / chrono_gettotal(&chrono);
    
    printf("\n=== DESEMPENHO ===\n");
    printf("Largura de Banda: %.2f GB/s\n", bandwidth_GBs);
    printf("Throughput: %.2f GFLOPS\n", throughput_GFLOPS);
    
    double theoretical_bandwidth = 86.4;
    double efficiency = (bandwidth_GBs / theoretical_bandwidth) * 100.0;
    printf("Eficiência: %.1f%% da largura de banda teórica (%.1f GB/s)\n", 
           efficiency, theoretical_bandwidth);
    
    free(input_h);
    free(output_h);
    checkCudaErrors(cudaFree(input_d));
    checkCudaErrors(cudaFree(output_d));
    
    printf("\nDone\n");
    return 0;
}
