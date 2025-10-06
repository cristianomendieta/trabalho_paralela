if [ "$(hostname)" = "orval" ]; then
   echo "Compilacao especial na maquina orval"

   #compilação específica para GTX 750ti (máquina orval)
   #OBS:
   # nesse semestre a orval está com cuda 11.8 
   # nessa versao o nvcc NAO suporta gcc 12 ou g++ 12, 
   #   que é o gcc/g++ atualmente na orval
   # entao, apesar disso, consegui compilar com o gcc 12
   #   forçando o uso do gcc-12 conforme abaixo
   echo nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 vectorAdd.cu -o vectorAdd
   nvcc -arch sm_50 --allow-unsupported-compiler -ccbin /usr/bin/gcc-12 vectorAdd.cu -o vectorAdd

else
   echo compilando para maquina mauina genérica \(`hostname`\)
   #compilação para diversas GPUs
   echo nvcc -O3 vectorAdd.cu -o vectorAdd
   nvcc -O3 vectorAdd.cu -o vectorAdd

   #compilação específica para GTX 1080ti (máquina nv00)
   #echo nvcc -arch sm_61 -o vectorAdd vectorAdd.cu 
   #nvcc -arch sm_61 -o vectorAdd vectorAdd.cu 
fi
