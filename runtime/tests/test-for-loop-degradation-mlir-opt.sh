#!/bin/sh
basename=`basename $1 | sed 's/[.][^.]*$//'`
funcname=$2
# remove previously generated files
sh clean-out.sh $basename

# generate optimized and un-optimized versions of 
# 1) linalg/scf dialect, and then 2) LLVM dialect
mkdir -p $basename/out/mlir-linalg-scf
mkdir -p $basename/out/mlir-llvm

# llvm dialect (original version)
mlir-opt $basename/$basename.mlir  \
 --one-shot-bufferize='bufferize-function-boundaries' \
 -test-lower-to-llvm > $basename/out/mlir-llvm/$basename-in-llvm-dialect.mlir

# optimized llvm dialect version
# WHAT FLAGS SHOULD I PASS INSTEAD OF -O3?
#-loop-invariant-code-motion ?
#-loop-invariant-subset-hoisting ?
# -cse ?
mlir-opt $basename/$basename.mlir \
 --one-shot-bufferize='bufferize-function-boundaries' \
 -test-lower-to-llvm > $basename/out/mlir-llvm/$basename-in-llvm-dialect-after-o3.mlir

# scf/linalg (original version)
cp $basename/$basename.mlir $basename/out/mlir-linalg-scf/$basename.mlir

# optimized linalg/scf version
# WHAT FLAGS SHOULD I PASS INSTEAD OF -O3?
#-loop-invariant-code-motion ?
#-loop-invariant-subset-hoisting ?
# -cse ?
mlir-opt $basename/$basename.mlir \
 --one-shot-bufferize='bufferize-function-boundaries' \
 > $basename/out/mlir-linalg-scf/$basename-after-o3.mlir
