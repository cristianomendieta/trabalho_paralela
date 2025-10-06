#!/usr/bin/env python3
"""
Script alternativo para converter Markdown para PDF usando markdown2pdf ou weasyprint
"""
import sys
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RELATORIO_MD = ROOT / 'relatorio' / 'relatorio_completo.md'
RELATORIO_PDF = ROOT / 'relatorio' / 'relatorio_completo.pdf'

print("=== Tentando gerar PDF do relatório ===\n")

# Verificar se o arquivo Markdown existe
if not RELATORIO_MD.exists():
    print(f"❌ Erro: Arquivo não encontrado: {RELATORIO_MD}")
    sys.exit(1)

# Opção 1: Tentar markdown-pdf (npm package)
print("Tentando usar markdown-pdf (npm)...")
try:
    result = subprocess.run(
        ['npx', '-y', 'markdown-pdf', str(RELATORIO_MD), '-o', str(RELATORIO_PDF)],
        capture_output=True,
        timeout=30
    )
    if result.returncode == 0 and RELATORIO_PDF.exists():
        print(f"✅ PDF gerado com sucesso usando markdown-pdf!")
        print(f"   {RELATORIO_PDF}")
        sys.exit(0)
except:
    pass

# Opção 2: Tentar md-to-pdf (npm package)
print("Tentando usar md-to-pdf (npm)...")
try:
    result = subprocess.run(
        ['npx', '-y', 'md-to-pdf', str(RELATORIO_MD)],
        capture_output=True,
        timeout=30
    )
    pdf_output = RELATORIO_MD.with_suffix('.pdf')
    if result.returncode == 0 and pdf_output.exists():
        pdf_output.rename(RELATORIO_PDF)
        print(f"✅ PDF gerado com sucesso usando md-to-pdf!")
        print(f"   {RELATORIO_PDF}")
        sys.exit(0)
except:
    pass

# Opção 3: Tentar weasyprint (Python)
print("Tentando usar weasyprint (Python)...")
try:
    import markdown
    from weasyprint import HTML
    
    # Converter Markdown para HTML
    with open(RELATORIO_MD, 'r', encoding='utf-8') as f:
        md_content = f.read()
    
    html_content = markdown.markdown(
        md_content,
        extensions=['extra', 'codehilite', 'tables', 'toc']
    )
    
    # Adicionar CSS básico
    html_with_style = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {{
                font-family: Arial, sans-serif;
                line-height: 1.6;
                margin: 2cm;
                font-size: 11pt;
            }}
            h1 {{ color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }}
            h2 {{ color: #34495e; margin-top: 20px; }}
            table {{ border-collapse: collapse; width: 100%; margin: 20px 0; }}
            th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
            th {{ background-color: #3498db; color: white; }}
            img {{ max-width: 100%; height: auto; }}
            code {{ background-color: #f4f4f4; padding: 2px 5px; border-radius: 3px; }}
            pre {{ background-color: #f4f4f4; padding: 10px; border-radius: 5px; overflow-x: auto; }}
        </style>
    </head>
    <body>
        {html_content}
    </body>
    </html>
    """
    
    # Gerar PDF
    HTML(string=html_with_style, base_url=str(ROOT)).write_pdf(str(RELATORIO_PDF))
    
    if RELATORIO_PDF.exists():
        print(f"✅ PDF gerado com sucesso usando weasyprint!")
        print(f"   {RELATORIO_PDF}")
        sys.exit(0)
except ImportError:
    print("   weasyprint não disponível (instale com: pip install weasyprint markdown)")
except Exception as e:
    print(f"   Erro ao usar weasyprint: {e}")

# Opção 4: Tentar pypandoc (Python wrapper para pandoc)
print("Tentando usar pypandoc (Python)...")
try:
    import pypandoc
    
    pypandoc.convert_file(
        str(RELATORIO_MD),
        'pdf',
        outputfile=str(RELATORIO_PDF),
        extra_args=[
            '--pdf-engine=xelatex',
            '-V', 'geometry:margin=2.5cm',
            '--toc'
        ]
    )
    
    if RELATORIO_PDF.exists():
        print(f"✅ PDF gerado com sucesso usando pypandoc!")
        print(f"   {RELATORIO_PDF}")
        sys.exit(0)
except ImportError:
    print("   pypandoc não disponível (instale com: pip install pypandoc)")
except Exception as e:
    print(f"   Erro ao usar pypandoc: {e}")

# Se nenhuma opção funcionou
print("\n❌ Nenhum método de conversão funcionou automaticamente.\n")
print("Por favor, use uma das alternativas manuais:\n")
print("1️⃣  VS Code com extensão 'Markdown PDF':")
print("   - Instalar extensão: yzane.markdown-pdf")
print("   - Abrir: relatorio/relatorio_completo.md")
print("   - Ctrl+Shift+P → 'Markdown PDF: Export (pdf)'\n")
print("2️⃣  Conversor online:")
print("   - https://www.markdowntopdf.com/")
print("   - Upload: relatorio/relatorio_completo.md\n")
print("3️⃣  LibreOffice:")
print("   - Abrir arquivo .md no Writer")
print("   - Arquivo → Exportar como PDF\n")
print("4️⃣  Instalar pandoc:")
print("   - sudo apt-get install pandoc texlive-xetex")
print("   - ./gerar_pdf.sh\n")

sys.exit(1)
