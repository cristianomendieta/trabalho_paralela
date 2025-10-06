#!/usr/bin/env python3
"""
Script para criar planilha ODS (LibreOffice) com os resultados
Requer: pip install odfpy
"""
import sys
import csv
from pathlib import Path

try:
    from odf.opendocument import OpenDocumentSpreadsheet
    from odf.style import Style, TextProperties, ParagraphProperties, TableColumnProperties
    from odf.text import P
    from odf.table import Table, TableColumn, TableRow, TableCell
except ImportError:
    print("Erro: biblioteca 'odfpy' não encontrada")
    print("Instale com: pip install odfpy")
    print()
    print("Alternativa: Use LibreOffice para abrir o CSV:")
    print("  1. Abra o LibreOffice Calc")
    print("  2. Arquivo -> Abrir -> resultados/resultados_completos.csv")
    print("  3. Selecione separador: vírgula")
    print("  4. Salve como .ods")
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / 'resultados'
CSV_FILE = RESULTS / 'resultados_completos.csv'
ODS_FILE = RESULTS / 'resultados_experimentos.ods'

# Ler dados do CSV
dados = []
with open(CSV_FILE, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        dados.append(row)

# Criar documento ODS
doc = OpenDocumentSpreadsheet()

# Estilos
bold_style = Style(name="BoldText", family="paragraph")
bold_style.addElement(TextProperties(fontweight="bold"))
doc.styles.addElement(bold_style)

# Folha 1: Dados Brutos
table1 = Table(name="Dados Brutos")

# Cabeçalho
header_row = TableRow()
headers = ['Teste', 'Kernel', 'Elementos', 'Tempo Médio (ns)', 
           'Vazão (GFLOPS)', 'Aceleração vs Thrust', 'Validação']
for header in headers:
    cell = TableCell()
    p = P(stylename=bold_style, text=header)
    cell.addElement(p)
    header_row.addElement(cell)
table1.addElement(header_row)

# Dados
for row in dados:
    table_row = TableRow()
    
    # Teste
    cell = TableCell()
    cell.addElement(P(text=row['Teste']))
    table_row.addElement(cell)
    
    # Kernel
    cell = TableCell()
    cell.addElement(P(text=row['Kernel']))
    table_row.addElement(cell)
    
    # Elementos
    cell = TableCell(valuetype="float", value=row['Elementos'])
    cell.addElement(P(text=row['Elementos']))
    table_row.addElement(cell)
    
    # Tempo Médio
    cell = TableCell(valuetype="float", value=row['Tempo_Medio_ns'])
    cell.addElement(P(text=row['Tempo_Medio_ns']))
    table_row.addElement(cell)
    
    # Vazão
    cell = TableCell(valuetype="float", value=row['Vazao_GFLOPS'])
    cell.addElement(P(text=f"{float(row['Vazao_GFLOPS']):.3f}"))
    table_row.addElement(cell)
    
    # Aceleração
    cell = TableCell(valuetype="float", value=row['Aceleracao_vs_Thrust'])
    cell.addElement(P(text=f"{float(row['Aceleracao_vs_Thrust']):.2f}"))
    table_row.addElement(cell)
    
    # Validação
    cell = TableCell()
    cell.addElement(P(text=row['Validacao']))
    table_row.addElement(cell)
    
    table1.addElement(table_row)

doc.spreadsheet.addElement(table1)

# Folha 2: Resumo
table2 = Table(name="Resumo")

# Título
title_row = TableRow()
cell = TableCell()
cell.addElement(P(stylename=bold_style, text="RESUMO DOS EXPERIMENTOS"))
title_row.addElement(cell)
table2.addElement(title_row)

# Linha vazia
table2.addElement(TableRow())

# Organizar dados por teste
from collections import defaultdict
por_teste = defaultdict(list)
for row in dados:
    por_teste[row['Teste']].append(row)

# Para cada teste
for teste in ['1M', '16M']:
    # Cabeçalho do teste
    test_row = TableRow()
    cell = TableCell()
    cell.addElement(P(stylename=bold_style, text=f"Teste: {teste} elementos"))
    test_row.addElement(cell)
    table2.addElement(test_row)
    
    # Cabeçalho da tabela
    header_row = TableRow()
    for h in ['Kernel', 'Vazão (GFLOPS)', 'Aceleração vs Thrust']:
        cell = TableCell()
        cell.addElement(P(stylename=bold_style, text=h))
        header_row.addElement(cell)
    table2.addElement(header_row)
    
    # Dados do teste
    for row in por_teste[teste]:
        data_row = TableRow()
        
        # Kernel
        cell = TableCell()
        cell.addElement(P(text=row['Kernel']))
        data_row.addElement(cell)
        
        # Vazão
        cell = TableCell(valuetype="float", value=row['Vazao_GFLOPS'])
        cell.addElement(P(text=f"{float(row['Vazao_GFLOPS']):.3f}"))
        data_row.addElement(cell)
        
        # Aceleração
        cell = TableCell(valuetype="float", value=row['Aceleracao_vs_Thrust'])
        cell.addElement(P(text=f"{float(row['Aceleracao_vs_Thrust']):.2f}×"))
        data_row.addElement(cell)
        
        table2.addElement(data_row)
    
    # Linha vazia entre testes
    table2.addElement(TableRow())

# Observações
obs_row = TableRow()
cell = TableCell()
cell.addElement(P(stylename=bold_style, text="Observações:"))
obs_row.addElement(cell)
table2.addElement(obs_row)

observacoes = [
    "• GPU: NVIDIA GeForce GTX 750 Ti",
    "• Repetições: 30 vezes por kernel",
    "• Threads por bloco: 1024",
    "• Blocos (persistente): 32",
    "• Thrust baseline (1.00×) é a referência",
]

for obs in observacoes:
    row = TableRow()
    cell = TableCell()
    cell.addElement(P(text=obs))
    row.addElement(cell)
    table2.addElement(row)

doc.spreadsheet.addElement(table2)

# Salvar documento
doc.save(ODS_FILE)

print(f"✓ Planilha ODS criada: {ODS_FILE}")
print()
print("A planilha contém duas folhas:")
print("  1. 'Dados Brutos' - Todos os dados experimentais")
print("  2. 'Resumo' - Tabela resumida com observações")
print()
print("Para inserir os gráficos no LibreOffice:")
print("  1. Abra o arquivo .ods no LibreOffice Calc")
print("  2. Vá para a folha 'Resumo'")
print("  3. Inserir -> Imagem -> Do arquivo...")
print("  4. Selecione os gráficos em resultados/plots/")
print()
print("Gráficos disponíveis:")
print(f"  - {RESULTS}/plots/vazao_vs_elementos.png")
print(f"  - {RESULTS}/plots/aceleracao_vs_elementos.png")
print(f"  - {RESULTS}/plots/comparacao_completa.png")
