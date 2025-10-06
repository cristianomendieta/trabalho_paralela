#!/bin/bash
# Script para executar os testes do projeto CUDA Reduce Max
# CI1009 - Programação Paralela com GPUs
# UFPR - 2025

echo "=== Executando Testes CUDA Reduce Max ==="

# Verificar se o executável existe
if [ ! -f "./cudaReduceMax" ]; then
    echo "Erro: Executável não encontrado. Execute './compile.sh' primeiro."
    exit 1
fi

# Verificar se há uma GPU CUDA disponível
nvidia-smi > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Aviso: nvidia-smi não encontrado. Verifique se há uma GPU CUDA disponível."
fi

echo ""
echo "Teste 1: 1M elementos (10^6) - Kernel Many-threads"
echo "=================================================="
./cudaReduceMax 1000000

echo ""
echo ""
echo "Teste 2: 1M elementos (10^6) - Kernel Persistente (32 blocos)"
echo "=============================================================="
./cudaReduceMax 1000000 32

echo ""
echo ""
echo "Teste 3: 16M elementos (16*10^6) - Kernel Many-threads" 
echo "======================================================"
./cudaReduceMax 16000000

echo ""
echo ""
echo "Teste 4: 16M elementos (16*10^6) - Kernel Persistente (32 blocos)"
echo "================================================================="
./cudaReduceMax 16000000 32

echo ""
echo "Testes concluídos!"