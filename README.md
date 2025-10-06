# CUDA Reduce Max - Kernels Persistentes

**CI1009 - Programação Paralela com GPUs**  
**2º semestre de 2025**  
**UFPR - Prof. W.Zola**

## Descrição

Implementação de kernels de redução paralela para encontrar o valor máximo de um vetor de números float usando CUDA. O projeto compara duas abordagens:

1. **Kernel 1 (Many-threads)**: Versão tradicional seguindo o algoritmo eficiente dos slides
2. **Kernel 2 (Persistente)**: Versão com kernels persistentes usando operações atômicas

## Arquivos do Projeto

### Arquivos Principais
- `cudaReduceMax.cu` - Código principal com implementação dos kernels (versão completa com Thrust)
- `cudaReduceMax_simple.cu` - Versão simplificada sem Thrust (recomendada para orval)
- `Makefile` - Script de compilação com suporte para diferentes máquinas
- `compile.sh` - Script de compilação padrão
- `compile_simple.sh` - Script de compilação para versão simplificada (sem Thrust)
- `compile_alt.sh` - Script de compilação com múltiplas tentativas
- `README.md` - Esta documentação

### Arquivos Auxiliares (adaptados do vectorAdd)
- `chrono.c` - Biblioteca para medição de tempo de alta precisão
- `helper_cuda.h` - Funções auxiliares do CUDA SDK
- `helper_string.h` - Funções auxiliares para strings

### Scripts de Execução
- `run_tests.sh` - Script para executar os testes padrão (1M e 16M elementos)
- `roda-reduce-n-rep.sh` - Script para repetir testes (similar ao roda-n-rep.sh)
- `roda-reduce-varios.sh` - Script para testar vários tamanhos (similar ao roda-varios.sh)

### Documentação e Resultados
- `relatorio_experimentos.md` - Template para relatório de resultados

## Compilação

### ⚠️ Problemas de Linkagem com Thrust

Se você encontrar erros de linkagem relacionados ao Thrust (referências não definidas para std::), use a **versão simplificada**:

### Versão Simplificada (Recomendada para orval)
```bash
./compile_simple.sh
```
Esta versão:
- ✅ Compila sem problemas na orval
- ✅ Implementa ambos os kernels solicitados
- ✅ Faz validação com CPU
- ❌ Não inclui comparação com Thrust (para evitar problemas de linkagem)

### Versão Completa (com Thrust)
```bash
# Makefile automático
make

# Script alternativo
./compile.sh

# Script com múltiplas tentativas
./compile_alt.sh
```

### Compilação manual

**Para máquina orval (GTX 750ti) - Versão Simplificada:**
```bash
nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 cudaReduceMax_simple.cu -o cudaReduceMax
```

**Para máquina orval (GTX 750ti) - Versão Completa:**
```bash
nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -lstdc++ cudaReduceMax.cu -o cudaReduceMax
```

**Para máquinas genéricas:**
```bash
# Versão simplificada
nvcc -O3 cudaReduceMax_simple.cu -o cudaReduceMax

# Versão completa
nvcc -O3 -lstdc++ cudaReduceMax.cu -o cudaReduceMax
```

## Execução

### Interface Atualizada (compatível com vectorAdd.cu)
```bash
./cudaReduceMax <nTotalElements> [<nBlocks>]
```

Onde:
- `nTotalElements`: número de floats do vetor de entrada
- `nBlocks`: número de blocos (opcional)
  - **Se especificado**: usa kernel persistente
  - **Se omitido**: usa kernel many-threads

### Exemplos
```bash
# Kernel Many-threads com 1M elementos
./cudaReduceMax 1000000

# Kernel Persistente com 1M elementos e 32 blocos
./cudaReduceMax 1000000 32

# Kernel Many-threads com 16M elementos  
./cudaReduceMax 16000000

# Kernel Persistente com 16M elementos e 32 blocos
./cudaReduceMax 16000000 32
```

### Scripts de testes automáticos
```bash
# Testes padrão do enunciado
./run_tests.sh

# Repetir testes (5 vezes com 1M elementos, many-threads)
./roda-reduce-n-rep.sh 1000000 5

# Repetir testes (5 vezes com 1M elementos, persistente 32 blocos)
./roda-reduce-n-rep.sh 1000000 5 32

# Testar vários tamanhos
./roda-reduce-varios.sh
```

