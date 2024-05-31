#!/bin/sh
# Run this script from inside the runtime/tests directory

basename=`basename $1 | sed 's/[.][^.]*$//'`
funcname=$2

## compile the mlir kernel and save two versions, optimized and unoptimized
sh test-for-loop-degradation.sh "$basename" "$funcname"&&\

## compile c code with mlir kernel linked in as object file
cd ../build &&\
cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake &&\
ninja ${basename^} &&\

# return to runtime/tests directory
cd tests
