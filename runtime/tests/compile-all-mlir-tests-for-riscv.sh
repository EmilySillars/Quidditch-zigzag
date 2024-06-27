#!/bin/sh

tests="holaWorld.mlir \
matmul.mlir \
tiledMatmul.mlir \
tiledMatmul2.mlir \
tiledMatmul3.mlir \
tiledMatmul4.mlir \
tiledMatmul5.mlir \
tiledMatmul6.mlir \
tiledMatmul7.mlir \
tiledMatmul8.mlir \
tiledMatmul9.mlir \
tiledMatmul10.mlir \
tiledMatmul11.mlir \
tiledMatmul12.mlir \
"
for i in $tests
do
   echo "Compiling $i for riscv..."
   sh compile-for-riscv.sh "$i"
done
