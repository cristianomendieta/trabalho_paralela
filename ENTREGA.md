# Trabalho 1 - CI1009 Programação Paralela com GPUs

**Aluno(s):** [COLOCAR SEU NOME AQUI]  
**Data de Entrega:** 06/Outubro/2025

---

## 📦 Arquivos Entregues

Este pacote contém todos os arquivos solicitados no enunciado do trabalho:

### 1. Código Fonte
- `cudaReduceMax.cu` - Implementação dos kernels (Many-threads e Persistente)
- `helper_cuda.h` - Funções auxiliares CUDA
- `helper_string.h` - Funções auxiliares de string
- `chrono.c` - Biblioteca para medição de tempo

### 2. Scripts de Compilação e Execução
- `compila.sh` - Script para compilar o programa
- `compile.sh` / `Makefile` - Alternativas de compilação
- `executar_experimentos.sh` - Script para rodar todos os experimentos
- `roda-varios.sh` / `roda-reduce-varios.sh` - Scripts auxiliares

### 3. Dados Experimentais
Diretório `resultados/`:
- `dados_1M_many.txt` - Saída bruta do experimento com 1M elementos (many-threads)
- `dados_1M_persist.txt` - Saída bruta do experimento com 1M elementos (persistente)
- `dados_16M_many.txt` - Saída bruta do experimento com 16M elementos (many-threads)
- `dados_16M_persist.txt` - Saída bruta do experimento com 16M elementos (persistente)
- `resultados_completos.csv` - **Tabela consolidada com todos os dados**
- `resultados_experimentos.ods` - **Planilha LibreOffice com 2 folhas**

### 4. Gráficos
Diretório `resultados/plots/`:
- `vazao_vs_elementos.png` - Gráfico de vazão (GFLOPS) vs tamanho da entrada
- `aceleracao_vs_elementos.png` - Gráfico de aceleração vs tamanho da entrada
- `comparacao_completa.png` - Gráfico comparativo lado a lado

### 5. Relatório
Diretório `relatorio/`:
- `relatorio_completo.md` - **Relatório completo em Markdown**
- `relatorio_completo.pdf` - **Relatório em PDF** (gerar conforme instruções abaixo)

### 6. Scripts de Processamento
Diretório `scripts/`:
- `processar_resultados_completo.py` - Script para processar dados e gerar gráficos
- `gerar_planilha_ods.py` - Script para gerar planilha ODS

---

## 🚀 Como Reproduzir os Experimentos

### Pré-requisitos
- CUDA Toolkit instalado
- GPU NVIDIA (experimentos realizados na GTX 750 Ti)
- GCC/G++ compatível com CUDA

### Passo 1: Compilar o Programa

```bash
./compila.sh
```

Ou usando Makefile:
```bash
make
```

### Passo 2: Executar os Experimentos

**Experimento 1M elementos (Many-threads):**
```bash
./cudaReduceMax 1000000 > resultados/dados_1M_many.txt
```

**Experimento 1M elementos (Persistente com 32 blocos):**
```bash
./cudaReduceMax 1000000 32 > resultados/dados_1M_persist.txt
```

**Experimento 16M elementos (Many-threads):**
```bash
./cudaReduceMax 16000000 > resultados/dados_16M_many.txt
```

**Experimento 16M elementos (Persistente com 32 blocos):**
```bash
./cudaReduceMax 16000000 32 > resultados/dados_16M_persist.txt
```

### Passo 3: Processar Resultados e Gerar Gráficos

```bash
python3 scripts/processar_resultados_completo.py
```

Este script irá:
- Ler os arquivos `.txt` em `resultados/`
- Extrair métricas de todos os kernels (Many-threads, Persistente, Thrust)
- Gerar `resultados/resultados_completos.csv`
- Gerar gráficos PNG em `resultados/plots/`

### Passo 4: Gerar Planilha ODS

```bash
# Instalar dependência (se necessário)
pip install odfpy

# Gerar planilha
python3 scripts/gerar_planilha_ods.py
```

Resultado: `resultados/resultados_experimentos.ods` (compatível com LibreOffice)

---

## 📊 Resultados Principais

### Resumo dos Experimentos

| Teste | Kernel | Vazão (GFLOPS) | Aceleração vs Thrust |
|-------|--------|----------------|---------------------|
| 1M | Many-threads | 1,678 | 0,31× |
| 1M | **Thrust** | **5,378** | **1,00× (baseline)** |
| 1M | **Persistente** | **8,701** | **1,62× ⚡** |
| 16M | Many-threads | 1,828 | 0,12× |
| 16M | **Thrust** | **15,846** | **1,00× (baseline)** |
| 16M | **Persistente** | **15,291** | **0,96× ⚡** |

