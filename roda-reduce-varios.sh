#!/bin/bash
# Script similar ao roda-varios.sh para testar o cudaReduceMax com diferentes tamanhos
# CI1009 - Programação Paralela com GPUs

echo "=== Testando Kernel Many-threads ==="
./cudaReduceMax 100000 | tee resultados-reduce-varios.txt | grep -e Using -e GPU
./cudaReduceMax 100000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 200000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 400000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 800000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"

./cudaReduceMax 1000000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 2000000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 4000000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 8000000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 16000000 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"

echo ""
echo "=== Testando Kernel Persistente (32 blocos) ==="
./cudaReduceMax 100000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 200000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 400000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 800000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"

./cudaReduceMax 1000000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 2000000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 4000000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 8000000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"
./cudaReduceMax 16000000 32 | tee -a resultados-reduce-varios.txt | grep -e "Number of elements" -e "reduceMax.*Throughput"