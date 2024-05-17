#!/bin/sh
# echo "MLIR to object file."
basename=`basename $1 | sed 's/[.][^.]*$//'`
mlir-opt $basename.mlir  --one-shot-bufferize='bufferize-function-boundaries' -test-lower-to-llvm > out/$basename-in-llvm-dialect.mlir
mlir-translate --mlir-to-llvmir -o out/$basename.ll out/$basename-in-llvm-dialect.mlir


# llc out/$basename.ll -o out/$basename.o -filetype=obj
#clang -c out/$basename.ll -o out/$basename.o
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
-c out/$basename.ll \
-o out/$basename.o

# clang \
# -fuse-ld=/usr/bin/ld.lld \
# -Wno-unused-command-line-argument \
# -D__DEFINED_uint64_t \
# --target=riscv32-unknown-linux \
# -mcpu=generic-rv32 \
# -march=rv32imafdzfh \
# -mabi=ilp32d \
# -mcmodel=medany \
# -ftls-model=local-exec \
# -ffast-math \
# -fno-builtin-printf \
# -fno-common \
# -O3 \
# -std=gnu11 \
# -Wall \
# -Wextra \
# data.c main.c out/$basename.o -o out/main.o

#--sysroot="/home/hoppip/riscv-gnu-toolchain" \
#-I/home/hoppip/riscv-gnu-toolchain \
# -I/home/hoppip/llvm-project-pistachio/build-riscv/lib/clang/18/include \
# -I/usr/include \


# echo "Link together to get an executable."
# clang data.c main.c out/$basename.o -o out/main.o

# echo "Run it."
#./out/main.o


#/usr/bin/clang-17 
# -I/opt/snax-gemm/target/snitch_cluster/sw/snax/gemm/include 
# -Wno-unused-command-line-argument 
# -I/opt/snax-gemm/target/snitch_cluster/sw/runtime/rtl-generic/src 
# -I/opt/snax-gemm/target/snitch_cluster/sw/runtime/common 
# -I/opt/snax-gemm/sw/snRuntime/api 
# -I/opt/snax-gemm/sw/snRuntime/src 
# -I/opt/snax-gemm/sw/snRuntime/src/omp/ 
# -I/opt/snax-gemm/sw/snRuntime/api/omp/ 
# -I/opt/snax-gemm/sw/math/arch/riscv64/bits/ 
# -I/opt/snax-gemm/sw/math/arch/generic 
# -I/opt/snax-gemm/sw/math/src/include 
# -I/opt/snax-gemm/sw/math/src/internal 
# -I/opt/snax-gemm/sw/math/include/bits 
# -I/opt/snax-gemm/sw/math/include 
# -I/repo/runtime/include 
# -D__DEFINED_uint64_t 
# --target=riscv32-unknown-elf 
# -mcpu=generic-rv32 
# -march=rv32imafdzfh 
# -mabi=ilp32d 
# -mcmodel=medany 
# -ftls-model=local-exec 
# -ffast-math 
# -fno-builtin-printf 
# -fno-common 
# -O3 
# -std=gnu11 
# -Wall 
# -Wextra 
# -x ir 
# -c out/$basename.ll
# -o out/$basename.o

