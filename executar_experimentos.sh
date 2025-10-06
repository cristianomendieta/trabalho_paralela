#!/bin/bash

echo "=============================================="
echo "EXECUTANDO APENAS OS EXPERIMENTOS"
echo "Detectando problema na coleta de dados..."
echo "=============================================="

# Verificar se executável existe
if [ ! -f "./cudaReduceMax" ] && [ ! -f "./cudaReduceMax_simple" ]; then
    echo "❌ Nenhum executável encontrado!"
    echo "Tentando compilar..."
    
    if [ -f "./compile_smart.sh" ]; then
        ./compile_smart.sh
    else
        echo "Script de compilação não encontrado!"
        exit 1
    fi
fi

# Determinar qual executável usar
EXEC=""
if [ -f "./cudaReduceMax_simple" ]; then
    EXEC="./cudaReduceMax_simple"
elif [ -f "./cudaReduceMax" ]; then
    EXEC="./cudaReduceMax"
else
    echo "❌ Nenhum executável funcional encontrado!"
    exit 1
fi

echo "Usando executável: $EXEC"

# Definir número de repetições
NTIMES=30

echo "=============================================="
echo "EXPERIMENTO 1: 1M elementos - Many-threads"
echo "=============================================="

echo "Executando: $EXEC 1000000"
echo "Salvando em: dados_1M_many.txt"
$EXEC 1000000 > dados_1M_many.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Sucesso! Primeiras linhas:"
    head -5 dados_1M_many.txt
else
    echo "❌ Erro na execução"
    cat dados_1M_many.txt
fi

echo ""
echo "=============================================="
echo "EXPERIMENTO 2: 1M elementos - Persistente"
echo "=============================================="

echo "Executando: $EXEC 1000000 32"
echo "Salvando em: dados_1M_persist.txt"
$EXEC 1000000 32 > dados_1M_persist.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Sucesso! Primeiras linhas:"
    head -5 dados_1M_persist.txt
else
    echo "❌ Erro na execução"
    cat dados_1M_persist.txt
fi

echo ""
echo "=============================================="
echo "EXPERIMENTO 3: 16M elementos - Many-threads"
echo "=============================================="

echo "Executando: $EXEC 16000000"
echo "Salvando em: dados_16M_many.txt"
$EXEC 16000000 > dados_16M_many.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Sucesso! Primeiras linhas:"
    head -5 dados_16M_many.txt
else
    echo "❌ Erro na execução"
    cat dados_16M_many.txt
fi

echo ""
echo "=============================================="
echo "EXPERIMENTO 4: 16M elementos - Persistente"
echo "=============================================="

echo "Executando: $EXEC 16000000 32"
echo "Salvando em: dados_16M_persist.txt"
$EXEC 16000000 32 > dados_16M_persist.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Sucesso! Primeiras linhas:"
    head -5 dados_16M_persist.txt
else
    echo "❌ Erro na execução"
    cat dados_16M_persist.txt
fi

echo ""
echo "=============================================="
echo "VERIFICANDO ARQUIVOS GERADOS"
echo "=============================================="

for arquivo in dados_1M_many.txt dados_1M_persist.txt dados_16M_many.txt dados_16M_persist.txt; do
    if [ -f "$arquivo" ]; then
        echo "✅ $arquivo - $(wc -l < $arquivo) linhas"
        echo "   Contém tempo? $(grep -c 'each op takes\|deltaT' $arquivo)"
        echo "   Contém validação? $(grep -c 'CORRETO\|Test PASSED' $arquivo)"
    else
        echo "❌ $arquivo - NÃO ENCONTRADO"
    fi
done

echo ""
echo "=============================================="
echo "EXPERIMENTOS CONCLUÍDOS!"
echo "=============================================="
echo "Agora execute a parte de processamento:"
echo "bash -c 'source coleta_dados_trabalho.sh && echo \"Teste,Kernel,Elementos,Tempo_Medio_ns,Desvio_Padrao_ns,Tempo_por_Op_ns,Vazao_GOPS,Validacao\" > resultados_experimentos.csv && processar_dados \"dados_1M_many.txt\" \"1M\" \"Many-threads\" \"1000000\" && processar_dados \"dados_1M_persist.txt\" \"1M\" \"Persistente\" \"1000000\" && processar_dados \"dados_16M_many.txt\" \"16M\" \"Many-threads\" \"16000000\" && processar_dados \"dados_16M_persist.txt\" \"16M\" \"Persistente\" \"16000000\"'"