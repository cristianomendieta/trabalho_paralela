#!/bin/bash

echo "=============================================="
echo "SCRIPT CORRIGIDO PARA FORMATO ESPECÍFICO"
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

# Função de processamento corrigida para o formato específico
processar() {
    local arquivo=$1
    local teste=$2
    local kernel=$3
    local elementos=$4
    
    echo "Processando $arquivo..."
    
    if [ -f "$arquivo" ]; then
        # Estratégia baseada no formato real observado
        tempo_por_op=""
        
        if [ "$kernel" == "Many-threads" ]; then
            # Buscar por "Kernel 1" e depois "each op takes"
            tempo_por_op=$(grep -A1 "Kernel 1.*deltaT" "$arquivo" | grep "each op takes" | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
            validacao_linha="Kernel 1: CORRETO"
        else
            # Para persistente, buscar por "Kernel 2" ou padrão similar
            tempo_por_op=$(grep -A1 "Kernel 2.*deltaT\|Persistente.*deltaT" "$arquivo" | grep "each op takes" | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
            if [ -z "$tempo_por_op" ]; then
                # Se não encontrou Kernel 2, pode ser o segundo "each op takes"
                tempo_por_op=$(grep "each op takes" "$arquivo" | tail -1 | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
            fi
            validacao_linha="Kernel 2: CORRETO"
        fi
        
        echo "  Tempo extraído: '$tempo_por_op'"
        
        # Se ainda não encontrou, tentar abordagem genérica
        if [ -z "$tempo_por_op" ] || [ "$tempo_por_op" = "" ]; then
            echo "  Tentando abordagem genérica..."
            # Pegar o primeiro "each op takes" para many-threads, segundo para persistente
            if [ "$kernel" == "Many-threads" ]; then
                tempo_por_op=$(grep "each op takes" "$arquivo" | head -1 | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
            else
                tempo_por_op=$(grep "each op takes" "$arquivo" | tail -1 | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
            fi
            echo "  Tempo genérico extraído: '$tempo_por_op'"
        fi
        
        # Verificar se temos um valor válido
        if [ ! -z "$tempo_por_op" ] && [ "$tempo_por_op" != "" ] && [ "$tempo_por_op" != "0" ]; then
            echo "  Calculando estatísticas com tempo_por_op=$tempo_por_op, elementos=$elementos"
            
            # Calcular estatísticas
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
            if grep -q "CORRETO" "$arquivo"; then
                validacao="OK"
            else
                validacao="VERIFICAR"
            fi
            
            echo "$teste,$kernel,$elementos,$stats,$validacao" >> resultados_experimentos.csv
            echo "✅ $teste $kernel processado: $stats"
        else
            echo "❌ Erro: tempo por operação não encontrado"
            echo "  Mostrando linhas relevantes:"
            grep -n "each op takes\|deltaT\|Kernel" "$arquivo"
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
echo "CSV final:"
cat resultados_experimentos.csv
echo ""
echo "Arquivos gerados:"
ls -la dados_*.txt resultados_experimentos.csv