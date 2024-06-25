#!/bin/sh
basename=`basename $1 | sed 's/[.][^.]*$//'`
funcname=$2
# remove previously generated files
sh clean-out.sh $basename

# lower mlir to llvm
mlir-opt $basename/$basename.mlir  --one-shot-bufferize='bufferize-function-boundaries' -test-lower-to-llvm > $basename/out/$basename-in-llvm-dialect.mlir
mlir-translate --mlir-to-llvmir -o $basename/out/$basename-before-o3.ll $basename/out/$basename-in-llvm-dialect.mlir

# optimize llvm with O3 and save result for inspection
opt \
--O3 \
-S \
$basename/out/$basename-before-o3.ll \
> $basename/out/$basename-after-o3.ll

# generate control flow graphs of the optimized and unoptimized llvm for inspection
mkdir -p $basename/out/beforeO3
mkdir -p $basename/out/afterO3
mkdir -p $basename/out/beforeO3-cfg-only
mkdir -p $basename/out/afterO3-cfg-only
here=$(pwd) # save current directory so we can return to it
cd $basename/out/beforeO3
opt ../$basename-before-o3.ll -passes=dot-cfg > /dev/null
cd "$here"
cd $basename/out/beforeO3-cfg-only
opt ../$basename-before-o3.ll -passes=dot-cfg-only > /dev/null
cd "$here"
cd $basename/out/afterO3
opt ../$basename-after-o3.ll -passes=dot-cfg > /dev/null
cd "$here"
cd $basename/out/afterO3-cfg-only
opt ../$basename-after-o3.ll -passes=dot-cfg-only > /dev/null
cd "$here"
# save the CFG graphs for the specified function as svg image files
dot -Tsvg $basename/out/afterO3/.$funcname.dot > $basename/out/$funcname-afterO3.svg
dot -Tsvg $basename/out/beforeO3/.$funcname.dot > $basename/out/$funcname-beforeO3.svg
dot -Tsvg $basename/out/afterO3-cfg-only/.$funcname.dot > $basename/out/$funcname-afterO3-simple.svg
dot -Tsvg $basename/out/beforeO3-cfg-only/.$funcname.dot > $basename/out/$funcname-beforeO3-simple.svg

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
-c $basename/out/$basename-before-o3.ll \
-o $basename/out/$basename.o