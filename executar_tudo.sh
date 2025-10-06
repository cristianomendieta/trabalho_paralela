#!/bin/bash

echo "=============================================="
echo "SOLUÇÃO RÁPIDA - EXECUTAR EXPERIMENTOS"
echo "=============================================="

# 1. Compilar
echo "1. Compilando..."
if [ -f "./compile_smart.sh" ]; then
    ./compile_smart.sh
else
    echo "Tentando make..."
    make
fi

# 2. Verificar executável
EXEC=""
if [ -f "./cudaReduceMax_simple" ]; then
    EXEC="./cudaReduceMax_simple"
elif [ -f "./cudaReduceMax" ]; then
    EXEC="./cudaReduceMax"
else
    echo "❌ Nenhum executável encontrado!"
    exit 1
fi

echo "✅ Usando: $EXEC"

# 3. Executar os 4 experimentos obrigatórios
echo ""
echo "2. Executando experimentos..."

echo "Teste 1: 1M Many-threads..."
$EXEC 1000000 > dados_1M_many.txt 2>&1
echo "✅ dados_1M_many.txt criado"

echo "Teste 2: 1M Persistente..."
$EXEC 1000000 32 > dados_1M_persist.txt 2>&1
echo "✅ dados_1M_persist.txt criado"

echo "Teste 3: 16M Many-threads..."
$EXEC 16000000 > dados_16M_many.txt 2>&1
echo "✅ dados_16M_many.txt criado"

echo "Teste 4: 16M Persistente..."
$EXEC 16000000 32 > dados_16M_persist.txt 2>&1
echo "✅ dados_16M_persist.txt criado"

# 4. Processar dados para CSV
echo ""
echo "3. Processando dados para CSV..."

# Criar CSV
cat > resultados_experimentos.csv << 'EOF'
Teste,Kernel,Elementos,Tempo_Medio_ns,Desvio_Padrao_ns,Tempo_por_Op_ns,Vazao_GOPS,Validacao
EOF

# Função de processamento simplificada
processar() {
    local arquivo=$1
    local teste=$2
    local kernel=$3
    local elementos=$4
    
    echo "Processando $arquivo..."
    
    if [ -f "$arquivo" ]; then
        echo "  Arquivo existe, analisando conteúdo..."
        
        # Debug: mostrar conteúdo relevante
        echo "  Linhas com 'each op takes':"
        grep -n "each op takes" "$arquivo" || echo "  Nenhuma linha encontrada"
        
        echo "  Linhas com 'deltaT':"
        grep -n "deltaT" "$arquivo" || echo "  Nenhuma linha encontrada"
        
        echo "  Linhas com 'Kernel':"
        grep -n "Kernel" "$arquivo" || echo "  Nenhuma linha encontrada"
        
        # Tentar extrair tempo por operação
        tempo_por_op=$(grep "each op takes" "$arquivo" | sed 's/.*each op takes \([0-9]*\) ns.*/\1/' | head -1)
        
        echo "  Tempo extraído: '$tempo_por_op'"
        
        # Se não encontrou, tentar outros formatos
        if [ -z "$tempo_por_op" ] || [ "$tempo_por_op" = "" ]; then
            echo "  Tentando formato alternativo..."
            
            # Tentar extrair de deltaT
            tempo_total=$(grep "deltaT(ns):" "$arquivo" | sed 's/.*deltaT(ns): \([0-9]*\) ns.*/\1/' | head -1)
            echo "  Tempo total extraído: '$tempo_total'"
            
            if [ ! -z "$tempo_total" ] && [ "$tempo_total" != "" ] && [ "$tempo_total" != "0" ]; then
                # Estimar tempo por operação (assumindo 30 repetições)
                tempo_por_op=$(echo "$tempo_total" | awk '{print int($1/30)}')
                echo "  Tempo por op calculado: '$tempo_por_op'"
            fi
        fi
        
        # Verificar se temos um valor válido
        if [ ! -z "$tempo_por_op" ] && [ "$tempo_por_op" != "" ] && [ "$tempo_por_op" != "0" ]; then
            echo "  Calculando estatísticas com tempo_por_op=$tempo_por_op, elementos=$elementos"
            
            # Calcular estatísticas com verificação de divisão por zero
            stats=$(echo "$tempo_por_op $elementos" | awk '{
                tempo_medio = $1;
                elementos = $2;
                if (tempo_medio > 0 && elementos > 0) {
                    desvio = 0;
                    tempo_por_op_calc = tempo_medio / elementos;
                    vazao = elementos / tempo_medio * 1000000000;
                    printf "%.0f,%.0f,%.6f,%.2f", tempo_medio, desvio, tempo_por_op_calc, vazao
                } else {
                    printf "0,0,0,0"
                }
            }')
            
            # Verificar validação
            if grep -q "CORRETO\|Test PASSED\|OK" "$arquivo"; then
                validacao="OK"
            else
                validacao="VERIFICAR"
            fi
            
            echo "$teste,$kernel,$elementos,$stats,$validacao" >> resultados_experimentos.csv
            echo "✅ $teste $kernel processado: $stats"
        else
            echo "❌ Erro: tempo por operação não encontrado ou inválido"
            echo "  Primeiras 10 linhas do arquivo:"
            head -10 "$arquivo"
            echo "  Últimas 10 linhas do arquivo:"
            tail -10 "$arquivo"
            echo "$teste,$kernel,$elementos,0,0,0,0,SEM_TEMPO" >> resultados_experimentos.csv
        fi
    else
        echo "❌ $arquivo não encontrado"
        echo "$teste,$kernel,$elementos,0,0,0,0,ARQUIVO_NAO_ENCONTRADO" >> resultados_experimentos.csv
    fi
    
    echo ""
}

# Processar todos os arquivos
processar "dados_1M_many.txt" "1M" "Many-threads" "1000000"
processar "dados_1M_persist.txt" "1M" "Persistente" "1000000"  
processar "dados_16M_many.txt" "16M" "Many-threads" "16000000"
processar "dados_16M_persist.txt" "16M" "Persistente" "16000000"

echo ""
echo "=============================================="
echo "CONCLUÍDO!"
echo "=============================================="
echo "Arquivos gerados:"
echo "- dados_1M_many.txt"
echo "- dados_1M_persist.txt"
echo "- dados_16M_many.txt" 
echo "- dados_16M_persist.txt"
echo "- resultados_experimentos.csv"
echo ""
echo "Verificar resultados:"
echo "cat resultados_experimentos.csv"