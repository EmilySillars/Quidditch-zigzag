#!/bin/sh
# Run this script from inside the runtime/tests directory

basename=`basename $1 | sed 's/[.][^.]*$//'`
## compile the mlir kernel
sh compile-for-riscv.sh "$basename" &&\

## compile c code with mlir kernel linked in as object file
cd ../build &&\
cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake &&\
ninja ${basename^} &&\

# run the program
# $SPIKE/spike -l -m0x10000000:0x40000,0x80000000:0x80000000 --disable-dtb -p9 tests/${basename^}
$SPIKE/spike -m0x10000000:0x40000,0x80000000:0x80000000 --disable-dtb -p9 tests/${basename^}

# return to runtime/tests directory
cd ../tests

