#!/bin/bash

echo "=============================================="
echo "PROCESSANDO DADOS EXISTENTES"
echo "=============================================="

# Verificar se existe arquivo de dados do trabalho
if [ -f "dados_trabalho_20251006_184252.txt" ]; then
    echo "✅ Encontrado arquivo de dados existente!"
    echo "Conteúdo do arquivo (primeiras 20 linhas):"
    head -20 dados_trabalho_20251006_184252.txt
    echo ""
    echo "Últimas 10 linhas:"
    tail -10 dados_trabalho_20251006_184252.txt
    echo ""
    
    echo "Analisando conteúdo do arquivo..."
    echo "- Linhas com 'Kernel 1':"
    grep -n "Kernel 1" dados_trabalho_20251006_184252.txt || echo "Nenhuma"
    
    echo "- Linhas com 'Kernel 2':"
    grep -n "Kernel 2" dados_trabalho_20251006_184252.txt || echo "Nenhuma"
    
    echo "- Linhas com 'each op takes':"
    grep -n "each op takes" dados_trabalho_20251006_184252.txt || echo "Nenhuma"
    
    echo "- Linhas com 'deltaT':"
    grep -n "deltaT" dados_trabalho_20251006_184252.txt || echo "Nenhuma"
    
    echo "- Linhas com números e 'ns':"
    grep -n "[0-9] ns" dados_trabalho_20251006_184252.txt | head -5 || echo "Nenhuma"
    
    echo ""
    echo "Este arquivo contém os dados dos experimentos?"
    echo "Se sim, podemos processá-lo para extrair os dados."
fi

# Verificar se arquivos individuais existem
echo ""
echo "Verificando arquivos individuais:"
for arquivo in dados_1M_many.txt dados_1M_persist.txt dados_16M_many.txt dados_16M_persist.txt; do
    if [ -f "$arquivo" ]; then
        echo "✅ $arquivo existe - $(wc -l < $arquivo) linhas"
    else
        echo "❌ $arquivo não existe"
    fi
done

echo ""
echo "=============================================="
echo "PRÓXIMOS PASSOS:"
echo "=============================================="
echo "1. Se dados_trabalho_*.txt contém todos os experimentos:"
echo "   - Podemos dividir esse arquivo em 4 partes"
echo "   - Ou processar diretamente dele"
echo ""
echo "2. Se não, execute:"
echo "   ./executar_experimentos.sh"
echo ""
echo "3. Depois processe com:"
echo "   ./coleta_dados_trabalho.sh (apenas a parte do CSV)"