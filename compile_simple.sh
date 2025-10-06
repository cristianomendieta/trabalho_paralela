#!/bin/bash
# Script de compilação para versão simplificada (sem Thrust)
# CI1009 - Programação Paralela com GPUs
# UFPR - 2025

echo "=== Compilando CUDA Reduce Max (Versão Simplificada - Sem Thrust) ==="

# Verificar se o NVCC está disponível
if ! command -v nvcc &> /dev/null; then
    echo "Erro: NVCC não encontrado. Certifique-se de que o CUDA está instalado."
    exit 1
fi

# Compilação específica por máquina
if [ "$(hostname)" = "orval" ]; then
    echo "Compilacao especial na maquina orval (GTX 750ti)"
    echo "nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 cudaReduceMax_simple.cu -o cudaReduceMax"
    nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 cudaReduceMax_simple.cu -o cudaReduceMax
else
    echo "Compilando para maquina generica ($(hostname))"
    echo "nvcc -O3 cudaReduceMax_simple.cu -o cudaReduceMax"
    nvcc -O3 cudaReduceMax_simple.cu -o cudaReduceMax
fi

if [ $? -eq 0 ]; then
    echo "✓ Compilação bem-sucedida!"
    echo "Execute './run_tests.sh' para executar os testes"
    echo ""
    echo "NOTA: Esta versão não inclui comparação com Thrust para evitar"
    echo "      problemas de linkagem, mas implementa os dois kernels solicitados."
else
    echo "✗ Erro na compilação!"
    exit 1
fi