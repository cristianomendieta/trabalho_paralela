#!/usr/bin/env python3
import csv
import os
from pathlib import Path
import math

import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / 'resultados'
CSV_IN = RESULTS / 'resultados_experimentos.csv'
CSV_OUT = RESULTS / 'summary_results.csv'
PLOTS_DIR = RESULTS / 'plots'
PLOTS_DIR.mkdir(exist_ok=True)

# Read CSV
rows = []
with open(CSV_IN, newline='') as f:
    reader = csv.DictReader(f)
    for r in reader:
        # convert numeric fields
        r['Elementos'] = int(r['Elementos'])
        r['Tempo_Medio_ns'] = float(r['Tempo_Medio_ns'])
        r['Vazao_GOPS'] = float(r['Vazao_GOPS'])
        rows.append(r)

# Pivot by Test and Kernel
from collections import defaultdict
data = defaultdict(dict)  # data[test][kernel] = row
for r in rows:
    test = r['Teste']
    kernel = r['Kernel']
    data[test][kernel] = r

# If thrust missing, use Many-threads as fallback and warn
have_thrust = any('thrust' in k.lower() for r in rows for k in [r['Kernel']])
if not have_thrust:
    print('Aviso: não há entrada do kernel thrust. Usarei Many-threads como referência para aceleração.')

# Build summary rows
summary = []
for test, kernels in data.items():
    n = next(iter(kernels.values()))['Elementos']
    # Determine thrust baseline
    thrust_row = kernels.get('Thrust') or kernels.get('thrust') or kernels.get('thrust-reduction') or kernels.get('Many-threads')
    for kname, row in kernels.items():
        vazao_gops = row['Vazao_GOPS']
        # Convert to GFLOPS: Vazao_GOPS currently contains elements/sec (ops/s),
        # so divide by 1e9 to get Giga ops/sec (GFLOPS)
        vazao_gflops = vazao_gops / 1e9
        if thrust_row:
            accel = vazao_gops / thrust_row['Vazao_GOPS']
        else:
            accel = 1.0
        summary.append({
            'Teste': test,
            'Kernel': kname,
            'Elementos': n,
            'Tempo_Medio_ns': row['Tempo_Medio_ns'],
            'Vazao_GOPS': vazao_gops,
            'Vazao_GFLOPS': vazao_gflops,
            'Aceleracao_vs_Thrust': accel,
            'Validacao': row.get('Validacao',''),
        })

# Write summary CSV
with open(CSV_OUT, 'w', newline='') as f:
    fieldnames = ['Teste','Kernel','Elementos','Tempo_Medio_ns','Vazao_GOPS','Vazao_GFLOPS','Aceleracao_vs_Thrust','Validacao']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    for r in summary:
        writer.writerow(r)

# Plotting
import numpy as np

def plot_vazao(data, out_path):
    # data: list of summary rows
    # group by kernel
    by_kernel = defaultdict(list)
    for r in data:
        by_kernel[r['Kernel']].append(r)
    plt.figure(figsize=(6,4))
    for k, items in by_kernel.items():
        items_sorted = sorted(items, key=lambda x: x['Elementos'])
        x = [it['Elementos']/1e6 for it in items_sorted]
        y = [it['Vazao_GFLOPS'] for it in items_sorted]
        plt.plot(x,y,'-o',label=k)
    plt.xlabel('Elementos (Milhões)')
    plt.ylabel('Vazão (GFLOPS)')
    plt.title('Vazão vs tamanho de entrada')
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.savefig(out_path)
    plt.close()


def plot_acel(data, out_path):
    by_kernel = defaultdict(list)
    tests = sorted({r['Elementos'] for r in data})
    # baseline is thrust or Many-threads
    # create x as millions
    plt.figure(figsize=(6,4))
    kernels = sorted({r['Kernel'] for r in data})
    for k in kernels:
        items = [r for r in data if r['Kernel']==k]
        items_sorted = sorted(items, key=lambda x: x['Elementos'])
        x = [it['Elementos']/1e6 for it in items_sorted]
        y = [it['Aceleracao_vs_Thrust'] for it in items_sorted]
        plt.plot(x,y,'-o',label=k)
    plt.xlabel('Elementos (Milhões)')
    plt.ylabel('Aceleração vs Thrust (x)')
    plt.title('Aceleração relative ao Thrust')
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.savefig(out_path)
    plt.close()

plot_vazao(summary, PLOTS_DIR / 'vazao_vs_n.png')
plot_acel(summary, PLOTS_DIR / 'aceleracao_vs_n.png')

# Create a simple report markdown
REPORT_DIR = ROOT / 'relatorio'
REPORT_DIR.mkdir(exist_ok=True)
REPORT_MD = REPORT_DIR / 'relatorio.md'
with open(REPORT_MD, 'w') as f:
    f.write('# Relatório - Redução GPU (trab1)\n\n')
    f.write('Autores: (colocar nomes)\n\n')
    f.write('## Objetivo\n')
    f.write('Implementar e comparar kernels de redução (many-threads e persistente) e comparar com thrust.\n\n')
    f.write('## Dados experimentais\n')
    f.write('Resumo dos resultados em `resultados/summary_results.csv`.\n\n')
    f.write("![](../resultados/plots/vazao_vs_n.png)\n\n")
    f.write("![](../resultados/plots/aceleracao_vs_n.png)\n\n")
    f.write('## Interpretação\n')
    f.write('Colocar interpretação dos resultados aqui.\n')

print('Gerado:', CSV_OUT, 'e plots em', PLOTS_DIR)
