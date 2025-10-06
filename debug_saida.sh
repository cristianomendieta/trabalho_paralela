#!/bin/bash

echo "=============================================="
echo "DEBUG - VERIFICANDO FORMATO DA SAÍDA"
echo "=============================================="

# Verificar qual executável usar
EXEC=""
if [ -f "./cudaReduceMax_simple" ]; then
    EXEC="./cudaReduceMax_simple"
elif [ -f "./cudaReduceMax" ]; then
    EXEC="./cudaReduceMax"
else
    echo "❌ Nenhum executável encontrado!"
    exit 1
fi

echo "Executável: $EXEC"

# Executar um teste simples e ver a saída
echo ""
echo "Executando teste simples: $EXEC 1000"
echo "Saída completa:"
echo "=============================================="
$EXEC 1000
echo "=============================================="

echo ""
echo "Executando e salvando em arquivo temporário..."
$EXEC 1000 > debug_saida.txt 2>&1

echo "Conteúdo do arquivo:"
echo "=============================================="
cat debug_saida.txt
echo "=============================================="

echo ""
echo "Análise da saída:"
echo "- Linhas totais: $(wc -l < debug_saida.txt)"
echo "- Linhas com 'ns': $(grep -c 'ns' debug_saida.txt)"
echo "- Linhas com 'Tempo': $(grep -c -i 'tempo' debug_saida.txt)"
echo "- Linhas com 'each op takes': $(grep -c 'each op takes' debug_saida.txt)"
echo "- Linhas com 'deltaT': $(grep -c 'deltaT' debug_saida.txt)"
echo "- Linhas com números: $(grep -c '[0-9]' debug_saida.txt)"

echo ""
echo "Linhas específicas:"
echo "Linhas com 'each op takes':"
grep -n "each op takes" debug_saida.txt || echo "Nenhuma"

echo "Linhas com 'deltaT':"
grep -n "deltaT" debug_saida.txt || echo "Nenhuma"

echo "Linhas com 'Kernel':"
grep -n "Kernel" debug_saida.txt || echo "Nenhuma"

echo "Linhas com 'CORRETO':"
grep -n "CORRETO" debug_saida.txt || echo "Nenhuma"

echo ""
echo "Arquivo salvo como debug_saida.txt para análise"