// vectprAdd.cu 
// Alterado por W. Zola (ago 2025)
// para uso em ci1009

/**
 * Copyright 1993-2015 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

/**
 * Vector addition: C = A + B.
 *
 * This sample is a very basic sample that implements element by element
 * vector addition. It is the same as the sample illustrating Chapter 2
 * of the programming guide with some additions like error checking.
 */

#include <stdio.h>

// For the CUDA runtime routines (prefixed with "cuda_")
//#include <cuda_runtime.h>  // comentado por WZ (não precisamos disso!)

//#include <helper_cuda.h>
#include "helper_cuda.h"   // mudado aqui por WZ
#include <assert.h>
#include "chrono.c"

chronometer_t c1;      // declare a chronometer (you could have more!)
int NTIMES = 1; //100;     // NTIMES to repeat our experiments
       
/**
 * CUDA Kernel Device code
 *
 * Computes the vector addition of A and B into C. The 3 vectors have the same
 * number of elements numElements.
 */
__global__ void
vectorAdd(const float *A, const float *B, float *C, int numElements)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;

    if (i < numElements)
    {
        C[i] = A[i] + B[i];
    }
}

/**
 * Host main routine
 */
int
main(int argc, char *argv[])
{
    // Error code to check return values for CUDA calls
    cudaError_t err = cudaSuccess;

    // Print the vector length to be used, and compute its size
    long numElements = 1*1000*1000;   // 1 milhao (default)
    size_t size = numElements * sizeof(float);
    
    if( argc != 3 && argc != 2 ) {
	   printf( "Usage: %s <nElements> [<nBlocks>] \n", argv[0] );
	   printf( "Note that the number of blocks is optional\n" );
           printf( "If nBlocks is specified the persistent kernel is used\n" );
           printf( "If nBlocks is omitted the many-threads kernel is used\n" );
	   exit( 0 ); 
    }

    int usePersistentKernel = 0, useManyThreadsKernel = 0;

    if( argc == 3 ) {
       usePersistentKernel = 1;
       printf( "Using persistent kernel\n" );
       
    } else if( argc == 2 ) {
       useManyThreadsKernel = 1;
       printf( "Using ManyThreads kernel\n" );
    }
    
    numElements = atol(argv[1]);
    printf( "Number of elements requested in command line: %ld \n", 
             numElements );
    size = numElements * sizeof(float);   // size of arrays (in bytes)         

    int dev = 0;            // wz: assume only one GPU for simplicity!
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
    


    
    // Allocate the host input vector A
    float *h_A = (float *)malloc(size);

    // Allocate the host input vector B
    float *h_B = (float *)malloc(size);

    // Allocate the host output vector C
    float *h_C = (float *)malloc(size);

    // Verify that allocations succeeded
    if (h_A == NULL || h_B == NULL || h_C == NULL)
    {
        fprintf(stderr, "Failed to allocate host vectors!\n");
        exit(EXIT_FAILURE);
    }

    // Initialize the host input vectors
    for (int i = 0; i < numElements; ++i)
    {
        h_A[i] = rand()/(float)RAND_MAX;
        h_B[i] = rand()/(float)RAND_MAX;
    }

    // Allocate the device input vector A
    float *d_A = NULL;
    err = cudaMalloc((void **)&d_A, size);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to allocate device vector A (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    // Allocate the device input vector B
    float *d_B = NULL;
    err = cudaMalloc((void **)&d_B, size);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to allocate device vector B (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    // Allocate the device output vector C
    float *d_C = NULL;
    err = cudaMalloc((void **)&d_C, size);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to allocate device vector C (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    // Copy the host input vectors A and B in host memory to the device input vectors in
    // device memory
    printf("Copy input data from the host memory to the CUDA device\n");
    err = cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to copy vector A from host to device (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to copy vector B from host to device (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    int blocksPerGrid;    // number of thread blocks
    if( usePersistentKernel ) {
    
       blocksPerGrid = atoi(argv[2]);   // get number of 
                                   //  persistent thread blocks from command line
       fprintf(stderr, 
                 "codigo da versao persistente NAO feito ainda!\n" );                             
        
    } else {

       // use NVIDIA regular (manythreads) model
       assert( useManyThreadsKernel == 1 );
       // Launch the Vector Add CUDA Kernel
       int threadsPerBlock = 768;     // wz: mudar AQUI para ser o maximo na sua GPU
       blocksPerGrid =(numElements + threadsPerBlock - 1) / threadsPerBlock;
       printf("CUDA kernel launch with %d blocks of %d threads\n", 
               blocksPerGrid, threadsPerBlock);
               
       chrono_reset(&c1);

       chrono_reset(&c1);

       vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, 1);  // WARM UP
       // usar cudaDeviceSynchronize() para esperar término de 
       //   cudaMemcpy e/ou warm-up kernels iniciados anteriormente
       //   ANTES de ligar o cronometro
       cudaDeviceSynchronize();   
       chrono_start(&c1);
         for (int i = 0; i < NTIMES; i++) {

           
               
           vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, numElements);

           err = cudaGetLastError();

           if (err != cudaSuccess)
           {
               fprintf(stderr, "Failed to launch vectorAdd kernel (error code %s)!\n", 
                                cudaGetErrorString(err));
               exit(EXIT_FAILURE);
           }
         }
         cudaDeviceSynchronize();
       chrono_stop(&c1);

    }
    
    // Cálculo da VAZAO
    
      printf("\nGPU: %s vectorAdd kernel\n", 
             deviceProp.name );
      chrono_report_TimeInLoop(&c1, "CUDA kernel launch", NTIMES);
      printf("vectorAdd Throughput: %lf floats/ns (or Giga FLOPS, in this case)\n", 
                ((double)numElements*NTIMES)/((double)chrono_gettotal(&c1)));
                
      // OBS: veja que SAO lidos 2 vetores (A e B) e produzido um terceiro vetor C
      //      entao para calculo da vazao de acesso à memoria devemos 
      //      multiplicar (abaixo) o numero de elementos por 3         
      printf("Global Memory Throughput: %lf GiB/s (Giga Bytes/s)\n", 
                ((double)sizeof(uint32_t)*numElements*3*NTIMES) / ((double)chrono_gettotal(&c1)) );
          
    // Copy the device result vector in device memory to the host result vector
    // in host memory.
    printf("Copy output data from the CUDA device to the host memory\n");
    err = cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to copy vector C from device to host (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    // Verify that the result vector is correct
    for (int i = 0; i < numElements; ++i)
    {
        if (fabs(h_A[i] + h_B[i] - h_C[i]) > 1e-5)
        {
            fprintf(stderr, "Result verification failed at element %d!\n", i);
            exit(EXIT_FAILURE);
        }
    }

    printf("Test PASSED\n");

    // Free device global memory
    err = cudaFree(d_A);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to free device vector A (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaFree(d_B);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to free device vector B (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaFree(d_C);

    if (err != cudaSuccess)
    {
        fprintf(stderr, 
                 "Failed to free device vector C (error code %s)!\n", 
                 cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    // Free host memory
    free(h_A);
    free(h_B);
    free(h_C);

    printf("Done\n");
    return 0;
}

