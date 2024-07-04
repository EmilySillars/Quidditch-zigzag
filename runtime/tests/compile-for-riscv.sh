#!/bin/sh
basename=`basename $1 | sed 's/[.][^.]*$//'`
# remove previously generated files
sh clean-out.sh $basename

# make an output directory if doesn't already exist
mkdir -p $basename/out

# lower mlir to llvm
echo "START: mlir-opt --one-shot-bufferize"
mlir-opt $basename/$basename.mlir  --one-shot-bufferize='bufferize-function-boundaries' > $basename/out/$basename-bufferized.mlir
echo "FINISHED: mlir-opt --one-shot-bufferize"

echo "START: mlir-opt -test-lower-to-llvm"
mlir-opt $basename/out/$basename-bufferized.mlir \
--test-lower-to-llvm \
--expand-strided-metadata \
--finalize-memref-to-llvm \
--memref-expand \
--reconcile-unrealized-casts \
--test-lower-to-llvm > $basename/out/$basename-in-llvm-dialect.mlir
echo "FINISHED: mlir-opt -test-lower-to-llvm"

# echo "START: mlir-opt pass by pass"
# mlir-opt $basename/out/$basename-bufferized.mlir \
# --convert-linalg-to-loops \
# > $basename/out/$basename-lowered1.mlir

# mlir-opt $basename/out/$basename-lowered1.mlir \
# --convert-scf-to-cf \
# > $basename/out/$basename-lowered2.mlir

# mlir-opt $basename/out/$basename-lowered2.mlir \
# --lower-affine \
# > $basename/out/$basename-lowered3.mlir

# mlir-opt $basename/out/$basename-lowered3.mlir \
# --canonicalize \
# > $basename/out/$basename-lowered4.mlir

# mlir-opt $basename/out/$basename-lowered4.mlir \
# --cse \
# > $basename/out/$basename-lowered5.mlir

# mlir-opt $basename/out/$basename-lowered5.mlir \
# --convert-math-to-llvm \
# > $basename/out/$basename-lowered6.mlir

# mlir-opt $basename/out/$basename-lowered6.mlir \
# --llvm-request-c-wrappers \
# > $basename/out/$basename-lowered7.mlir

# mlir-opt $basename/out/$basename-lowered7.mlir \
# --expand-strided-metadata \
# > $basename/out/$basename-lowered8.mlir

# # made a typo and went from 8 to 10, skipping 9 (whoops!)
# mlir-opt $basename/out/$basename-lowered8.mlir \
# --convert-index-to-llvm=index-bitwidth=32 \
# > $basename/out/$basename-lowered10.mlir

# mlir-opt $basename/out/$basename-lowered10.mlir \
# --convert-cf-to-llvm=index-bitwidth=32 \
# > $basename/out/$basename-lowered11.mlir

# mlir-opt $basename/out/$basename-lowered11.mlir \
# --convert-arith-to-llvm=index-bitwidth=32 \
# > $basename/out/$basename-lowered12.mlir

# mlir-opt $basename/out/$basename-lowered12.mlir \
# --convert-func-to-llvm='index-bitwidth=32' \
# > $basename/out/$basename-lowered13.mlir

# # lowering 13 to 14 is where memrefCopy gets introduced, along with "llvm.intr.memcpy"
# mlir-opt $basename/out/$basename-lowered13.mlir \
# --finalize-memref-to-llvm='use-generic-functions index-bitwidth=32' \
# > $basename/out/$basename-lowered14.mlir
# # mlir-opt $basename/out/$basename-lowered13.mlir \
# # --finalize-memref-to-llvm='use-generic-functions index-bitwidth=32' \
# # > $basename/out/$basename-lowered14.mlir

# mlir-opt $basename/out/$basename-lowered14.mlir \
# --canonicalize \
# > $basename/out/$basename-lowered15.mlir

# mlir-opt $basename/out/$basename-lowered15.mlir \
# --reconcile-unrealized-casts \
# > $basename/out/$basename-lowered16.mlir

# cat $basename/out/$basename-lowered16.mlir > $basename/out/$basename-in-llvm-dialect.mlir
# echo "FINISHED: mlir-opt pass by pass"


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