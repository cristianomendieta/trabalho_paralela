#!/bin/bash

echo "Testando processamento de dados..."

# Função simplificada para teste
processar_dados_teste() {
    local arquivo=$1
    local teste=$2
    local kernel=$3
    local elementos=$4
    
    if [ -f "$arquivo" ]; then
        echo "Processando $arquivo..."
        
        # Extrair tempo por operação
        tempo_por_op=$(grep -A2 "Kernel 1\|Many-threads" "$arquivo" | grep "each op takes" | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
        
        echo "Tempo por op extraído: '$tempo_por_op'"
        
        if [ ! -z "$tempo_por_op" ] && [ "$tempo_por_op" != "" ]; then
            # Calcular usando awk
            stats=$(echo "$tempo_por_op $elementos" | awk '{
                tempo_medio = $1;
                elementos = $2;
                desvio = 0;
                tempo_por_op_calc = tempo_medio / elementos;
                vazao = elementos / tempo_medio * 1000000000;
                printf "%.0f,%.0f,%.6f,%.2f", tempo_medio, desvio, tempo_por_op_calc, vazao
            }')
            
            validacao=$(grep -c "CORRETO\|Test PASSED" "$arquivo")
            if [ "$validacao" -gt 0 ]; then
                validacao_status="OK"
            else
                validacao_status="VERIFICAR"  
            fi
            
            echo "$teste,$kernel,$elementos,$stats,$validacao_status" >> teste_resultado.csv
            echo "✅ Processamento funcionou! Linha: $teste,$kernel,$elementos,$stats,$validacao_status"
        else
            echo "❌ Nenhum tempo encontrado"
            echo "Conteúdo do arquivo:"
            cat "$arquivo"
        fi
    else
        echo "❌ Arquivo não encontrado: $arquivo"
    fi
}

# Criar cabeçalho CSV
echo "Teste,Kernel,Elementos,Tempo_Medio_ns,Desvio_Padrao_ns,Tempo_por_Op_ns,Vazao_GOPS,Validacao" > teste_resultado.csv

# Testar
processar_dados_teste "dados_teste.txt" "TESTE" "Many-threads" "1000000"

echo ""
echo "Resultado salvo em teste_resultado.csv:"
cat teste_resultado.csv