nElements=100000   
ntimes=1
usePersistentKernel=0

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <nElements> [<ntimes>]"
    exit 1
elif [ "$#" -eq 1 ]; then
    #echo xx
    nElements=$1
elif [ "$#" -eq 2 ]; then
    #echo ww $nBlocks
    nElements=$1   
    ntimes=$2 
elif [ "$#" -eq 3 ]; then
    #echo ww2
    nElements=$1   
    ntimes=$2 
    nBlocks=$3
    usePersistentKernel=1
fi

   if [ $usePersistentKernel -eq 0 ]; then
     ./vectorAdd   $nElements | tee resultados-nx.txt | grep -e Using -e blocks -e Device 
   else
     ./vectorAdd   $nElements $nBlocks | tee resultados-nx.txt | grep -e Using -e blocks -e Device
   fi
     
for (( i=0; i<ntimes; i+=1 ));
do
   #echo $i
   echo -n nElements=$nElements " "
   if [ $usePersistentKernel -eq 1 ]; then
     ./vectorAdd   $nElements $nBlocks | tee resultados-nx.txt | grep -e "vectorAdd Throughput"
   else
     ./vectorAdd   $nElements | tee resultados-nx.txt | grep -e "vectorAdd Throughput"   
   fi
done


