./vectorAdd   100000 | tee resultados-varios.txt | grep -e Using -e blocks -e GPU 
./vectorAdd   100000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd   200000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd   400000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd   800000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"

./vectorAdd  1000000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd  2000000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd  4000000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd  8000000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd 16000000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd 32000000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"
./vectorAdd 64000000 | tee resultados-varios.txt | grep -e requested -e "vectorAdd Throughput"

