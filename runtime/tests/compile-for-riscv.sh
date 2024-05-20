#!/bin/sh
basename=`basename $1 | sed 's/[.][^.]*$//'`
# remove previously generated files
sh clean-out.sh $basename

# lower mlir to llvm
mlir-opt $basename/$basename.mlir  --one-shot-bufferize='bufferize-function-boundaries' -test-lower-to-llvm > $basename/out/$basename-in-llvm-dialect.mlir
mlir-translate --mlir-to-llvmir -o $basename/out/$basename.ll $basename/out/$basename-in-llvm-dialect.mlir

# compile llvm to .o file (target riscv)
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