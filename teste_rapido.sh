#!/bin/bash

echo "=============================================="
echo "TESTE RÁPIDO - Verificando se programa funciona"
echo "=============================================="

# Compilar primeiro
echo "Compilando..."
if [ -f "./compile_smart.sh" ]; then
    ./compile_smart.sh
else
    echo "Script de compilação não encontrado. Tentando make..."
    make
fi

# Verificar se executável existe
if [ ! -f "./cudaReduceMax" ] && [ ! -f "./cudaReduceMax_simple" ]; then
    echo "❌ Nenhum executável encontrado!"
    echo "Arquivos disponíveis:"
    ls -la *.cu *.o cudaReduceMax* 2>/dev/null || echo "Nenhum arquivo relacionado"
    exit 1
fi

# Determinar qual executável usar
EXEC=""
if [ -f "./cudaReduceMax_simple" ]; then
    EXEC="./cudaReduceMax_simple"
elif [ -f "./cudaReduceMax" ]; then
    EXEC="./cudaReduceMax"
fi

echo "Usando executável: $EXEC"

echo "=============================================="
echo "TESTE 1: Execução simples com 1000 elementos"
echo "=============================================="

# Teste básico
echo "Executando: $EXEC 1000"
$EXEC 1000

echo ""
echo "=============================================="
echo "TESTE 2: Execução com kernel persistente"
echo "=============================================="

echo "Executando: $EXEC 1000 32"
$EXEC 1000 32

echo ""
echo "=============================================="
echo "TESTE 3: Verificando formato de saída"
echo "=============================================="

echo "Salvando saída em teste_saida.txt..."
$EXEC 10000 > teste_saida.txt 2>&1

echo "Conteúdo do arquivo de saída:"
cat teste_saida.txt

echo ""
echo "Procurando padrões de tempo:"
echo "- Linhas com 'Tempo':"
grep -i "tempo" teste_saida.txt || echo "Nenhuma linha com 'tempo' encontrada"

echo "- Linhas com 'ns':"
grep "ns" teste_saida.txt || echo "Nenhuma linha com 'ns' encontrada"

echo "- Linhas com 'ms':"
grep "ms" teste_saida.txt || echo "Nenhuma linha com 'ms' encontrada"

echo "- Linhas com números:"
grep -E '[0-9]+' teste_saida.txt || echo "Nenhuma linha com números encontrada"

echo ""
echo "=============================================="
echo "RESULTADO DO TESTE"
echo "=============================================="

if grep -q "ns\|ms\|tempo" teste_saida.txt; then
    echo "✅ Programa está gerando saída com tempos!"
    echo "✅ Pronto para executar coleta completa de dados"
    echo ""
    echo "Para executar a coleta completa:"
    echo "./coleta_dados_trabalho.sh"
else
    echo "❌ Programa não está gerando saída de tempo esperada"
    echo "❌ Verifique a implementação ou formato de saída"
fi

echo ""
echo "Arquivo de teste salvo: teste_saida.txt"