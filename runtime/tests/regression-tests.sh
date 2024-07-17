#!/bin/sh

# tiledMatmul7.mlir \
# tiledMatmul8.mlir \
# tiledMatmul9.mlir \

tests="holaWorld.mlir \
matmul.mlir \
tiledMatmul.mlir \
tiledMatmul2.mlir \
tiledMatmul3.mlir \
tiledMatmul4.mlir \
tiledMatmul5.mlir \
tiledMatmul6.mlir \
tiledMatmul10.mlir \
tiledMatmul11.mlir \
tiledMatmul12.mlir \
"

echo "" > regression-tests.log
if [[ $1 == "-t" ]]; then
   echo "Compiling MLIR $2 for riscv..." >> regression-tests.log
   sh compile-for-riscv.sh "$2" 2>> regression-tests.log >> regression-tests.log
   . spike-link-and-run.sh "$2"
elif [[ $1 == "-rb" ]]; then
   for i in $tests
   do
      echo "Compiling MLIR $i for riscv..."
      echo "Compiling MLIR $i for riscv... ------------------------------------------------------V" >> regression-tests.log
      sh compile-for-riscv.sh "$i" 2>> regression-tests.log >> regression-tests.log
   done
   for i in $tests
   do
   . spike-link-and-run.sh "$i"
   done
else
   for i in $tests
   do
   . spike-link-and-run.sh "$i"
   done
fi


