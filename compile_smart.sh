#!/bin/bash
# Script de compilação inteligente para o projeto CUDA Reduce Max
# Tenta primeiro a versão completa, depois a simplificada se necessário
# CI1009 - Programação Paralela com GPUs
# UFPR - 2025

echo "=== Compilação Inteligente CUDA Reduce Max ==="

# Verificar se o NVCC está disponível
if ! command -v nvcc &> /dev/null; then
    echo "❌ Erro: NVCC não encontrado. Certifique-se de que o CUDA está instalado."
    exit 1
fi

echo "🔄 Tentando compilar versão completa (com Thrust)..."

# Tentar versão completa primeiro
if [ "$(hostname)" = "orval" ]; then
    CMD_FULL="nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -lstdc++ cudaReduceMax.cu -o cudaReduceMax"
    CMD_SIMPLE="nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 cudaReduceMax_simple.cu -o cudaReduceMax"
else
    CMD_FULL="nvcc -O3 -lstdc++ cudaReduceMax.cu -o cudaReduceMax"
    CMD_SIMPLE="nvcc -O3 cudaReduceMax_simple.cu -o cudaReduceMax"
fi

# Tentar versão completa
echo "Comando: $CMD_FULL"
if eval $CMD_FULL 2>/dev/null; then
    echo "✅ Versão completa compilada com sucesso!"
    echo "   - Inclui comparação com Thrust"
    echo "   - Validação completa implementada"
    echo ""
    echo "Execute: './run_tests.sh' para executar os testes"
    exit 0
fi

echo "⚠️  Versão completa falhou (problemas de linkagem com Thrust)"
echo "🔄 Tentando versão simplificada (sem Thrust)..."

# Tentar versão simplificada
echo "Comando: $CMD_SIMPLE"
if eval $CMD_SIMPLE; then
    echo "✅ Versão simplificada compilada com sucesso!"
    echo "   - Implementa os dois kernels solicitados"
    echo "   - Validação com CPU incluída"
    echo "   - Comparação com Thrust removida (evita problemas de linkagem)"
    echo ""
    echo "Execute: './run_tests.sh' para executar os testes"
    echo ""
    echo "📝 NOTA: Para o trabalho, a versão simplificada atende todos os"
    echo "   requisitos do enunciado (kernels many-threads e persistente)"
    exit 0
fi

echo "❌ Ambas as versões falharam na compilação!"
echo ""
echo "🔧 Possíveis soluções:"
echo "   1. Verificar se CUDA Toolkit está completo"
echo "   2. Verificar compatibilidade do gcc"
echo "   3. Tentar: ./compile_alt.sh (múltiplas tentativas)"
echo "   4. Compilação manual com debug:"
echo "      nvcc -v -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 cudaReduceMax_simple.cu -o cudaReduceMax"
exit 1