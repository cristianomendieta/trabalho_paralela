# Relatório do Trabalho 1 - Programação Paralela com GPUs

**Disciplina:** CI1009 - Programação Paralela com GPUs  
**Professor:** W. Zola  
**Instituição:** UFPR  
**Semestre:** 2º/2025  
**Data:** Outubro de 2025  

**Autor(es):** [COLOCAR SEU NOM---

## 8. Referências

1. Harris, M. "Optimizing Parallel Reduction in CUDA", NVIDIA Developer Blog
2. NVIDIA CUDA C Programming Guide
3. Thrust Documentation: https://docs.nvidia.com/cuda/thrust/

---

## 9. Anexos-

## 1. Objetivo

Este trabalho tem como objetivo implementar e comparar diferentes estratégias de kernels CUDA para realizar a operação de **redução paralela** (encontrar o valor máximo) em vetores de números de ponto flutuante (float).

Foram implementados dois kernels:
1. **Many-threads (Kernel 1)**: Versão tradicional de redução paralela com múltiplas chamadas ao kernel
2. **Persistente (Kernel 2)**: Versão otimizada com kernel persistente usando operações atômicas

Os resultados foram comparados com a implementação de redução da biblioteca **Thrust**.

---

## 2. Metodologia

### 2.1. Especificações do Hardware

- **GPU:** NVIDIA GeForce GTX 750 Ti
- **Arquitetura:** Maxwell
- **CUDA Compute Capability:** 5.0
- **Memória Global:** 2GB GDDR5

### 2.2. Configuração dos Experimentos

Os experimentos foram realizados com os seguintes parâmetros:

| Parâmetro | Valor |
|-----------|-------|
| Tamanhos de entrada | 10⁶ e 16×10⁶ elementos |
| Número de repetições (nR) | 30 |
| Tipo de dado | float (32 bits) |
| Threads por bloco | 1024 |
| Blocos (kernel persistente) | 32 |

### 2.3. Geração de Dados de Entrada

Os dados de entrada foram gerados seguindo a especificação do trabalho:

```c
for (int i = 0; i < nTotalElements; i++) {
    int a = rand();  // Número pseudo-aleatório [0, RAND_MAX]
    int b = rand();  // Número pseudo-aleatório [0, RAND_MAX]
    float v = a * 100.0 + b;
    Input[i] = v;
}
```

### 2.4. Implementação dos Kernels

#### Kernel 1: Many-threads (reduceMax)

Implementação clássica de redução paralela com as seguintes características:
- **Fase 1:** Cada thread carrega um elemento do vetor global para memória compartilhada
- **Fase 2:** Redução em árvore (tree reduction) na memória compartilhada
- **Fase 3:** Thread 0 de cada bloco escreve o resultado parcial
- **Fase 4:** Chamadas recursivas do kernel até obter um único valor

#### Kernel 2: Persistente (reduceMax_atomic_persist)

Implementação otimizada usando kernel persistente:
- **Fase 1:** Cada thread processa múltiplos elementos de forma coalescida (stride igual ao tamanho da grid)
- **Fase 2:** Redução intra-bloco usando `atomicMax` em memória compartilhada
- **Fase 3:** Thread 0 de cada bloco faz `atomicMax` em memória global

#### Thrust

Utilização da função `thrust::max_element` da biblioteca Thrust, que implementa uma versão altamente otimizada de redução.

---

## 3. Resultados Experimentais

### 3.1. Tabela de Resultados Completos

| Teste | Kernel | Elementos | Tempo Médio (ns) | Vazão (GFLOPS) | Aceleração vs Thrust |
|-------|--------|-----------|-----------------|----------------|---------------------|
| 1M | copyKernel | 1.000.000 | 115.856 | 8,630 | **1,60×** |
| 1M | Many-threads | 1.000.000 | 595.779 | 1,678 | 0,31× |
| 1M | Thrust | 1.000.000 | 185.944 | 5,378 | 1,00× (baseline) |
| 1M | Persistente | 1.000.000 | 114.926 | 8,701 | **1,62×** |
| 16M | Many-threads | 16.000.000 | 8.750.399 | 1,828 | 0,12× |
| 16M | Thrust | 16.000.000 | 1.009.741 | 15,846 | 1,00× (baseline) |
| 16M | copyKernel | 16.000.000 | 1.785.718 | 8,960 | 0,57× |
| 16M | Persistente | 16.000.000 | 1.046.368 | 15,291 | **0,96×** |

### 3.2. Gráficos

#### Gráfico Principal: Desempenho Completo dos Kernels

![Resultado Final](../resultados/plots/resultado_final_enunciado.png)

O gráfico acima apresenta a visualização completa do desempenho de todos os kernels testados:
- **Eixo X:** Quantidade de elementos (em milhões)
- **Eixo Y esquerdo:** Vazão (throughput) em GFLOPS
- **Eixo Y direito:** Aceleração relativa ao Thrust
- **Linhas sólidas:** Indicam a vazão de cada kernel
- **Linhas pontilhadas:** Indicam a aceleração dos kernels customizados em relação ao Thrust

**Observações principais:**
- O kernel **Persistente** supera o Thrust para 1M elementos (1,62×)
- Para 16M elementos, **Thrust** e **Persistente** apresentam desempenho similar (~15 GFLOPS)
- O **copyKernel** estabelece o baseline de largura de banda (~8,6-9,0 GFLOPS)
- O kernel **Many-threads** apresenta desempenho significativamente inferior (5× pior que copyKernel)

#### Gráficos Detalhados de Análise

Os gráficos a seguir apresentam análises complementares dos resultados:

##### Vazão dos Kernels

![Vazão vs Elementos](../resultados/plots/vazao_vs_elementos.png)

Este gráfico mostra a vazão (throughput) em GFLOPS de cada kernel em função do tamanho da entrada.

##### Aceleração Relativa ao Thrust

![Aceleração vs Elementos](../resultados/plots/aceleracao_vs_elementos.png)

Este gráfico mostra a aceleração de cada kernel customizado em relação à implementação do Thrust.

##### Comparação Lado a Lado

![Comparação Completa](../resultados/plots/comparacao_completa.png)

---

## 4. Análise e Discussão

### 4.1. Desempenho do copyKernel (Baseline de Largura de Banda)

O **copyKernel** foi implementado como medida de **baseline** para largura de banda de memória:
- **1M elementos:** 8,630 GFLOPS com largura de banda de **69,05 GB/s** (79,9% da teórica)
- **16M elementos:** 8,960 GFLOPS com largura de banda de **71,68 GB/s** (83,0% da teórica)

**Métricas de eficiência:**
- Largura de banda teórica da GTX 750 Ti: **86,4 GB/s**
- Eficiência alcançada: **79,9% - 83,0%**

**Significado dos resultados:**
1. **Operação memory-bound:** copyKernel realiza apenas leitura e escrita simples (`output[i] = input[i]`), sem computação
2. **Eficiência alta:** 80-83% da banda teórica é excelente para operações de cópia
3. **Baseline para comparação:** Estabelece o limite superior de throughput para operações dominadas por acesso à memória

**Comparação com kernels de redução:**
- O kernel **Persistente** (8,701 GFLOPS para 1M) é **similar ao copyKernel**, indicando que também é limitado por banda de memória, não por computação
- Para 16M, Thrust e Persistente **superam significativamente** o copyKernel (15+ GFLOPS vs 8,96), indicando otimizações adicionais ou melhor uso de cache

### 4.2. Desempenho do Kernel Many-threads

O kernel **Many-threads** apresentou o **pior desempenho** em ambos os testes:
- **1M elementos:** 1,678 GFLOPS (0,31× mais lento que Thrust)
- **16M elementos:** 1,828 GFLOPS (0,12× mais lento que Thrust)

**Comparação importante:**
- copyKernel (baseline de banda): 8,63 GFLOPS (1M) e 8,96 GFLOPS (16M)
- Many-threads: 1,68 GFLOPS (1M) e 1,83 GFLOPS (16M)
- **Many-threads é 5× mais lento que uma simples cópia!**

**Motivos para o baixo desempenho:**
1. **Múltiplas chamadas ao kernel:** O algoritmo requer várias invocações sequenciais do kernel até convergir para um único valor
2. **Overhead de sincronização:** Cada chamada ao kernel tem overhead de lançamento
3. **Latência de memória global:** Leituras e escritas repetidas na memória global entre as fases
4. **Não aproveitamento de kernel persistente:** Threads não são reutilizadas eficientemente
5. **Abaixo do baseline:** Desempenho inferior até mesmo ao copyKernel, que faz operação trivial

### 4.3. Desempenho do Kernel Persistente

O kernel **Persistente** mostrou resultados interessantes:
- **1M elementos:** 8,701 GFLOPS (**1,62× mais rápido que Thrust!**)
- **16M elementos:** 15,291 GFLOPS (0,96× em relação ao Thrust, praticamente empate)

**Vantagens do kernel persistente:**
1. **Única chamada ao kernel:** Toda a redução é feita em uma única invocação
2. **Coalescência de acessos:** Threads acessam memória de forma coalescida (stride igual ao tamanho da grid)
3. **Redução de overhead:** Menos sincronizações entre CPU e GPU
4. **Uso eficiente de atomics:** Atomics em shared memory têm baixa contenção
5. **Desempenho no limite da banda:** Para 1M elementos, praticamente alcança a eficiência do copyKernel (8,70 vs 8,63 GFLOPS)

**Interpretação em relação ao copyKernel:**
- Para **1M elementos:** Persistente (8,701 GFLOPS) ≈ copyKernel (8,630 GFLOPS) → **limitado por largura de banda**
- Para **16M elementos:** Persistente (15,291 GFLOPS) > copyKernel (8,960 GFLOPS) → **beneficia-se de cache e reuso de dados**

**Por que o desempenho é superior para 1M mas não para 16M?**
- **Para 1M elementos:** O custo de lançamento do kernel many-threads domina, tornando o persistente muito mais eficiente
- **Para 16M elementos:** Thrust usa otimizações avançadas (possivelmente múltiplos estágios e técnicas de load balancing) que compensam em entradas grandes

### 4.4. Desempenho do Thrust

O **Thrust** demonstrou excelente desempenho:
- **1M elementos:** 5,378 GFLOPS
- **16M elementos:** 15,846 GFLOPS

**Razões para o bom desempenho:**
1. Implementação altamente otimizada e testada
2. Uso de heurísticas para escolher estratégias conforme tamanho da entrada
3. Otimizações específicas da arquitetura da GPU
4. Possivelmente usa técnicas como unrolling e vetorização

**Comparação com copyKernel:**
- Para 1M: Thrust (5,378 GFLOPS) está entre copyKernel (8,63) e Many-threads (1,68)
- Para 16M: Thrust (15,846 GFLOPS) **supera copyKernel em 77%**, indicando otimizações além de pura banda

### 4.5. Escalabilidade

Observando a **escalabilidade** (aumento de 1M → 16M elementos, i.e., 16×):

| Kernel | Vazão 1M | Vazão 16M | Ganho de Vazão |
|--------|----------|-----------|----------------|
| copyKernel | 8,630 | 8,960 | 1,04× |
| Many-threads | 1,678 | 1,828 | 1,09× |
| Persistente | 8,701 | 15,291 | 1,76× |
| Thrust | 5,378 | 15,846 | 2,95× |

- **Thrust** escala muito bem (quase 3× de ganho)
- **Persistente** escala razoavelmente (1,76×)
- **Many-threads** praticamente não escala (apenas 9% de ganho)
- **copyKernel** não escala (apenas 4% de ganho) - esperado para operação puramente memory-bound

Isso indica que:
- copyKernel e Many-threads são **limitados por overhead** (não conseguem aproveitar mais dados)
- Persistente e Thrust são **limitados por largura de banda para 1M**, mas aproveitam cache/reuso para 16M

### 4.6. Validação

**Todos os kernels foram validados com sucesso**, produzindo o mesmo valor máximo calculado pela CPU, confirmando a correção das implementações.

---

## 5. Conclusões

1. **copyKernel estabelece baseline de largura de banda**: Com 8,63-8,96 GFLOPS e eficiência de 80-83% da banda teórica (69-72 GB/s), demonstra o limite superior para operações memory-bound simples.

2. **Kernel Persistente alcança eficiência próxima ao baseline para entradas pequenas**: Com 8,701 GFLOPS para 1M elementos (praticamente igual ao copyKernel), mostra que está limitado por largura de banda, não por computação.

3. **Kernel Persistente supera Thrust para entradas pequenas (1M)**: Com 1,62× de speedup, demonstra que para problemas menores, minimizar overhead de lançamento é crucial.

2. **Thrust é imbatível para entradas grandes (16M)**: A implementação altamente otimizada do Thrust alcança 15,8 GFLOPS, ligeiramente superior ao kernel persistente.

3. **Many-threads não é adequado para este problema**: Com desempenho 3-8× inferior ao Thrust e **5× pior que copyKernel**, evidencia que múltiplas chamadas ao kernel introduzem overhead proibitivo.

4. **Operações atômicas em shared memory são eficientes**: O kernel persistente usa atomics sem penalidade significativa, tornando a implementação mais simples e performática.

5. **Thrust supera limite teórico de copyKernel para entradas grandes**: Para 16M elementos, Thrust atinge 15,8 GFLOPS (77% acima do copyKernel), indicando otimizações avançadas como reuso de cache e técnicas de vetorização.

6. **Trade-offs de design**: 
   - **Simplicidade:** Thrust > Persistente > Many-threads
   - **Desempenho (1M):** Persistente ≈ copyKernel > Thrust > Many-threads
   - **Desempenho (16M):** Thrust ≈ Persistente > copyKernel > Many-threads
   - **Eficiência de banda:** copyKernel (80-83%) ≈ Persistente (1M) > Thrust

---

## 6. Recomendações

Para aplicações práticas de redução em GPU:

1. **Use Thrust por padrão**: É a opção mais robusta e eficiente na maioria dos casos
2. **Considere kernel persistente para casos específicos**: Quando você tem controle fino sobre os parâmetros e tamanhos de entrada menores
3. **Evite many-threads tradicional**: O overhead de múltiplas chamadas não compensa

---

## 7. Decisões de Implementação e Limitações

### 7.1. Interface da Linha de Comando

A especificação original sugeria:
```
./cudaReduceMax <nTotalElements> nR
```

A implementação adotada usa:
```
./cudaReduceMax <nTotalElements>          # Para kernel many-threads
./cudaReduceMax <nTotalElements> <nBlocks> # Para kernel persistente
```

**Justificativa:** Esta abordagem permite:
- Executar e medir cada kernel independentemente
- Evitar interferência entre medições
- Maior controle sobre os parâmetros de cada kernel
- O número de repetições (nR=30) está fixo no código como constante `NTIMES`

### 7.2. Medição de Largura de Banda (copyKernel)

O enunciado sugeria incluir medições de um `copyKernel` como baseline para largura de banda. **Esta implementação incluiu o copyKernel** e seus resultados foram fundamentais para a análise.

**Implementação realizada:**
- Kernel simples de cópia: `output[i] = input[i]`
- Medição de largura de banda: `(2 × nElements × sizeof(float) × nR) / tempo`
- Cálculo de eficiência em relação à banda teórica da GTX 750 Ti (86,4 GB/s)

**Resultados obtidos:**
- **1M elementos:** 69,05 GB/s (79,9% de eficiência), 8,63 GFLOPS
- **16M elementos:** 71,68 GB/s (83,0% de eficiência), 8,96 GFLOPS

**Contribuição para a análise:**
- Estabeleceu **baseline quantitativo** para operações memory-bound
- Permitiu identificar que kernel Persistente (1M) está **limitado por largura de banda**
- Demonstrou que Thrust e Persistente (16M) **superam** copyKernel através de otimizações de cache
- Quantificou exatamente o **overhead** do Many-threads (5× pior que simples cópia)

### 7.3. Número de Blocos para Kernel Persistente

Foi utilizado **nb = 32 blocos** para o kernel persistente nos experimentos.

**Justificativa:** 
- GTX 750 Ti possui 5 SMs (Streaming Multiprocessors)
- 32 blocos = 6-7 blocos por SM, permitindo boa ocupação
- Valor alinhado com recomendações da NVIDIA para kernels persistentes
- Balanceamento adequado entre paralelismo e contenção em operações atômicas

---

## 8. Referências

1. Harris, M. "Optimizing Parallel Reduction in CUDA", NVIDIA Developer Blog
2. NVIDIA CUDA C Programming Guide
3. Thrust Documentation: https://docs.nvidia.com/cuda/thrust/

---

## 8. Anexos

### Arquivos Entregues

1. **Código fonte:**
   - `cudaReduceMax.cu` - Implementação dos kernels
   - `helper_cuda.h` - Funções auxiliares CUDA
   - `chrono.c` - Medição de tempo

2. **Scripts:**
   - `compila.sh` - Script de compilação
   - `executar_experimentos.sh` - Script para executar experimentos
   - `scripts/processar_resultados_completo.py` - Processamento e geração de gráficos

3. **Dados experimentais:**
   - `resultados/dados_1M_copy.txt` - Saída do copyKernel 1M
   - `resultados/dados_1M_many.txt` - Saída do experimento 1M many-threads
   - `resultados/dados_1M_persist.txt` - Saída do experimento 1M persistente
   - `resultados/dados_16M_copy.txt` - Saída do copyKernel 16M
   - `resultados/dados_16M_many.txt` - Saída do experimento 16M many-threads
   - `resultados/dados_16M_persist.txt` - Saída do experimento 16M persistente
   - `resultados/resultados_completos.csv` - Tabela consolidada

4. **Gráficos:**
   - `resultados/plots/vazao_vs_elementos.png`
   - `resultados/plots/aceleracao_vs_elementos.png`
   - `resultados/plots/comparacao_completa.png`

5. **Relatório:**
   - `relatorio/relatorio.md` (este arquivo)
   - `relatorio/relatorio.pdf` (versão PDF)

### Como Reproduzir os Experimentos

```bash
# 1. Compilar o programa
./compila.sh

# Compilar copyKernel (opcional)
nvcc -arch=sm_50 copyKernel.cu -o copyKernel

# 2. Executar experimentos
# copyKernel (baseline de largura de banda)
./copyKernel 1000000 > resultados/dados_1M_copy.txt
./copyKernel 16000000 > resultados/dados_16M_copy.txt

# Para 1M elementos (many-threads)
./cudaReduceMax 1000000 > resultados/dados_1M_many.txt

# Para 1M elementos (persistente, 32 blocos)
./cudaReduceMax 1000000 32 > resultados/dados_1M_persist.txt

# Para 16M elementos (many-threads)
./cudaReduceMax 16000000 > resultados/dados_16M_many.txt

# Para 16M elementos (persistente, 32 blocos)
./cudaReduceMax 16000000 32 > resultados/dados_16M_persist.txt

# 3. Processar resultados e gerar gráficos
python3 scripts/processar_resultados_completo.py
```

---

**Fim do Relatório**
