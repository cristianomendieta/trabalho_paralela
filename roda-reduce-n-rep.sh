#!/bin/bash
# Script similar ao roda-n-rep.sh para testar o cudaReduceMax
# CI1009 - Programação Paralela com GPUs

nElements=1000000   
ntimes=5
usePersistentKernel=0

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <nElements> [<ntimes>] [<nBlocks>]"
    exit 1
elif [ "$#" -eq 1 ]; then
    nElements=$1
elif [ "$#" -eq 2 ]; then
    nElements=$1   
    ntimes=$2 
elif [ "$#" -eq 3 ]; then
    nElements=$1   
    ntimes=$2 
    nBlocks=$3
    usePersistentKernel=1
fi

if [ $usePersistentKernel -eq 0 ]; then
    ./cudaReduceMax $nElements | tee resultados-reduce-nx.txt | grep -e Using -e GPU -e "reduceMax.*Throughput"
else
    ./cudaReduceMax $nElements $nBlocks | tee resultados-reduce-nx.txt | grep -e Using -e GPU -e "reduceMax.*Throughput"
fi
     
for (( i=0; i<ntimes; i+=1 ));
do
   echo -n "nElements=$nElements "
   if [ $usePersistentKernel -eq 1 ]; then
     ./cudaReduceMax $nElements $nBlocks | tee -a resultados-reduce-nx.txt | grep -e "reduceMax.*Throughput"
   else
     ./cudaReduceMax $nElements | tee -a resultados-reduce-nx.txt | grep -e "reduceMax.*Throughput"   
   fi
done