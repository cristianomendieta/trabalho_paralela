#!/bin/bash

echo "=============================================="
echo "VERSÃO ROBUSTA - EXECUTAR EXPERIMENTOS"
echo "=============================================="

# 1. Compilar
echo "1. Compilando..."
if [ -f "./compile_smart.sh" ]; then
    ./compile_smart.sh
else
    echo "Tentando make..."
    make clean && make
fi

# 2. Verificar executável
EXEC=""
if [ -f "./cudaReduceMax_simple" ]; then
    EXEC="./cudaReduceMax_simple"
elif [ -f "./cudaReduceMax" ]; then
    EXEC="./cudaReduceMax"
else
    echo "❌ Nenhum executável encontrado!"
    echo "Arquivos disponíveis:"
    ls -la
    exit 1
fi

echo "✅ Usando: $EXEC"

# 3. Testar primeiro com execução simples
echo ""
echo "2. Testando execução..."
echo "Executando: $EXEC 1000"
$EXEC 1000 > teste_simples.txt 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Erro na execução de teste!"
    echo "Saída do erro:"
    cat teste_simples.txt
    exit 1
fi

echo "✅ Teste bem-sucedido. Analisando formato de saída..."
echo "Primeiras linhas do teste:"
head -10 teste_simples.txt

# 4. Executar os 4 experimentos obrigatórios
echo ""
echo "3. Executando experimentos completos..."

declare -a testes=("1M_many:1000000::" "1M_persist:1000000:32" "16M_many:16000000::" "16M_persist:16000000:32")

for teste_info in "${testes[@]}"; do
    IFS=':' read -r nome elementos blocos <<< "$teste_info"
    arquivo="dados_${nome}.txt"
    
    echo "Executando: $nome"
    echo "  Elementos: $elementos"
    echo "  Blocos: $blocos"
    echo "  Arquivo: $arquivo"
    
    if [ -z "$blocos" ]; then
        $EXEC $elementos > $arquivo 2>&1
    else
        $EXEC $elementos $blocos > $arquivo 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ $arquivo criado ($(wc -l < $arquivo) linhas)"
    else
        echo "❌ Erro ao criar $arquivo"
        echo "Conteúdo do erro:"
        cat $arquivo
    fi
done

# 5. Analisar arquivos gerados
echo ""
echo "4. Analisando arquivos gerados..."

for arquivo in dados_*.txt; do
    if [ -f "$arquivo" ]; then
        echo ""
        echo "=== $arquivo ==="
        echo "Linhas: $(wc -l < $arquivo)"
        echo "Contém 'each op takes': $(grep -c 'each op takes' $arquivo)"
        echo "Contém 'deltaT': $(grep -c 'deltaT' $arquivo)"
        echo "Contém 'CORRETO': $(grep -c 'CORRETO' $arquivo)"
        
        # Mostrar linhas relevantes
        echo "Linhas com tempo:"
        grep -n "each op takes\|deltaT" $arquivo | head -3
    fi
done

# 6. Processar dados para CSV baseado no que encontramos
echo ""
echo "5. Processando dados para CSV..."

# Criar CSV
cat > resultados_experimentos.csv << 'EOF'
Teste,Kernel,Elementos,Tempo_Medio_ns,Desvio_Padrao_ns,Tempo_por_Op_ns,Vazao_GOPS,Validacao
EOF

# Mapear arquivos para testes
declare -A mapa_testes
mapa_testes["dados_1M_many.txt"]="1M,Many-threads,1000000"
mapa_testes["dados_1M_persist.txt"]="1M,Persistente,1000000"
mapa_testes["dados_16M_many.txt"]="16M,Many-threads,16000000"
mapa_testes["dados_16M_persist.txt"]="16M,Persistente,16000000"

for arquivo in "${!mapa_testes[@]}"; do
    if [ -f "$arquivo" ]; then
        info="${mapa_testes[$arquivo]}"
        echo "Processando $arquivo ($info)..."
        
        # Extrair dados de múltiplos formatos
        tempo_por_op=""
        tempo_total=""
        
        # Formato 1: "each op takes X ns"
        tempo_por_op=$(grep "each op takes" "$arquivo" | sed 's/.*each op takes \([0-9]*\) ns.*/\1/' | head -1)
        
        # Formato 2: "deltaT(ns): X ns for Y ops"
        if [ -z "$tempo_por_op" ]; then
            linha_delta=$(grep "deltaT(ns):" "$arquivo" | head -1)
            if [ ! -z "$linha_delta" ]; then
                tempo_total=$(echo "$linha_delta" | sed 's/.*deltaT(ns): \([0-9]*\) ns.*/\1/')
                num_ops=$(echo "$linha_delta" | sed 's/.*for \([0-9]*\) ops.*/\1/')
                if [ ! -z "$tempo_total" ] && [ ! -z "$num_ops" ] && [ "$num_ops" != "0" ]; then
                    tempo_por_op=$(echo "$tempo_total $num_ops" | awk '{print int($1/$2)}')
                fi
            fi
        fi
        
        echo "  Tempo por operação encontrado: '$tempo_por_op'"
        
        if [ ! -z "$tempo_por_op" ] && [ "$tempo_por_op" != "0" ]; then
            # Extrair elementos do info
            elementos=$(echo "$info" | cut -d',' -f3)
            
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
            if grep -q "CORRETO\|Test PASSED\|OK" "$arquivo"; then
                validacao="OK"
            else
                validacao="VERIFICAR"
            fi
            
            echo "$info,$stats,$validacao" >> resultados_experimentos.csv
            echo "✅ Processado: $stats"
        else
            echo "❌ Tempo não encontrado, salvando como erro"
            echo "$info,0,0,0,0,SEM_TEMPO" >> resultados_experimentos.csv
        fi
    else
        info="${mapa_testes[$arquivo]}"
        echo "❌ $arquivo não encontrado"
        echo "$info,0,0,0,0,ARQUIVO_NAO_ENCONTRADO" >> resultados_experimentos.csv
    fi
done

echo ""
echo "=============================================="
echo "CONCLUÍDO!"
echo "=============================================="
echo "CSV final:"
cat resultados_experimentos.csv