#!/bin/sh
# Helper script for regression-tests.sh
# Run this script from inside the runtime/tests directory

basename=`basename $1 | sed 's/[.][^.]*$//'`

## compile c code with mlir kernel linked in as object file
cd ../build &&\
echo "TESTING $basename ------------------------------------------------------V" >> ../tests/regression-tests.log
rm tests/${basename^} 2> /dev/null
if ! cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake; then
    echo "FAILED $basename: cmake error"
    # return to runtime/tests directory
    cd ../tests
    return
fi
if ! ninja ${basename^}; then
    echo "FAILED $basename: build error"
    # return to runtime/tests directory
    cd ../tests
    return
fi


# run the program
$SPIKE/spike -m0x10000000:0x40000,0x80000000:0x80000000 --disable-dtb -p9 tests/${basename^} > ../tests/out/$basename.txt

# return to runtime/tests directory
cd ../tests

if ! diff ../tests/correct/$basename.txt ../tests/out/$basename.txt 2> /dev/null; then
    echo "FAILED $basename: Output differs:" 
    diff ../tests/correct/$basename.txt ../tests/out/$basename.txt 
   
else
    echo "$basename OK."
fi