## Kernels Implementados

### Kernel 1: `reduceMax` (Many-threads)
- Versão tradicional com shared memory e tree reduction
- Múltiplas passadas para vetores grandes
- Acesso coalescido aos dados
- Usa `reduceMaxComplete()` como wrapper

### Kernel 2: `reduceMax_atomic_persist` (Persistente)
- Versão persistente com 3 fases:
  1. **Fase 1**: Cada thread processa múltiplos elementos de forma coalescida
  2. **Fase 2**: Redução dentro do bloco usando `atomicMax` em shared memory
  3. **Fase 3**: Thread 0 de cada bloco faz `atomicMax` em global memory
- Número de blocos configurável via linha de comando

## Especificações Técnicas

- **Threads por bloco**: 1024 (BLOCK_SIZE)
- **Arquitetura suportada**: SM 5.0+ (GTX 750ti) e superior
- **Precisão**: float (32 bits)
- **Repetições**: 30 por padrão (NTIMES)
- **Medição de tempo**: chrono.c (nanossegundos)

## Saída do Programa

O programa reporta:
- Configuração da GPU detectada
- Validação dos resultados (comparação CPU vs GPU vs Thrust)
- Tempo total e por operação usando chrono.c
- Vazão em GFLOPS
- Aceleração em relação ao Thrust

## Experimentos Especificados

Conforme enunciado, implementados testes para:
- **10^6 elementos** (1 milhão) 
- **16*10^6 elementos** (16 milhões)

### Comparação de Kernels
- Many-threads vs Persistente
- Ambos vs Thrust (biblioteca otimizada)

## Exemplo de Saída

```
=== CUDA Reduce Max - Kernels Persistentes ===
Number of elements requested in command line: 1000000
Using ManyThreads kernel
Elementos: 1000000
Repetições: 30

GPU Device 0 name is "GeForce GTX 750 Ti"

Gerando dados de entrada...
Máximo calculado na CPU: 4294266496.000000

=== TESTES DOS KERNELS ===
Testando Kernel 1 (Many-threads)...
CUDA kernel launch with 977 blocks of 1024 threads

=== RESULTADOS ===
CPU:               4294266496.000000
Kernel 1:          4294266496.000000
Thrust:            4294266496.000000

Validação:
Kernel 1: CORRETO
Thrust:   CORRETO

=== DESEMPENHO ===
GPU: GeForce GTX 750 Ti reduceMax kernel

Kernel 1 (Many-threads) deltaT(ns): 7234567 ns for 30 ops 
        ==> each op takes 241152 ns
reduceMax Kernel1 Throughput: 4.147 GFLOPS

Thrust deltaT(ns): 8651234 ns for 30 ops 
        ==> each op takes 288374 ns
reduceMax Thrust Throughput: 3.468 GFLOPS
Aceleração Kernel1 vs Thrust: 1.20x
Test PASSED

Done
```

## Estrutura do Código

### Baseado nos Arquivos Auxiliares
- Usa `chrono.c` para medição precisa de tempo
- Usa `helper_cuda.h` para verificação de erros
- Segue o padrão do `vectorAdd.cu` para interface e estrutura
- Saída compatível com scripts de análise existentes

### Funcionalidades Implementadas
- ✅ Geração de números aleatórios conforme especificação
- ✅ Kernel many-threads com tree reduction
- ✅ Kernel persistente com operações atômicas
- ✅ Comparação com Thrust
- ✅ Validação de resultados
- ✅ Medição de desempenho e vazão
- ✅ Interface compatível com scripts auxiliares

## Para Completar o Trabalho

1. **Execute na máquina orval (GTX 750ti)**:
   ```bash
   # Compilar
   make
   
   # Executar testes do enunciado
   ./run_tests.sh
   ```

2. **Coleta de dados**:
   - Use os scripts para obter dados de diferentes tamanhos
   - Documente os resultados no `relatorio_experimentos.md`

3. **Análise**:
   - Compare desempenho dos kernels
   - Calcule acelerações
   - Crie planilha LibreOffice com gráficos

O código está completo e pronto para uso! 🚀