#!/bin/bash
# Script para coleta de dados conforme especificações do trabalho
# CI1009 - Programação Paralela com GPUs
# Executa os experimentos obrigatórios: 10^6 e 16*10^6 elementos com nR=30

echo "=========================================="
echo "  COLETA DE DADOS - TRABALHO 1"
echo "  Kernels Persistentes para Redução"
echo "  CI1009 - UFPR - 2025"
echo "=========================================="

# Verificar se algum executável existe e determinar qual usar
EXEC=""
if [ -f "./cudaReduceMax_simple" ]; then
    EXEC="./cudaReduceMax_simple"
    echo "✅ Usando: cudaReduceMax_simple"
elif [ -f "./cudaReduceMax" ]; then
    EXEC="./cudaReduceMax"
    echo "✅ Usando: cudaReduceMax"
else
    echo "❌ Erro: Nenhum executável encontrado."
    echo "Arquivos disponíveis:"
    ls -la *cuda* *ReduceMax* 2>/dev/null || echo "Nenhum arquivo relacionado"
    echo ""
    echo "Execute primeiro: ./compile_smart.sh"
    exit 1
fi

# Arquivo de saída
OUTPUT_FILE="dados_trabalho_$(date +%Y%m%d_%H%M%S).txt"
echo "📁 Salvando resultados em: $OUTPUT_FILE"

# Função para executar e salvar teste
run_test() {
    local elementos=$1
    local blocos=$2
    local descricao="$3"
    
    echo ""
    echo "🔄 Executando: $descricao"
    echo "   Elementos: $elementos"
    if [ -n "$blocos" ]; then
        echo "   Blocos: $blocos (Kernel Persistente)"
    else
        echo "   Kernel Many-threads"
    fi
    echo "   Repetições: 30"
    
    echo "" >> $OUTPUT_FILE
    echo "==========================================" >> $OUTPUT_FILE
    echo "TESTE: $descricao" >> $OUTPUT_FILE
    echo "Elementos: $elementos" >> $OUTPUT_FILE
    if [ -n "$blocos" ]; then
        echo "Blocos: $blocos (Kernel Persistente)" >> $OUTPUT_FILE
    else
        echo "Kernel: Many-threads" >> $OUTPUT_FILE
    fi
    echo "Data/Hora: $(date)" >> $OUTPUT_FILE
    echo "==========================================" >> $OUTPUT_FILE
    
    if [ -n "$blocos" ]; then
        $EXEC $elementos $blocos >> $OUTPUT_FILE 2>&1
    else
        $EXEC $elementos >> $OUTPUT_FILE 2>&1
    fi
    
    echo "✅ Concluído: $descricao"
}

# EXPERIMENTO 1: 10^6 elementos (1 milhão)
echo ""
echo "📊 EXPERIMENTO 1: 1 MILHÃO DE ELEMENTOS"
run_test 1000000 "" "1M elementos - Many-threads"
run_test 1000000 32 "1M elementos - Persistente (32 blocos)"

# EXPERIMENTO 2: 16*10^6 elementos (16 milhões)  
echo ""
echo "📊 EXPERIMENTO 2: 16 MILHÕES DE ELEMENTOS"
run_test 16000000 "" "16M elementos - Many-threads"
run_test 16000000 32 "16M elementos - Persistente (32 blocos)"

echo ""
echo "🎉 COLETA DE DADOS CONCLUÍDA!"
echo "📁 Arquivo gerado: $OUTPUT_FILE"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Abra o arquivo $OUTPUT_FILE"
echo "   2. Extraia os dados de tempo e vazão"
echo "   3. Crie planilha LibreOffice com os dados"
echo "   4. Gere gráficos conforme especificação"
echo "   5. Complete o relatório em PDF"
echo ""
echo "📊 DADOS A EXTRAIR DE CADA TESTE:"
echo "   - Tempo médio (ns)"
echo "   - Vazão (GFLOPS)"  
echo "   - Validação (deve ser CORRETO)"
echo "   - Nome da GPU"
echo ""

# Criar sumário dos dados para facilitar análise
echo "📈 Criando sumário dos dados..."
SUMMARY_FILE="sumario_$(date +%Y%m%d_%H%M%S).txt"

echo "SUMÁRIO DOS EXPERIMENTOS - $(date)" > $SUMMARY_FILE
echo "======================================" >> $SUMMARY_FILE
echo "" >> $SUMMARY_FILE

# Extrair dados principais de cada teste
echo "VAZÃO (GFLOPS):" >> $SUMMARY_FILE
grep "Throughput:" $OUTPUT_FILE >> $SUMMARY_FILE
echo "" >> $SUMMARY_FILE

echo "TEMPO MÉDIO:" >> $SUMMARY_FILE  
grep "each op takes" $OUTPUT_FILE >> $SUMMARY_FILE
echo "" >> $SUMMARY_FILE

