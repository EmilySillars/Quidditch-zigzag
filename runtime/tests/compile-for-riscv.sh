#!/bin/sh
basename=`basename $1 | sed 's/[.][^.]*$//'`
echo "compile-for-riscv: basename is $basename"
# remove previously generated files
sh clean-out.sh $basename

# make an output directory if doesn't already exist
mkdir -p $basename/out

# lower mlir to llvm
echo "START: mlir-opt --one-shot-bufferize"
mlir-opt $basename/$basename.mlir --one-shot-bufferize='bufferize-function-boundaries' > $basename/out/$basename-bufferized.mlir
echo "FINISHED: mlir-opt --one-shot-bufferize"

# echo "START: mlir-opt -test-lower-to-llvm"
# mlir-opt $basename/out/$basename-bufferized.mlir \
# --test-lower-to-llvm > $basename/out/$basename-in-llvm-dialect.mlir
# echo "FINISHED: mlir-opt -test-lower-to-llvm"

echo "START: mlir-opt pass by pass"
mlir-opt $basename/out/$basename-bufferized.mlir \
--convert-vector-to-scf \
> $basename/out/$basename-lowered1.mlir

mlir-opt $basename/out/$basename-lowered1.mlir \
--convert-linalg-to-loops \
> $basename/out/$basename-lowered2.mlir

mlir-opt $basename/out/$basename-lowered2.mlir \
--lower-affine \
> $basename/out/$basename-lowered3.mlir

mlir-opt $basename/out/$basename-lowered3.mlir \
--convert-scf-to-cf \
> $basename/out/$basename-lowered4.mlir

mlir-opt $basename/out/$basename-lowered4.mlir \
--canonicalize \
> $basename/out/$basename-lowered5.mlir

mlir-opt $basename/out/$basename-lowered5.mlir \
--cse \
> $basename/out/$basename-lowered6.mlir

mlir-opt $basename/out/$basename-lowered6.mlir \
--convert-vector-to-llvm='reassociate-fp-reductions' \
> $basename/out/$basename-lowered7.mlir

mlir-opt $basename/out/$basename-lowered7.mlir \
--convert-math-to-llvm \
> $basename/out/$basename-lowered8.mlir

mlir-opt $basename/out/$basename-lowered8.mlir \
--expand-strided-metadata \
> $basename/out/$basename-lowered9.mlir

mlir-opt $basename/out/$basename-lowered9.mlir \
--lower-affine \
> $basename/out/$basename-lowered10.mlir

# fix numbering after this point
mlir-opt $basename/out/$basename-lowered10.mlir \
--finalize-memref-to-llvm='use-generic-functions index-bitwidth=32' \
> $basename/out/$basename-lowered11.mlir

mlir-opt $basename/out/$basename-lowered11.mlir \
--convert-func-to-llvm='index-bitwidth=32' \
> $basename/out/$basename-lowered12.mlir

mlir-opt $basename/out/$basename-lowered12.mlir \
--convert-index-to-llvm=index-bitwidth=32 \
> $basename/out/$basename-lowered13.mlir

mlir-opt $basename/out/$basename-lowered13.mlir \
--reconcile-unrealized-casts \
> $basename/out/$basename-lowered14.mlir

cat $basename/out/$basename-lowered14.mlir > $basename/out/$basename-in-llvm-dialect.mlir
echo "FINISHED: mlir-opt pass by pass"


echo "START: mlir-translate --mlir-to-llvmir"
mlir-translate --mlir-to-llvmir -o $basename/out/$basename.ll $basename/out/$basename-in-llvm-dialect.mlir
echo "FINISHED: mlir-translate --mlir-to-llvmir"

# compile llvm to .o file (target riscv)
echo "START: clang (llvm to .o)"
clang \
-Wno-unused-command-line-argument \
-D__DEFINED_uint64_t \
--target=riscv32-unknown-elf \
-mcpu=generic-rv32 \
-march=rv32imafdzfh \
-mabi=ilp32d \
-mcmodel=medany \
-ftls-model=local-exec \
-ffast-math \
-fno-builtin-printf \
-fno-common \
-O3 \
-std=gnu11 \
-Wall \
-Wextra \
-x ir \
-c $basename/out/$basename.ll \
-o $basename/out/$basename.o
echo "FINISHED: clang (llvm to .o)"



# ))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))
# mlir-opt $basename/out/$basename-lowered#.mlir \
#  \
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir
# > $basename/out/$basename-lowered#.mlir

# --canonicalize \
# --cse --convert-math-to-llvm --llvm-request-c-wrappers --expand-strided-metadata \
# --convert-index-to-llvm=index-bitwidth=32 --convert-cf-to-llvm=index-bitwidth=32 \
# --convert-arith-to-llvm=index-bitwidth=32 --convert-func-to-llvm='index-bitwidth=32' \
# --finalize-memref-to-llvm='use-generic-functions index-bitwidth=32' --canonicalize \
# --reconcile-unrealized-casts > $basename/out/$basename-in-llvm-dialect.mlir
# ))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))