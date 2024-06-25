#!/bin/sh
# Run this script from inside the runtime/tests directory

basename=`basename $1 | sed 's/[.][^.]*$//'`
funcname=$2

## CLANG O3: lower the mlir kernel from scf/linalg to llvm dialect, saving optimized and unoptimized versions
sh test-for-loop-degradation-mlir-opt.sh "$basename" "$funcname"&&\

## LLVM O3: compile the mlir kernel and save two versions, optimized and unoptimized
sh test-for-loop-degradation-clang.sh "$basename" "$funcname"&&\

## compile c code with mlir kernel linked in as object file
cd ../build &&\
cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake &&\
ninja ${basename^} &&\

# return to runtime/tests directory
cd tests
