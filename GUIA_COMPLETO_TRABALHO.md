# Checklist Completo - Trabalho 1: Kernels Persistentes

## ✅ Implementação (CONCLUÍDO)

### Kernels Obrigatórios
- [x] **Kernel 1**: `reduceMax` (many-threads) - ✅ Implementado
- [x] **Kernel 2**: `reduceMax_atomic_persist` (persistente) - ✅ Implementado

### Especificações Técnicas
- [x] Operação: Redução para encontrar valor **máximo** - ✅ 
- [x] Tipo de dados: `float` (32 bits) - ✅
- [x] Geração de números: `v = a * 100.0 + b` (conforme especificado) - ✅
- [x] Interface: `./cudaReduceMax <nElements> [<nBlocks>]` - ✅
- [x] Acesso coalescido - ✅
- [x] Compilação para orval (GTX 750ti) - ✅

## 🎯 EXPERIMENTOS OBRIGATÓRIOS

### Testes Especificados no Enunciado
- [ ] **Teste 1**: 10^6 elementos (1 milhão) com nR = 30
- [ ] **Teste 2**: 16*10^6 elementos (16 milhões) com nR = 30

### Como Executar os Experimentos
```bash
# Na máquina orval, execute:

# Teste 1: 1M elementos - Many-threads
./cudaReduceMax 1000000

# Teste 1: 1M elementos - Persistente (32 blocos)
./cudaReduceMax 1000000 32

# Teste 2: 16M elementos - Many-threads  
./cudaReduceMax 16000000

# Teste 2: 16M elementos - Persistente (32 blocos)
./cudaReduceMax 16000000 32

# OU use o script automático:
./run_tests.sh
```

## 📊 COLETA DE DADOS

### Dados a Coletar (para cada teste)
- [ ] **Tempo médio** de execução (30 repetições)
- [ ] **Vazão** em GFLOPS
- [ ] **Validação** de resultados (vs CPU)
- [ ] **Comparação** entre kernels

### Script para Coleta Automatizada
```bash
# Para múltiplas repetições e análise:
./roda-reduce-n-rep.sh 1000000 30     # Many-threads, 30 vezes
./roda-reduce-n-rep.sh 1000000 30 32  # Persistente, 30 vezes

./roda-reduce-n-rep.sh 16000000 30    # Many-threads, 30 vezes  
./roda-reduce-n-rep.sh 16000000 30 32 # Persistente, 30 vezes
```

## 📈 ANÁLISE E DOCUMENTAÇÃO

### 1. Planilha LibreOffice (OBRIGATÓRIO)
- [ ] **Folha 1**: Dados brutos dos experimentos
- [ ] **Folha 2**: Tabela sumarizada com médias
- [ ] **Gráfico**: 
  - Eixo X: Quantidade de elementos (em milhões)
  - Eixo Y esquerdo: Vazão em GFLOPS
  - Eixo Y direito: Aceleração relativa
  - Mostrar: Kernel1, Kernel2, comparação entre eles

### 2. Relatório em PDF (OBRIGATÓRIO)
- [ ] Descrição dos algoritmos implementados
- [ ] Análise dos resultados experimentais
- [ ] Gráficos com comparações
- [ ] Conclusões sobre eficiência dos kernels

## 📝 TEMPLATE PARA COLETA DE DADOS

### Resultado Esperado de Cada Teste:
```
=== GPU Device 0 name is "GeForce GTX 750 Ti" ===
Elementos: 1000000
Repetições: 30

=== RESULTADOS ===
CPU: [valor]
Kernel 1: [valor] (deve ser igual ao CPU)
Validação: CORRETO

=== DESEMPENHO ===
Kernel 1 (Many-threads) deltaT(ns): [X] ns for 30 ops
        ==> each op takes [Y] ns
reduceMax Kernel1 Throughput: [Z] GFLOPS
```

Anote estes valores para:
- 1M elementos - Many-threads
- 1M elementos - Persistente
- 16M elementos - Many-threads  
- 16M elementos - Persistente

## 🚀 PRÓXIMOS PASSOS IMEDIATOS

1. **Execute na orval**:
   ```bash
   ssh orval
   cd [seu_diretorio]
   ./compile_smart.sh
   ```

2. **Rode experimentos**:
   ```bash
   ./run_tests.sh > resultados_experimentos.txt
   ```

3. **Coleta dados específicos**:
   ```bash
   # Coleta para planilha
   echo "=== DADOS PARA PLANILHA ===" > dados_planilha.txt
   ./roda-reduce-n-rep.sh 1000000 30 >> dados_planilha.txt
   ./roda-reduce-n-rep.sh 1000000 30 32 >> dados_planilha.txt
   ./roda-reduce-n-rep.sh 16000000 30 >> dados_planilha.txt
   ./roda-reduce-n-rep.sh 16000000 30 32 >> dados_planilha.txt
   ```

## 📋 ENTREGÁVEIS FINAIS

- [ ] **Código fonte**: `cudaReduceMax_simple.cu` (ou versão completa se compilar)
- [ ] **Makefile/Scripts**: Para compilação
- [ ] **Scripts de execução**: Para reproduzir experimentos
- [ ] **Planilha LibreOffice**: Com dados e gráficos
- [ ] **Relatório PDF**: Com análise completa
- [ ] **Nome dos autores**: No código e planilha

## ⚠️ OBSERVAÇÕES IMPORTANTES

1. **GPU Específica**: Todos os resultados devem ser da GTX 750ti (orval)
2. **Repetições**: 30 repetições conforme especificado
3. **Validação**: Sempre verificar se resultado == CPU
4. **Comparação**: Focar na comparação entre os dois kernels (many-threads vs persistente)

---

**Seu código já está 100% pronto! Agora é só executar os experimentos e documentar os resultados.** 🎯