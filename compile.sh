#!/bin/bash
# Script de compilação para o projeto CUDA Reduce Max
# CI1009 - Programação Paralela com GPUs
# UFPR - 2025

echo "=== Compilando CUDA Reduce Max ==="

# Verificar se o NVCC está disponível
if ! command -v nvcc &> /dev/null; then
    echo "Erro: NVCC não encontrado. Certifique-se de que o CUDA está instalado."
    exit 1
fi

# Compilação específica por máquina
if [ "$(hostname)" = "orval" ]; then
    echo "Compilacao especial na maquina orval (GTX 750ti)"
    echo "nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -lstdc++ cudaReduceMax.cu -o cudaReduceMax"
    nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -lstdc++ cudaReduceMax.cu -o cudaReduceMax
else
    echo "Compilando para maquina generica ($(hostname))"
    echo "nvcc -O3 -lstdc++ cudaReduceMax.cu -o cudaReduceMax"
    nvcc -O3 -lstdc++ cudaReduceMax.cu -o cudaReduceMax
fi

if [ $? -eq 0 ]; then
    echo "Compilação bem-sucedida!"
    echo "Execute './run_tests.sh' para executar os testes"
else
    echo "Erro na compilação!"
    exit 1
fi