#!/usr/bin/env python3
"""
Script para processar resultados dos experimentos de redução GPU
Extrai dados de thrust dos arquivos .txt e gera relatório completo
"""
import re
import csv
from pathlib import Path
from collections import defaultdict
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Backend sem display

ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / 'resultados'
PLOTS_DIR = RESULTS / 'plots'
PLOTS_DIR.mkdir(exist_ok=True)
REPORT_DIR = ROOT / 'relatorio'
REPORT_DIR.mkdir(exist_ok=True)

def extrair_metricas(filepath):
    """Extrai métricas de um arquivo de saída do experimento"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    metricas = {}
    
    # Extrair número de elementos
    match = re.search(r'Elementos:\s+(\d+)', content)
    if match:
        metricas['elementos'] = int(match.group(1))
    
    # Extrair métricas do Kernel 1 (Many-threads)
    match = re.search(r'Kernel 1 \(Many-threads\).*?each op takes (\d+) ns', content, re.DOTALL)
    if match:
        metricas['kernel1_tempo_ns'] = int(match.group(1))
        match_throughput = re.search(r'reduceMax Kernel1 Throughput:\s+([\d.]+)\s+GFLOPS', content)
        if match_throughput:
            metricas['kernel1_gflops'] = float(match_throughput.group(1))
    
    # Extrair métricas do Kernel 2 (Persistente)
    match = re.search(r'Kernel 2 \(Persistente\).*?each op takes (\d+) ns', content, re.DOTALL)
    if match:
        metricas['kernel2_tempo_ns'] = int(match.group(1))
        match_throughput = re.search(r'reduceMax Kernel2 Throughput:\s+([\d.]+)\s+GFLOPS', content)
        if match_throughput:
            metricas['kernel2_gflops'] = float(match_throughput.group(1))
    
    # Extrair métricas do Thrust
    match = re.search(r'Thrust deltaT.*?each op takes (\d+) ns', content, re.DOTALL)
    if match:
        metricas['thrust_tempo_ns'] = int(match.group(1))
        match_throughput = re.search(r'reduceMax Thrust Throughput:\s+([\d.]+)\s+GFLOPS', content)
        if match_throughput:
            metricas['thrust_gflops'] = float(match_throughput.group(1))
    
    # Extrair métricas do copyKernel
    match = re.search(r'copyKernel deltaT.*?each op takes (\d+) ns', content, re.DOTALL)
    if match:
        metricas['copy_tempo_ns'] = int(match.group(1))
        match_throughput = re.search(r'Throughput:\s+([\d.]+)\s+GFLOPS', content)
        if match_throughput:
            metricas['copy_gflops'] = float(match_throughput.group(1))
    
    # Extrair validação
    metricas['validacao'] = 'OK' if ('Test PASSED' in content or 'CORRETO' in content) else 'FAIL'
    
    return metricas

# Processar todos os arquivos
dados = []

# 1M copyKernel
if (RESULTS / 'dados_1M_copy.txt').exists():
    print("Processando dados_1M_copy.txt...")
    m = extrair_metricas(RESULTS / 'dados_1M_copy.txt')
    if 'copy_tempo_ns' in m:
        dados.append({
            'Teste': '1M',
            'Kernel': 'copyKernel',
            'Elementos': m['elementos'],
            'Tempo_Medio_ns': m['copy_tempo_ns'],
            'Vazao_GFLOPS': m['copy_gflops'],
            'Validacao': m['validacao']
        })

# 1M Many-threads
print("Processando dados_1M_many.txt...")
m = extrair_metricas(RESULTS / 'dados_1M_many.txt')
if 'kernel1_tempo_ns' in m:
    dados.append({
        'Teste': '1M',
        'Kernel': 'Many-threads',
        'Elementos': m['elementos'],
        'Tempo_Medio_ns': m['kernel1_tempo_ns'],
        'Vazao_GFLOPS': m['kernel1_gflops'],
        'Validacao': m['validacao']
    })
if 'thrust_tempo_ns' in m:
    dados.append({
        'Teste': '1M',
        'Kernel': 'Thrust',
        'Elementos': m['elementos'],
        'Tempo_Medio_ns': m['thrust_tempo_ns'],
        'Vazao_GFLOPS': m['thrust_gflops'],
        'Validacao': m['validacao']
    })

# 1M Persistente
print("Processando dados_1M_persist.txt...")
m = extrair_metricas(RESULTS / 'dados_1M_persist.txt')
if 'kernel2_tempo_ns' in m:
    dados.append({
        'Teste': '1M',
        'Kernel': 'Persistente',
        'Elementos': m['elementos'],
        'Tempo_Medio_ns': m['kernel2_tempo_ns'],
        'Vazao_GFLOPS': m['kernel2_gflops'],
        'Validacao': m['validacao']
    })

# 16M Many-threads
print("Processando dados_16M_many.txt...")
m = extrair_metricas(RESULTS / 'dados_16M_many.txt')
if 'kernel1_tempo_ns' in m:
    dados.append({
        'Teste': '16M',
        'Kernel': 'Many-threads',
        'Elementos': m['elementos'],
        'Tempo_Medio_ns': m['kernel1_tempo_ns'],
        'Vazao_GFLOPS': m['kernel1_gflops'],
        'Validacao': m['validacao']
    })
if 'thrust_tempo_ns' in m:
    dados.append({
        'Teste': '16M',
        'Kernel': 'Thrust',
        'Elementos': m['elementos'],
        'Tempo_Medio_ns': m['thrust_tempo_ns'],
        'Vazao_GFLOPS': m['thrust_gflops'],
        'Validacao': m['validacao']
    })

# 16M copyKernel
if (RESULTS / 'dados_16M_copy.txt').exists():
    print("Processando dados_16M_copy.txt...")
    m = extrair_metricas(RESULTS / 'dados_16M_copy.txt')
    if 'copy_tempo_ns' in m:
        dados.append({
            'Teste': '16M',
            'Kernel': 'copyKernel',
            'Elementos': m['elementos'],
            'Tempo_Medio_ns': m['copy_tempo_ns'],
            'Vazao_GFLOPS': m['copy_gflops'],
            'Validacao': m['validacao']
        })

# 16M Persistente
print("Processando dados_16M_persist.txt...")
m = extrair_metricas(RESULTS / 'dados_16M_persist.txt')
if 'kernel2_tempo_ns' in m:
    dados.append({
        'Teste': '16M',
        'Kernel': 'Persistente',
        'Elementos': m['elementos'],
        'Tempo_Medio_ns': m['kernel2_tempo_ns'],
        'Vazao_GFLOPS': m['kernel2_gflops'],
        'Validacao': m['validacao']
    })

# Calcular acelerações em relação ao Thrust
thrust_por_teste = {}
for d in dados:
    if d['Kernel'] == 'Thrust':
        thrust_por_teste[d['Teste']] = d['Vazao_GFLOPS']

for d in dados:
    teste = d['Teste']
    if teste in thrust_por_teste and thrust_por_teste[teste] > 0:
        d['Aceleracao_vs_Thrust'] = d['Vazao_GFLOPS'] / thrust_por_teste[teste]
    else:
        d['Aceleracao_vs_Thrust'] = 1.0

# Escrever CSV final
CSV_OUT = RESULTS / 'resultados_completos.csv'
print(f"\nGerando {CSV_OUT}...")
with open(CSV_OUT, 'w', newline='') as f:
    fieldnames = ['Teste', 'Kernel', 'Elementos', 'Tempo_Medio_ns', 
                  'Vazao_GFLOPS', 'Aceleracao_vs_Thrust', 'Validacao']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    for d in dados:
        writer.writerow(d)

print("CSV gerado com sucesso!")
print("\nDados extraídos:")
for d in dados:
    print(f"  {d['Teste']:4s} {d['Kernel']:15s}: {d['Vazao_GFLOPS']:8.3f} GFLOPS, "
          f"Aceleração: {d['Aceleracao_vs_Thrust']:5.2f}x")

# Gerar gráficos
print("\nGerando gráficos...")

# Organizar dados por kernel
kernels_data = defaultdict(lambda: {'x': [], 'vazao': [], 'aceleracao': []})
for d in dados:
    kernel = d['Kernel']
    elementos_milhoes = d['Elementos'] / 1e6
    kernels_data[kernel]['x'].append(elementos_milhoes)
    kernels_data[kernel]['vazao'].append(d['Vazao_GFLOPS'])
    kernels_data[kernel]['aceleracao'].append(d['Aceleracao_vs_Thrust'])

# Gráfico 1: Vazão vs Tamanho
fig, ax1 = plt.subplots(figsize=(10, 6))

cores = {'copyKernel': '#9467bd', 'Many-threads': '#1f77b4', 'Persistente': '#ff7f0e', 'Thrust': '#2ca02c'}
marcadores = {'copyKernel': 'd', 'Many-threads': 'o', 'Persistente': 's', 'Thrust': '^'}

for kernel in ['copyKernel', 'Many-threads', 'Persistente', 'Thrust']:
    if kernel in kernels_data:
        data = kernels_data[kernel]
        ax1.plot(data['x'], data['vazao'], 
                marker=marcadores[kernel], 
                color=cores[kernel],
                linewidth=2, 
                markersize=8,
                label=kernel)

ax1.set_xlabel('Número de Elementos (Milhões)', fontsize=12, fontweight='bold')
ax1.set_ylabel('Vazão (GFLOPS)', fontsize=12, fontweight='bold')
ax1.set_title('Vazão dos Kernels de Redução vs Tamanho da Entrada', 
              fontsize=14, fontweight='bold', pad=20)
ax1.grid(True, alpha=0.3, linestyle='--')
ax1.legend(fontsize=10, loc='best')
ax1.set_xticks([1, 16])

plt.tight_layout()
plt.savefig(PLOTS_DIR / 'vazao_vs_elementos.png', dpi=300, bbox_inches='tight')
print(f"  Salvo: {PLOTS_DIR / 'vazao_vs_elementos.png'}")
plt.close()

# Gráfico 2: Aceleração vs Tamanho
fig, ax2 = plt.subplots(figsize=(10, 6))

for kernel in ['Many-threads', 'Persistente']:
    if kernel in kernels_data:
        data = kernels_data[kernel]
        ax2.plot(data['x'], data['aceleracao'], 
                marker=marcadores[kernel], 
                color=cores[kernel],
                linewidth=2, 
                markersize=8,
                label=kernel)

# Linha de referência (Thrust = 1.0x)
ax2.axhline(y=1.0, color='#2ca02c', linestyle='--', linewidth=2, 
            label='Thrust (baseline)', alpha=0.7)

ax2.set_xlabel('Número de Elementos (Milhões)', fontsize=12, fontweight='bold')
ax2.set_ylabel('Aceleração vs Thrust (×)', fontsize=12, fontweight='bold')
ax2.set_title('Aceleração dos Kernels em Relação ao Thrust', 
              fontsize=14, fontweight='bold', pad=20)
ax2.grid(True, alpha=0.3, linestyle='--')
ax2.legend(fontsize=10, loc='best')
ax2.set_xticks([1, 16])

plt.tight_layout()
plt.savefig(PLOTS_DIR / 'aceleracao_vs_elementos.png', dpi=300, bbox_inches='tight')
print(f"  Salvo: {PLOTS_DIR / 'aceleracao_vs_elementos.png'}")
plt.close()

# Gráfico 3: Comparação lado a lado
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))

# Subplot 1: Vazão
for kernel in ['copyKernel', 'Many-threads', 'Persistente', 'Thrust']:
    if kernel in kernels_data:
        data = kernels_data[kernel]
        ax1.plot(data['x'], data['vazao'], 
                marker=marcadores[kernel], 
                color=cores[kernel],
                linewidth=2, 
                markersize=8,
                label=kernel)

ax1.set_xlabel('Número de Elementos (Milhões)', fontsize=11, fontweight='bold')
ax1.set_ylabel('Vazão (GFLOPS)', fontsize=11, fontweight='bold')
ax1.set_title('Vazão dos Kernels', fontsize=12, fontweight='bold')
ax1.grid(True, alpha=0.3, linestyle='--')
ax1.legend(fontsize=9)
ax1.set_xticks([1, 16])

# Subplot 2: Aceleração
for kernel in ['Many-threads', 'Persistente']:
    if kernel in kernels_data:
        data = kernels_data[kernel]
        ax2.plot(data['x'], data['aceleracao'], 
                marker=marcadores[kernel], 
                color=cores[kernel],
                linewidth=2, 
                markersize=8,
                label=kernel)

ax2.axhline(y=1.0, color='#2ca02c', linestyle='--', linewidth=2, 
            label='Thrust (baseline)', alpha=0.7)
ax2.set_xlabel('Número de Elementos (Milhões)', fontsize=11, fontweight='bold')
ax2.set_ylabel('Aceleração vs Thrust (×)', fontsize=11, fontweight='bold')
ax2.set_title('Aceleração Relativa ao Thrust', fontsize=12, fontweight='bold')
ax2.grid(True, alpha=0.3, linestyle='--')
ax2.legend(fontsize=9)
ax2.set_xticks([1, 16])

plt.tight_layout()
plt.savefig(PLOTS_DIR / 'comparacao_completa.png', dpi=300, bbox_inches='tight')
print(f"  Salvo: {PLOTS_DIR / 'comparacao_completa.png'}")
plt.close()

print("\n✓ Processamento completo!")
print(f"  CSV: {CSV_OUT}")
print(f"  Gráficos em: {PLOTS_DIR}")
