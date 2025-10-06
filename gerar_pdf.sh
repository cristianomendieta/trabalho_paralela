#!/bin/bash
# Script para gerar PDF do relatório

RELATORIO_MD="relatorio/relatorio_completo.md"
RELATORIO_PDF="relatorio/relatorio_completo.pdf"

echo "=== Geração de PDF do Relatório ==="
echo

# Verificar se pandoc está instalado
if command -v pandoc &> /dev/null; then
    echo "✓ pandoc encontrado"
    
    # Verificar se pdflatex ou xelatex estão disponíveis
    if command -v pdflatex &> /dev/null || command -v xelatex &> /dev/null; then
        echo "✓ LaTeX engine encontrado"
        echo
        echo "Gerando PDF..."
        
        pandoc "$RELATORIO_MD" \
            -o "$RELATORIO_PDF" \
            --pdf-engine=xelatex \
            -V geometry:margin=2.5cm \
            -V fontsize=11pt \
            -V documentclass=article \
            -V colorlinks=true \
            -V linkcolor=blue \
            --toc \
            --toc-depth=2 \
            --number-sections \
            2>/dev/null || \
        pandoc "$RELATORIO_MD" \
            -o "$RELATORIO_PDF" \
            --pdf-engine=pdflatex \
            -V geometry:margin=2.5cm \
            -V fontsize=11pt \
            -V documentclass=article \
            -V colorlinks=true \
            -V linkcolor=blue \
            --toc \
            --toc-depth=2 \
            --number-sections
        
        if [ $? -eq 0 ]; then
            echo "✓ PDF gerado com sucesso: $RELATORIO_PDF"
        else
            echo "✗ Erro ao gerar PDF"
            exit 1
        fi
    else
        echo "✗ LaTeX engine não encontrado (pdflatex ou xelatex necessário)"
        echo
        echo "Alternativa 1: Instalar LaTeX"
        echo "  Ubuntu/Debian: sudo apt-get install texlive-xetex texlive-fonts-recommended"
        echo "  Fedora: sudo dnf install texlive-xetex texlive-collection-fontsrecommended"
        echo
        echo "Alternativa 2: Usar conversor online"
        echo "  - https://pandoc.org/try/"
        echo "  - https://www.markdowntopdf.com/"
        exit 1
    fi
else
    echo "✗ pandoc não encontrado"
    echo
    echo "Para instalar pandoc:"
    echo "  Ubuntu/Debian: sudo apt-get install pandoc"
    echo "  Fedora: sudo dnf install pandoc"
    echo "  Arch: sudo pacman -S pandoc"
    echo
    echo "Alternativas para gerar PDF:"
    echo
    echo "1. Usar VS Code com extensão Markdown PDF:"
    echo "   - Instalar extensão: 'Markdown PDF' (yzane.markdown-pdf)"
    echo "   - Abrir $RELATORIO_MD"
    echo "   - Ctrl+Shift+P -> 'Markdown PDF: Export (pdf)'"
    echo
    echo "2. Usar conversor online:"
    echo "   - https://www.markdowntopdf.com/"
    echo "   - https://pandoc.org/try/"
    echo
    echo "3. Usar LibreOffice:"
    echo "   - Abrir $RELATORIO_MD no LibreOffice Writer"
    echo "   - Arquivo -> Exportar como PDF"
    exit 1
fi

echo
echo "Pronto! Relatório disponível em:"
echo "  Markdown: $RELATORIO_MD"
echo "  PDF: $RELATORIO_PDF"
