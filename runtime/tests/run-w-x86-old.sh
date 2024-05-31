#!/bin/sh
# clean out files from previous run
sh clean_out.sh; clear

# echo "MLIR to object file."
basename=`basename $1 | sed 's/[.][^.]*$//'`


mlir-opt $basename/$basename.mlir  --one-shot-bufferize='bufferize-function-boundaries' -test-lower-to-llvm > $basename/out/$basename-in-llvm-dialect.mlir
# mlir-opt-18 $basename.mlir  --one-shot-bufferize='bufferize-function-boundaries allow-return-allocs \
# function-boundary-type-conversion=identity-layout-map' -test-lower-to-llvm > out/$basename-in-llvm-dialect.mlir

mlir-translate --mlir-to-llvmir -o $basename/out/$basename.ll $basename/out/$basename-in-llvm-dialect.mlir

# echo "C to object file."
# llc out/$basename.ll -o out/$basename.o -filetype=obj
clang -c $basename/out/$basename.ll -o $basename/out/$basename.o

# echo "Link together to get an executable."
clang lib-zigzag/data.c $basename/main-no-snrt.c $basename/out/$basename.o -o $basename/out/main.o

# echo "Run it."
./$basename/out/main.o

