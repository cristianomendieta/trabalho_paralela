# Makefile para o projeto CUDA Reduce Max
# CI1009 - Programação Paralela com GPUs
# UFPR - 2025

TARGET = cudaReduceMax
SOURCE = cudaReduceMax.cu

# Regra principal
all: $(TARGET)

$(TARGET): $(SOURCE)
	@if [ "$$(hostname)" = "orval" ]; then \
		echo "Compilacao especial na maquina orval (GTX 750ti)"; \
		echo "nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -lstdc++ $(SOURCE) -o $(TARGET)"; \
		nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -lstdc++ $(SOURCE) -o $(TARGET); \
	else \
		echo "Compilando para maquina generica ($$(hostname))"; \
		echo "nvcc -O3 -lstdc++ $(SOURCE) -o $(TARGET)"; \
		nvcc -O3 -lstdc++ $(SOURCE) -o $(TARGET); \
	fi

# Limpar arquivos compilados
clean:
	rm -f $(TARGET)

# Executar testes
test: $(TARGET)
	@echo "Executando teste com 1M elementos..."
	./$(TARGET) 1000000 30
	@echo ""
	@echo "Executando teste com 16M elementos..."
	./$(TARGET) 16000000 30

# Teste rápido para debug
debug: $(TARGET)
	./$(TARGET) 1000 5

# Regras especiais
.PHONY: all clean test debug