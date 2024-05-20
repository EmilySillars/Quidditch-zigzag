#!/bin/sh
# Run this script from inside the runtime/tests directory

basename=`basename $1 | sed 's/[.][^.]*$//'`
echo "$basename"
echo "${basename^}"

## compile the mlir kernel
sh compile-for-riscv.sh "$basename"

## compile c code with mlir kernel linked in as object file
cd ../build
cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake
ninja ${basename^}

# run the program
../../toolchain/bin/snitch_cluster.vlt tests/${basename^}

# return to runtime/tests directory
cd tests