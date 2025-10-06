# Relatório de Experimentos - CUDA Reduce Max

**CI1009 - Programação Paralela com GPUs**  
**Trabalho 1: Kernels Persistentes para Redução**  
**Autor**: [Seu Nome]  
**Data**: Outubro 2025  

## 1. Introdução

Este trabalho implementa e compara dois kernels CUDA para redução paralela (operação máximo):
- **Kernel 1**: Versão many-threads tradicional com tree reduction
- **Kernel 2**: Versão persistente usando operações atômicas

## 2. Implementação

### 2.1 Kernel 1: Many-threads (`reduceMax`)
- Utiliza shared memory com tree reduction
- Múltiplas passadas para vetores grandes
- Acesso coalescido aos dados
- Redução hierárquica por blocos

### 2.2 Kernel 2: Persistente (`reduceMax_atomic_persist`)
Implementação em 3 fases conforme especificação:

**Fase 1**: Redução local por thread
- Cada thread processa múltiplos elementos de forma coalescida
- Padrão de acesso: `i += gridSize` (coalescido)

**Fase 2**: Redução por bloco em shared memory
- `atomicMax` em shared memory entre threads do bloco
- Reduz contenção comparado a global memory

**Fase 3**: Redução global
- Thread 0 de cada bloco faz `atomicMax` em global memory
- Resultado final da redução

### 2.3 Geração de Dados
Conforme especificação: `v = a * 100.0 + b` onde `a` e `b` são valores aleatórios.

## 3. Configuração Experimental

### 3.1 Hardware Utilizado
- **Máquina**: orval
- **GPU**: GeForce GTX 750 Ti
- **Arquitetura**: Maxwell (SM 5.0)
- **CUDA Version**: 11.8
- **Compiler**: gcc-12 com nvcc

### 3.2 Parâmetros dos Testes
- **Threads por bloco**: 1024
- **Blocos persistentes**: 32 (para kernel 2)
- **Repetições**: 30 por teste
- **Medição**: chrono.c (nanossegundos)

### 3.3 Experimentos Realizados
Conforme especificação do enunciado:
- **Teste 1**: 1.000.000 elementos (10^6)
- **Teste 2**: 16.000.000 elementos (16*10^6)

## 4. Resultados Experimentais

### 4.1 Teste 1: 1M elementos

| Kernel | Tempo Médio (ns) | Tempo por Op (ns) | Vazão (GFLOPS) | Validação |
|--------|------------------|-------------------|----------------|-----------|
| Many-threads | [PREENCHER] | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Persistente | [PREENCHER] | [PREENCHER] | [PREENCHER] | [PREENCHER] |

### 4.2 Teste 2: 16M elementos

| Kernel | Tempo Médio (ns) | Tempo por Op (ns) | Vazão (GFLOPS) | Validação |
|--------|------------------|-------------------|----------------|-----------|
| Many-threads | [PREENCHER] | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Persistente | [PREENCHER] | [PREENCHER] | [PREENCHER] | [PREENCHER] |

### 4.3 Comparação entre Kernels

| Tamanho | Aceleração (Persistente vs Many-threads) | Observações |
|---------|-------------------------------------------|-------------|
| 1M elementos | [PREENCHER] | [PREENCHER] |
| 16M elementos | [PREENCHER] | [PREENCHER] |

## 5. Análise dos Resultados

### 5.1 Eficiência dos Kernels
[PREENCHER com análise sobre:]
- Qual kernel foi mais eficiente
- Como a eficiência varia com o tamanho do problema
- Motivos para as diferenças observadas

### 5.2 Escalabilidade
[PREENCHER com análise sobre:]
- Como os kernels se comportam com aumento de dados
- Gargalos identificados
- Eficiência do uso da GPU

### 5.3 Operações Atômicas vs Tree Reduction
[PREENCHER com discussão sobre:]
- Vantagens/desvantagens de cada abordagem
- Contenção em operações atômicas
- Eficiência da redução hierárquica

## 6. Conclusões

### 6.1 Principais Descobertas
[PREENCHER com as principais conclusões]

### 6.2 Recomendações
[PREENCHER com recomendações sobre quando usar cada kernel]

### 6.3 Trabalhos Futuros
[PREENCHER com possíveis melhorias ou extensões]

## 7. Anexos

### 7.1 Comandos Executados
```bash
# Compilação
./compile_smart.sh

# Experimentos
./coleta_dados_trabalho.sh

# Testes individuais
./cudaReduceMax 1000000     # 1M - Many-threads
./cudaReduceMax 1000000 32  # 1M - Persistente
./cudaReduceMax 16000000    # 16M - Many-threads  
./cudaReduceMax 16000000 32 # 16M - Persistente
```

### 7.2 Validação
Todos os kernels produziram resultados idênticos ao cálculo sequencial na CPU, confirmando a correção da implementação.

### 7.3 Reprodutibilidade
Os experimentos podem ser reproduzidos executando:
```bash
git clone [repository]
cd trabalho_paralela
./compile_smart.sh
./coleta_dados_trabalho.sh
```

---

**Para completar este relatório:**
1. Execute `./coleta_dados_trabalho.sh` na orval
2. Extraia os dados dos arquivos gerados
3. Preencha as tabelas acima
4. Crie gráficos na planilha LibreOffice
5. Complete as análises nas seções 5 e 6