#!/usr/bin/env python3
"""
Gera o gráfico EXATO conforme especificação do enunciado:
- Eixo X: quantidade de elementos (em milhões)
- Eixo Y esquerdo: vazão em GFLOPS
- Eixo Y direito: aceleração vs Thrust
- Mostra copyKernel, Many-threads, Persistente e Thrust
"""
import csv
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')

ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / 'resultados'
CSV_FILE = RESULTS / 'resultados_completos.csv'
PLOTS_DIR = RESULTS / 'plots'
PLOTS_DIR.mkdir(exist_ok=True)

# Ler dados do CSV
dados = {}
with open(CSV_FILE, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        teste = row['Teste']
        kernel = row['Kernel']
        elementos = int(row['Elementos']) / 1e6  # Converter para milhões
        vazao = float(row['Vazao_GFLOPS'])
        aceleracao = float(row['Aceleracao_vs_Thrust'])
        
        if kernel not in dados:
            dados[kernel] = {'elementos': [], 'vazao': [], 'aceleracao': []}
        
        dados[kernel]['elementos'].append(elementos)
        dados[kernel]['vazao'].append(vazao)
        dados[kernel]['aceleracao'].append(aceleracao)

# Criar figura com dois eixos Y
fig, ax1 = plt.subplots(figsize=(12, 7))

# Definir cores e marcadores
cores = {
    'copyKernel': '#9467bd',
    'Many-threads': '#1f77b4',
    'Persistente': '#ff7f0e',
    'Thrust': '#2ca02c'
}

marcadores = {
    'copyKernel': 'd',
    'Many-threads': 'o',
    'Persistente': 's',
    'Thrust': '^'
}

# Eixo Y esquerdo: Vazão (GFLOPS)
ax1.set_xlabel('Quantidade de Elementos (Milhões)', fontsize=13, fontweight='bold')
ax1.set_ylabel('Vazão (GFLOPS)', fontsize=13, fontweight='bold', color='black')
ax1.tick_params(axis='y', labelcolor='black')

# Plotar vazão para todos os kernels
for kernel in ['copyKernel', 'Many-threads', 'Persistente', 'Thrust']:
    if kernel in dados:
        d = dados[kernel]
        ax1.plot(d['elementos'], d['vazao'],
                marker=marcadores[kernel],
                color=cores[kernel],
                linewidth=2.5,
                markersize=10,
                label=f'{kernel}',
                linestyle='-' if kernel != 'Thrust' else '--',
                alpha=0.9)

ax1.grid(True, alpha=0.3, linestyle='--', linewidth=0.8)
ax1.set_xticks([1, 16])
ax1.set_xlim(0, 17)
ax1.legend(loc='upper left', fontsize=11, framealpha=0.9)

# Eixo Y direito: Aceleração vs Thrust
ax2 = ax1.twinx()
ax2.set_ylabel('Aceleração vs Thrust (×)', fontsize=13, fontweight='bold', color='darkred')
ax2.tick_params(axis='y', labelcolor='darkred')

# Plotar aceleração apenas para kernels customizados (exceto Thrust)
kernels_aceleracao = ['copyKernel', 'Many-threads', 'Persistente']
for kernel in kernels_aceleracao:
    if kernel in dados:
        d = dados[kernel]
        ax2.plot(d['elementos'], d['aceleracao'],
                marker=marcadores[kernel],
                color=cores[kernel],
                linewidth=2,
                markersize=8,
                linestyle=':',
                alpha=0.7)

# Linha de referência em 1.0× (Thrust baseline)
ax2.axhline(y=1.0, color='darkred', linestyle='-.', linewidth=2, alpha=0.5, label='Thrust baseline (1.0×)')
ax2.legend(loc='upper right', fontsize=10, framealpha=0.9)

# Título
plt.title('Desempenho dos Kernels de Redução CUDA - GTX 750 Ti',
          fontsize=14, fontweight='bold', pad=20)

# Ajustar layout
fig.tight_layout()

# Salvar
output_file = PLOTS_DIR / 'resultado_final_enunciado.png'
plt.savefig(output_file, dpi=300, bbox_inches='tight')
print(f"✓ Gráfico gerado: {output_file}")
print(f"  - Eixo X: Elementos (milhões)")
print(f"  - Eixo Y esquerdo: Vazão (GFLOPS)")
print(f"  - Eixo Y direito: Aceleração vs Thrust")
print(f"  - Kernels: copyKernel, Many-threads, Persistente, Thrust")

plt.close()
