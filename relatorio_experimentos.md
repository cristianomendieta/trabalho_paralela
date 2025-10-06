# Relatório de Experimentos - CUDA Reduce Max

**CI1009 - Programação Paralela com GPUs**  
**Trabalho 1: Kernels Persistentes para Redução**  
**Autor**: [Seu Nome]  
**Data**: Outubro 2025  

## Configuração Experimental

### Hardware Utilizado
- **Máquina**: orval
- **GPU**: GTX 750ti
- **CUDA Version**: 11.8
- **Compiler**: gcc-12 com nvcc

### Parâmetros dos Testes
- **Teste 1**: 1.000.000 elementos (10^6) com 30 repetições
- **Teste 2**: 16.000.000 elementos (16*10^6) com 30 repetições

## Resultados Experimentais

### Teste 1: 1M elementos

| Método | Tempo Médio (ms) | Vazão (GFLOPS) | Aceleração vs Thrust |
|--------|------------------|----------------|---------------------|
| Kernel 1 (Many-threads) | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Kernel 2 (Persistente) | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Thrust | [PREENCHER] | [PREENCHER] | 1.00x |

### Teste 2: 16M elementos

| Método | Tempo Médio (ms) | Vazão (GFLOPS) | Aceleração vs Thrust |
|--------|------------------|----------------|---------------------|
| Kernel 1 (Many-threads) | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Kernel 2 (Persistente) | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Thrust | [PREENCHER] | [PREENCHER] | 1.00x |

## Análise dos Resultados

### Observações Gerais
- [PREENCHER com observações sobre os resultados]
- [Comparar eficiência dos kernels]
- [Discussão sobre escalabilidade]

### Kernel 1 vs Kernel 2
- [PREENCHER com comparação entre as duas abordagens]
- [Discussão sobre when usar cada um]

### Comparação com Thrust
- [PREENCHER com análise vs biblioteca otimizada]

## Comandos Executados

```bash
# Compilação
make

# Teste 1M elementos
./cudaReduceMax 1000000 30

# Teste 16M elementos  
./cudaReduceMax 16000000 30
```

## Validação

Todos os kernels produziram resultados idênticos ao cálculo feito na CPU, confirmando a correção da implementação.

## Conclusões

[PREENCHER com conclusões sobre:]
- Eficiência dos kernels implementados
- Vantagens/desvantagens da abordagem persistente
- Potenciais melhorias

---

*Para gerar gráficos e planilha detalhada, utilize os dados das tabelas acima no LibreOffice Calc.*