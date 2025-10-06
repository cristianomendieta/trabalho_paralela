#!/bin/bash

# Script para executar copyKernel e medir largura de banda

echo "=== Compilando copyKernel ==="
nvcc -O3 -arch=sm_50 copyKernel.cu -o copyKernel

if [ $? -ne 0 ]; then
    echo "Erro na compilação!"
    exit 1
fi

echo
echo "=== Executando copyKernel para 1M elementos ==="
./copyKernel 1000000 | tee resultados/dados_1M_copy.txt

echo
echo "=== Executando copyKernel para 16M elementos ==="
./copyKernel 16000000 | tee resultados/dados_16M_copy.txt

echo
echo "✓ Resultados salvos em resultados/dados_*M_copy.txt"