### Principais Conclusões

1. ✅ **Kernel Persistente supera Thrust para entradas pequenas (1M)**: 
   - 1,62× mais rápido que Thrust
   - 5,18× mais rápido que Many-threads

2. ✅ **Kernel Persistente empata com Thrust para entradas grandes (16M)**:
   - 0,96× (praticamente igual ao Thrust)
   - 8,36× mais rápido que Many-threads

3. ❌ **Many-threads tem desempenho ruim em ambos os casos**:
   - Overhead de múltiplas chamadas ao kernel
   - Não recomendado para redução paralela

4. 🎯 **Validação: Todos os kernels produziram resultados corretos**

---

## 📄 Como Gerar o PDF do Relatório

O relatório está em formato Markdown: `relatorio/relatorio_completo.md`

### Opção 1: Usando VS Code (Recomendado)

1. Instalar extensão **Markdown PDF** (yzane.markdown-pdf)
2. Abrir `relatorio/relatorio_completo.md` no VS Code
3. Pressionar `Ctrl+Shift+P`
4. Digitar: "Markdown PDF: Export (pdf)"
5. PDF será gerado em `relatorio/relatorio_completo.pdf`

### Opção 2: Usando pandoc (linha de comando)

```bash
# Instalar pandoc e LaTeX
sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended

# Gerar PDF
./gerar_pdf.sh
```

### Opção 3: Conversor Online

1. Abrir https://www.markdowntopdf.com/
2. Fazer upload de `relatorio/relatorio_completo.md`
3. Baixar o PDF gerado

### Opção 4: LibreOffice

1. Abrir `relatorio/relatorio_completo.md` no LibreOffice Writer
2. Menu: Arquivo → Exportar como PDF
3. Salvar como `relatorio/relatorio_completo.pdf`

---

## 📋 Checklist de Entrega

Conforme especificação do trabalho:

- [x] Código fonte dos kernels
- [x] Script de compilação (`compila.sh`)
- [x] Script de execução (`executar_experimentos.sh`)
- [x] Dados brutos dos experimentos (`.txt`)
- [x] Planilha com dados (CSV e ODS)
- [x] Planilha com folha de resumo
- [x] Gráficos (vazão vs elementos)
- [x] Gráficos (aceleração vs Thrust)
- [x] Gráficos inseridos/referenciados na planilha
- [x] Relatório completo em Markdown
- [ ] Relatório em PDF (gerar conforme instruções acima)
- [x] Nome do(s) autor(es) no código e planilha ⚠️ **ADICIONAR**

---

## ⚠️ Ações Pendentes

1. **Adicionar seu nome:**
   - No arquivo `cudaReduceMax.cu` (linha 11)
   - No relatório `relatorio/relatorio_completo.md` (linha 7)
   - Na planilha ODS (abrir no LibreOffice e adicionar)

2. **Gerar PDF do relatório:**
   - Escolher uma das opções acima
   - Verificar se as imagens aparecem corretamente

3. **Revisar o relatório:**
   - Ler seções de análise e conclusões
   - Ajustar interpretação se necessário

---

## 🛠️ Estrutura do Projeto

```
trabalho_paralela/
├── cudaReduceMax.cu          # Código principal com os kernels
├── helper_cuda.h             # Auxiliares CUDA
├── chrono.c                  # Medição de tempo
├── compila.sh                # Script de compilação
├── executar_experimentos.sh  # Script de execução
├── gerar_pdf.sh              # Script para gerar PDF
├── ENTREGA.md                # Este arquivo
├── resultados/
│   ├── dados_1M_many.txt
│   ├── dados_1M_persist.txt
│   ├── dados_16M_many.txt
│   ├── dados_16M_persist.txt
│   ├── resultados_completos.csv      # ⭐ CSV final
│   ├── resultados_experimentos.ods   # ⭐ Planilha ODS
│   └── plots/
│       ├── vazao_vs_elementos.png
│       ├── aceleracao_vs_elementos.png
│       └── comparacao_completa.png
├── relatorio/
│   ├── relatorio_completo.md         # ⭐ Relatório Markdown
│   └── relatorio_completo.pdf        # ⭐ Gerar este arquivo
└── scripts/
    ├── processar_resultados_completo.py
    └── gerar_planilha_ods.py
```

---

## 📧 Contato

Em caso de dúvidas sobre este trabalho, contatar:

**Aluno:** [SEU EMAIL]  
**Disciplina:** CI1009 - Programação Paralela com GPUs  
**Professor:** W. Zola  
**UFPR - 2º Semestre 2025**

---

**Última atualização:** 06/Outubro/2025
