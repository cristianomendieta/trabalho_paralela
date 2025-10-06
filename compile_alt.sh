#!/bin/bash
# Script de compilação alternativo para o projeto CUDA Reduce Max
# Versão com múltiplas tentativas para resolver problemas de linkagem
# CI1009 - Programação Paralela com GPUs
# UFPR - 2025

echo "=== Compilando CUDA Reduce Max (Versão Alternativa) ==="

# Verificar se o NVCC está disponível
if ! command -v nvcc &> /dev/null; then
    echo "Erro: NVCC não encontrado. Certifique-se de que o CUDA está instalado."
    exit 1
fi

# Função para testar compilação
try_compile() {
    local cmd="$1"
    local desc="$2"
    
    echo "Tentativa: $desc"
    echo "Comando: $cmd"
    
    if eval $cmd; then
        echo "✓ Compilação bem-sucedida com: $desc"
        return 0
    else
        echo "✗ Falhou: $desc"
        return 1
    fi
}

# Compilação específica por máquina
if [ "$(hostname)" = "orval" ]; then
    echo "Compilacao especial na maquina orval (GTX 750ti)"
    
    # Tentativa 1: Com -lstdc++ e flags básicas
    if try_compile "nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -lstdc++ cudaReduceMax.cu -o cudaReduceMax" "Flags básicas + lstdc++"; then
        exit 0
    fi
    
    # Tentativa 2: Com mais flags de linkagem
    if try_compile "nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -lstdc++ -lcudart -lm cudaReduceMax.cu -o cudaReduceMax" "Com bibliotecas extras"; then
        exit 0
    fi
    
    # Tentativa 3: Forçar C++11 e runtime dinâmico
    if try_compile "nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -std=c++11 -lstdc++ -lcudart_static -ldl -lrt -pthread cudaReduceMax.cu -o cudaReduceMax" "C++11 + runtime estático"; then
        exit 0
    fi
    
    # Tentativa 4: Separar compilação
    echo "Tentativa: Compilação separada"
    if nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 -c cudaReduceMax.cu -o cudaReduceMax.o && \
       g++-12 cudaReduceMax.o -lcuda -lcudart -lstdc++ -o cudaReduceMax; then
        echo "✓ Compilação bem-sucedida com compilação separada"
        exit 0
    fi
    
else
    echo "Compilando para maquina generica ($(hostname))"
    
    # Tentativa 1: Básica com lstdc++
    if try_compile "nvcc -O3 -lstdc++ cudaReduceMax.cu -o cudaReduceMax" "Otimização + lstdc++"; then
        exit 0
    fi
    
    # Tentativa 2: Com mais bibliotecas
    if try_compile "nvcc -O3 -lstdc++ -lcudart -lm cudaReduceMax.cu -o cudaReduceMax" "Com bibliotecas extras"; then
        exit 0
    fi
    
    # Tentativa 3: C++11 explícito
    if try_compile "nvcc -O3 -std=c++11 -lstdc++ -lcudart_static -ldl -lrt -pthread cudaReduceMax.cu -o cudaReduceMax" "C++11 + runtime estático"; then
        exit 0
    fi
fi

echo ""
echo "❌ Todas as tentativas de compilação falharam!"
echo "Verifique se todas as dependências estão instaladas:"
echo "  - CUDA Toolkit completo"
echo "  - g++ compatível" 
echo "  - Thrust library"
exit 1