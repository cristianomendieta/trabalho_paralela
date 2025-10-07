# CI1009 - Programação Paralela com GPUs
# UFPR - 2025

# Alvos principais
TARGET = cudaReduceMax
TARGET_COPY = copyKernel

# Arquivos fonte
SOURCE = cudaReduceMax.cu
SOURCE_COPY = copyKernel.cu
SOURCE_SIMPLE = cudaReduceMax_simple.cu

HOSTNAME := $(shell hostname)

ifeq ($(HOSTNAME),orval)
    # GTX 750 Ti (sm_50) na Orval com gcc-12
    NVCC_FLAGS = -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12
    NVCC_FULL = $(NVCC_FLAGS) -lstdc++
    NVCC_SIMPLE = $(NVCC_FLAGS)
else
    NVCC_FLAGS = -O3
    NVCC_FULL = $(NVCC_FLAGS) -lstdc++
    NVCC_SIMPLE = $(NVCC_FLAGS)
endif

# Compilador CUDA
NVCC = nvcc

all: check-nvcc
	@if $(NVCC) $(NVCC_FULL) $(SOURCE) -o $(TARGET) 2>/dev/null; then \
		echo "✅ Versão completa compilada com sucesso!"; \
	else \
		echo "⚠️  Versão completa falhou (problemas de linkagem com Thrust)"; \
		echo "🔄 Tentando versão simplificada..."; \
		if [ -f "$(SOURCE_SIMPLE)" ]; then \
			$(NVCC) $(NVCC_SIMPLE) $(SOURCE_SIMPLE) -o $(TARGET); \
			echo "✅ Versão simplificada compilada!"; \
		else \
			echo "❌ Arquivo $(SOURCE_SIMPLE) não encontrado"; \
			exit 1; \
		fi; \
	fi
	@echo ""
	@echo "Execute: make test"

# Forçar compilação completa (com Thrust)
full: check-nvcc
	@echo "=== Compilando versão COMPLETA (forçando Thrust) ==="
	$(NVCC) $(NVCC_FULL) $(SOURCE) -o $(TARGET)
	@echo "✅ Compilação completa finalizada!"

# Compilar copyKernel
copy: check-nvcc
	@echo "=== Compilando copyKernel ==="
	$(NVCC) $(NVCC_FLAGS) $(SOURCE_COPY) -o $(TARGET_COPY)
	@echo "✅ copyKernel compilado!"

# Compilar ambos
both: all copy

# Verificar se nvcc está disponível
check-nvcc:
	@which $(NVCC) > /dev/null || (echo "❌ Erro: NVCC não encontrado. Instale o CUDA Toolkit." && exit 1)

# Limpar arquivos compilados
clean:
	@echo "🧹 Limpando arquivos compilados..."
	rm -f $(TARGET) $(TARGET_COPY)
	@echo "✅ Limpeza concluída!"

# Executar testes do cudaReduceMax
test: $(TARGET)
	@echo "=== Executando Testes cudaReduceMax ==="
	@echo ""
	@echo "📊 Teste 1: 1M elementos (Many-threads)"
	./$(TARGET) 1000000
	@echo ""
	@echo "📊 Teste 2: 1M elementos (Persistente, 32 blocos)"
	./$(TARGET) 1000000 32
	@echo ""
	@echo "📊 Teste 3: 16M elementos (Many-threads)"
	./$(TARGET) 16000000
	@echo ""
	@echo "📊 Teste 4: 16M elementos (Persistente, 32 blocos)"
	./$(TARGET) 16000000 32

# Executar testes do copyKernel
test-copy: $(TARGET_COPY)
	@echo "=== Executando Testes copyKernel ==="
	@echo ""
	@echo "📊 Teste 1: 1M elementos"
	./$(TARGET_COPY) 1000000
	@echo ""
	@echo "📊 Teste 2: 16M elementos"
	./$(TARGET_COPY) 16000000

# Executar todos os testes e salvar resultados
test-all: both
	@echo "=== Executando TODOS os Testes ==="
	@mkdir -p resultados
	@echo ""
	@echo "📊 copyKernel 1M..."
	./$(TARGET_COPY) 1000000 | tee resultados/dados_1M_copy.txt
	@echo ""
	@echo "📊 Many-threads 1M..."
	./$(TARGET) 1000000 | tee resultados/dados_1M_many.txt
	@echo ""
	@echo "📊 Persistente 1M..."
	./$(TARGET) 1000000 32 | tee resultados/dados_1M_persist.txt
	@echo ""
	@echo "📊 copyKernel 16M..."
	./$(TARGET_COPY) 16000000 | tee resultados/dados_16M_copy.txt
	@echo ""
	@echo "📊 Many-threads 16M..."
	./$(TARGET) 16000000 | tee resultados/dados_16M_many.txt
	@echo ""
	@echo "📊 Persistente 16M..."
	./$(TARGET) 16000000 32 | tee resultados/dados_16M_persist.txt
	@echo ""
	@echo "✅ Todos os testes concluídos! Resultados salvos em resultados/"


# Mostrar ajuda
help:
	@echo "=== Makefile - CUDA Reduce Max ==="
	@echo ""
	@echo "Alvos disponíveis:"
	@echo "  make              - Compila cudaReduceMax (tenta completa, senão simplificada)"
	@echo "  make full         - Força compilação completa com Thrust"
	@echo "  make copy         - Compila apenas copyKernel"
	@echo "  make both         - Compila cudaReduceMax e copyKernel"
	@echo "  make test         - Executa testes do cudaReduceMax"
	@echo "  make test-copy    - Executa testes do copyKernel"
	@echo "  make results      - Executa testes + processa resultados + gera gráficos"
	@echo "  make debug        - Teste rápido de debug"
	@echo "  make clean        - Remove arquivos compilados"
	@echo "  make help         - Mostra esta ajuda"
	@echo ""
	@echo "Configuração atual:"
	@echo "  Hostname: $(HOSTNAME)"
	@echo "  NVCC Flags: $(NVCC_FLAGS)"

# Regras especiais (não são arquivos)
.PHONY: all full copy both check-nvcc clean test test-copy test-all debug results help