echo "VALIDAÇÃO:" >> $SUMMARY_FILE
grep "Validação:" $OUTPUT_FILE >> $SUMMARY_FILE
echo "" >> $SUMMARY_FILE

echo "GPU UTILIZADA:" >> $SUMMARY_FILE
grep "GPU Device.*name" $OUTPUT_FILE >> $SUMMARY_FILE

echo "📁 Sumário salvo em: $SUMMARY_FILE"
echo "✅ Pronto para análise!"

echo "=============================================="
echo "CRIANDO PLANILHA CSV..."
echo "=============================================="

# Criar arquivo CSV para LibreOffice
cat > resultados_experimentos.csv << 'EOF'
Teste,Kernel,Elementos,Tempo_Medio_ns,Desvio_Padrao_ns,Tempo_por_Op_ns,Vazao_GOPS,Validacao
EOF

# Função para calcular estatísticas dos dados
processar_dados() {
    local arquivo=$1
    local teste=$2
    local kernel=$3
    local elementos=$4
    
    if [ -f "$arquivo" ]; then
        echo "Processando $arquivo..."
        echo "Primeiras 20 linhas do arquivo:"
        head -20 "$arquivo"
        echo "---"
        
        # Extrair tempos do formato chrono: "deltaT(ns): XXXXX ns"
        tempo_total=""
        tempo_por_op=""
        
        # Capturar tempo total em ns do formato chrono
        if [ "$kernel" == "Many-threads" ]; then
            # Procurar por "Kernel 1" ou "Many-threads"
            tempo_total=$(grep -A1 "Kernel 1\|Many-threads" "$arquivo" | grep "deltaT(ns):" | sed 's/.*deltaT(ns): \([0-9]*\) ns.*/\1/')
            tempo_por_op=$(grep -A2 "Kernel 1\|Many-threads" "$arquivo" | grep "each op takes" | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
        else
            # Procurar por "Kernel 2" ou "Persistente"
            tempo_total=$(grep -A1 "Kernel 2\|Persistente" "$arquivo" | grep "deltaT(ns):" | sed 's/.*deltaT(ns): \([0-9]*\) ns.*/\1/')
            tempo_por_op=$(grep -A2 "Kernel 2\|Persistente" "$arquivo" | grep "each op takes" | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
        fi
        
        echo "Tempo total extraído: '$tempo_total'"
        echo "Tempo por op extraído: '$tempo_por_op'"
        
        # Se não encontrou pelos nomes dos kernels, tentar padrões genéricos
        if [ -z "$tempo_total" ]; then
            # Buscar qualquer linha com deltaT
            tempo_total=$(grep "deltaT(ns):" "$arquivo" | tail -1 | sed 's/.*deltaT(ns): \([0-9]*\) ns.*/\1/')
            tempo_por_op=$(grep "each op takes" "$arquivo" | tail -1 | sed 's/.*each op takes \([0-9]*\) ns.*/\1/')
        fi
        
        if [ ! -z "$tempo_por_op" ] && [ "$tempo_por_op" != "" ]; then
            # Usar tempo por operação se disponível
            tempo_medio=$tempo_por_op
            
            # Calcular estatísticas usando awk
            stats=$(echo "$tempo_medio $elementos" | awk '{
                tempo_medio = $1;
                elementos = $2;
                desvio = 0;
                tempo_por_op_calc = tempo_medio / elementos;
                vazao = elementos / tempo_medio * 1000000000;
                printf "%.0f,%.0f,%.6f,%.2f", tempo_medio, desvio, tempo_por_op_calc, vazao
            }')
            
            # Verificar validação
            validacao=$(grep -c "CORRETO\|Test PASSED\|OK" "$arquivo" 2>/dev/null || echo "0")
            if [ "$validacao" -gt 0 ]; then
                validacao_status="OK"
            else
                validacao_status="VERIFICAR"
            fi
            
            echo "$teste,$kernel,$elementos,$stats,$validacao_status" >> resultados_experimentos.csv
            echo "✓ Linha adicionada: $teste,$kernel,$elementos,$stats,$validacao_status"
            
        elif [ ! -z "$tempo_total" ] && [ "$tempo_total" != "" ]; then
            # Usar tempo total se tempo por op não estiver disponível
            tempo_medio=$tempo_total
            
            # Calcular estatísticas usando awk
            stats=$(echo "$tempo_total $elementos" | awk '{
                tempo_total = $1;
                elementos = $2;
                desvio = 0;
                tempo_por_op_calc = tempo_total / elementos;
                vazao = elementos / tempo_total * 1000000000;
                printf "%.0f,%.0f,%.6f,%.2f", tempo_total, desvio, tempo_por_op_calc, vazao
            }')
            
            # Verificar validação
            validacao=$(grep -c "CORRETO\|Test PASSED\|OK" "$arquivo" 2>/dev/null || echo "0")
            if [ "$validacao" -gt 0 ]; then
                validacao_status="OK"
            else
                validacao_status="VERIFICAR"
            fi
            
            echo "$teste,$kernel,$elementos,$stats,$validacao_status" >> resultados_experimentos.csv
            echo "✓ Linha adicionada: $teste,$kernel,$elementos,$stats,$validacao_status"
        else
            echo "❌ Nenhum tempo encontrado no formato esperado"
            echo "Tentando buscar qualquer número seguido de 'ns':"
            grep -n "ns" "$arquivo" | head -5
            echo "$teste,$kernel,$elementos,0,0,0,0,SEM_DADOS" >> resultados_experimentos.csv
        fi
    else
        echo "❌ Arquivo $arquivo não encontrado!"
        echo "Listando arquivos dados_* disponíveis:"
        ls -la dados_* 2>/dev/null || echo "Nenhum arquivo dados_* encontrado"
        echo "$teste,$kernel,$elementos,0,0,0,0,ARQUIVO_NAO_ENCONTRADO" >> resultados_experimentos.csv
    fi
}

# Processar todos os arquivos de dados
processar_dados "dados_1M_many.txt" "1M" "Many-threads" "1000000"
processar_dados "dados_1M_persist.txt" "1M" "Persistente" "1000000"
processar_dados "dados_16M_many.txt" "16M" "Many-threads" "16000000" 
processar_dados "dados_16M_persist.txt" "16M" "Persistente" "16000000"

echo "Planilha CSV criada: resultados_experimentos.csv"

echo "=============================================="
echo "CRIANDO SCRIPT PARA GRÁFICOS..."
echo "=============================================="

# Criar script Python para gerar gráficos
cat > gerar_graficos.py << 'EOF'
#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys

print("Gerando gráficos de performance...")

try:
    # Carregar dados
    df = pd.read_csv('resultados_experimentos.csv')
    print(f"Dados carregados: {len(df)} registros")
    
    # Verificar se temos dados válidos
    if df['Tempo_Medio_ns'].sum() == 0:
        print("AVISO: Nenhum dado válido encontrado!")
        print("Execute primeiro os experimentos antes de gerar gráficos.")
        sys.exit(1)
    
    # Configurar matplotlib
    plt.rcParams['figure.figsize'] = [15, 10]
    plt.rcParams['font.size'] = 10
    
    # Criar figura com subplots
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle('Análise de Performance - Kernels CUDA Reduce Max', fontsize=16, fontweight='bold')
    
    # Gráfico 1: Tempo Médio
    df_tempo = df.pivot(index='Teste', columns='Kernel', values='Tempo_Medio_ns')
    df_tempo.plot(kind='bar', ax=ax1, width=0.7, color=['skyblue', 'lightcoral'])
    ax1.set_title('Tempo Médio de Execução')
    ax1.set_ylabel('Tempo (nanossegundos)')
    ax1.set_xlabel('Tamanho do Vetor')
    ax1.legend(title='Kernel')
    ax1.tick_params(axis='x', rotation=0)
    
    # Gráfico 2: Vazão
    df_vazao = df.pivot(index='Teste', columns='Kernel', values='Vazao_GOPS')
    df_vazao.plot(kind='bar', ax=ax2, width=0.7, color=['orange', 'green'])
    ax2.set_title('Vazão (Throughput)')
    ax2.set_ylabel('GOPS (Giga Operações/segundo)')
    ax2.set_xlabel('Tamanho do Vetor')
    ax2.legend(title='Kernel')
    ax2.tick_params(axis='x', rotation=0)
    
    # Gráfico 3: Comparação Lado a Lado
    teste_1m = df[df['Teste'] == '1M']
    teste_16m = df[df['Teste'] == '16M']
    
    x = np.arange(2)
    width = 0.35
    
    many_times = [
        teste_1m[teste_1m['Kernel'] == 'Many-threads']['Tempo_Medio_ns'].iloc[0] if len(teste_1m[teste_1m['Kernel'] == 'Many-threads']) > 0 else 0,
        teste_16m[teste_16m['Kernel'] == 'Many-threads']['Tempo_Medio_ns'].iloc[0] if len(teste_16m[teste_16m['Kernel'] == 'Many-threads']) > 0 else 0
    ]
    persist_times = [
        teste_1m[teste_1m['Kernel'] == 'Persistente']['Tempo_Medio_ns'].iloc[0] if len(teste_1m[teste_1m['Kernel'] == 'Persistente']) > 0 else 0,
        teste_16m[teste_16m['Kernel'] == 'Persistente']['Tempo_Medio_ns'].iloc[0] if len(teste_16m[teste_16m['Kernel'] == 'Persistente']) > 0 else 0
    ]
    
    ax3.bar(x - width/2, many_times, width, label='Many-threads', alpha=0.8, color='skyblue')
    ax3.bar(x + width/2, persist_times, width, label='Persistente', alpha=0.8, color='lightcoral')
    ax3.set_title('Comparação Direta de Performance')
    ax3.set_ylabel('Tempo (nanossegundos)')
    ax3.set_xlabel('Tamanho do Vetor')
    ax3.set_xticks(x)
    ax3.set_xticklabels(['1M elementos', '16M elementos'])
    ax3.legend()
    
    # Gráfico 4: Speedup
    speedup_1m = many_times[0] / persist_times[0] if persist_times[0] > 0 else 1
    speedup_16m = many_times[1] / persist_times[1] if persist_times[1] > 0 else 1
    
    speedups = [speedup_1m, speedup_16m]
    colors = ['skyblue' if s >= 1 else 'lightcoral' for s in speedups]
    
    bars = ax4.bar(['1M elementos', '16M elementos'], speedups, color=colors, alpha=0.8)
    ax4.axhline(y=1, color='red', linestyle='--', alpha=0.7, label='Sem aceleração')
    ax4.set_title('Speedup: Many-threads vs Persistente')
    ax4.set_ylabel('Speedup (Many-threads / Persistente)')
    ax4.set_xlabel('Tamanho do Vetor')
    ax4.legend()
    
    # Adicionar valores nas barras
    for i, (bar, v) in enumerate(zip(bars, speedups)):
        height = bar.get_height()
        ax4.text(bar.get_x() + bar.get_width()/2., height + 0.05,
                f'{v:.2f}x', ha='center', va='bottom', fontweight='bold')
    
    plt.tight_layout()
    plt.savefig('graficos_performance.png', dpi=300, bbox_inches='tight')
    plt.savefig('graficos_performance.pdf', bbox_inches='tight')
    print("✓ Gráficos salvos: graficos_performance.png e graficos_performance.pdf")
    
    # Relatório de resultados
    print("\n" + "="*60)
    print("RESUMO DOS RESULTADOS")
    print("="*60)
    print(df.to_string(index=False))
    
    print(f"\nSPEEDUPS:")
    print(f"1M elementos: {speedup_1m:.2f}x")
    print(f"16M elementos: {speedup_16m:.2f}x")
    
except Exception as e:
    print(f"Erro ao gerar gráficos: {e}")
    print("Verifique se pandas e matplotlib estão instalados:")
    print("pip3 install pandas matplotlib numpy")
EOF

chmod +x gerar_graficos.py

echo "=============================================="
echo "TENTANDO GERAR GRÁFICOS..."
echo "=============================================="

# Verificar se Python3 está disponível
if command -v python3 &> /dev/null; then
    echo "Python3 encontrado. Verificando bibliotecas..."
    
    # Tentar instalar dependências se não existirem
    python3 -c "import pandas, matplotlib, numpy" 2>/dev/null || {
        echo "Instalando dependências Python..."
        python3 -m pip install pandas matplotlib numpy --user 2>/dev/null || {
            echo "Não foi possível instalar automaticamente."
            echo "Execute manualmente: pip3 install pandas matplotlib numpy"
        }
    }
    
    # Tentar gerar gráficos
    echo "Gerando gráficos..."
    python3 gerar_graficos.py 2>/dev/null || {
        echo "Erro ao gerar gráficos automaticamente."
        echo "Execute manualmente: python3 gerar_graficos.py"
    }
else
    echo "Python3 não encontrado."
    echo "Para gerar gráficos, instale Python3 e execute:"
    echo "python3 gerar_graficos.py"
fi

echo "=============================================="
echo "COLETA DE DADOS PARA O TRABALHO CONCLUÍDA!"
echo "=============================================="
echo ""
echo "Arquivos gerados:"
echo "- dados_1M_many.txt"
echo "- dados_1M_persist.txt"  
echo "- dados_16M_many.txt"
echo "- dados_16M_persist.txt"
echo "- resumo_experimentos.txt"
echo "- resultados_experimentos.csv (planilha LibreOffice)"
echo "- gerar_graficos.py (script para gráficos)"
if [ -f "graficos_performance.png" ]; then
    echo "- graficos_performance.png (gráficos gerados)"
    echo "- graficos_performance.pdf (gráficos em PDF)"
fi
echo ""
echo "Próximos passos:"
echo "1. Abra resultados_experimentos.csv no LibreOffice Calc"
echo "2. Se não tiver gráficos, execute: python3 gerar_graficos.py"
echo "3. Use os gráficos no relatório PDF"
echo "4. Complete as análises no relatorio_experimentos.md"