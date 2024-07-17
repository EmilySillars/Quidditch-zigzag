#!/bin/sh
# Helper script for regression-tests.sh
# Run this script from inside the runtime/tests directory

basename=`basename $1 | sed 's/[.][^.]*$//'`

## compile c code with mlir kernel linked in as object file
cd ../build &&\
echo "TESTING $basename ------------------------------------------------------V" >> ../tests/regression-tests.log
cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake >> ../tests/regression-tests.log
ninja ${basename^} >> ../tests/regression-tests.log

# run the program
$SPIKE/spike -m0x10000000:0x40000,0x80000000:0x80000000 --disable-dtb -p9 tests/${basename^} > ../tests/out/$basename.txt

# return to runtime/tests directory
cd ../tests

# compare results with ground truth
comparisonResult=$(diff ../tests/correct/$basename.txt ../tests/out/$basename.txt)
if [[ $comparisonResult ]]; then
echo "FAILED $basename"
    echo "FAILED $basename: Output differs:" >> regression-tests.log
    diff ../tests/correct/$basename.txt ../tests/out/$basename.txt >> regression-tests.log
else
    echo "$basename OK." >> regression-tests.log
    echo "$basename OK."
fi

# scripting notes/reference
# files=$(ls -A)
# if [[ $? != 0 ]]; then
#     echo "Command failed."
# elif [[ $files ]]; then
#     echo "Files found."
# else
#     echo "No files found."
# fi

