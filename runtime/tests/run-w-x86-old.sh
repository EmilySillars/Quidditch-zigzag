#!/bin/sh
# clean out files from previous run
sh clean_out.sh; clear

# echo "MLIR to object file."
basename=`basename $1 | sed 's/[.][^.]*$//'`


mlir-opt $basename.mlir  --one-shot-bufferize='bufferize-function-boundaries' -test-lower-to-llvm > out/$basename-in-llvm-dialect.mlir
# mlir-opt-18 $basename.mlir  --one-shot-bufferize='bufferize-function-boundaries allow-return-allocs \
# function-boundary-type-conversion=identity-layout-map' -test-lower-to-llvm > out/$basename-in-llvm-dialect.mlir

mlir-translate --mlir-to-llvmir -o out/$basename.ll out/$basename-in-llvm-dialect.mlir

# echo "C to object file."
# llc out/$basename.ll -o out/$basename.o -filetype=obj
clang -c out/$basename.ll -o out/$basename.o

# echo "Link together to get an executable."
clang data.c main-no-snrt.c out/$basename.o -o out/main.o

# echo "Run it."
./out/main.o

