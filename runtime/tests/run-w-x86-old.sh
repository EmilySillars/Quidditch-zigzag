#!/bin/sh
# clean out files from previous run
sh clean_out.sh; clear

# echo "MLIR to object file."
basename=`basename $1 | sed 's/[.][^.]*$//'`


mlir-opt $basename/$basename.mlir  --one-shot-bufferize='bufferize-function-boundaries' -test-lower-to-llvm > $basename/out/$basename-in-llvm-dialect.mlir
# mlir-opt-18 $basename.mlir  --one-shot-bufferize='bufferize-function-boundaries allow-return-allocs \
# function-boundary-type-conversion=identity-layout-map' -test-lower-to-llvm > out/$basename-in-llvm-dialect.mlir

mlir-translate --mlir-to-llvmir -o $basename/out/$basename.ll $basename/out/$basename-in-llvm-dialect.mlir


# or try adding THESE!
# -Wno-unused-command-line-argument \
# -D__DEFINED_uint64_t \
# --target=riscv32-unknown-elf \
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
# -x ir \
clang \
-Wno-unused-command-line-argument \
-D__DEFINED_uint64_t \
--target=x86_64-unknown-linux-gnu \
-ftls-model=local-exec \
-ffast-math \
-fno-builtin-printf \
-fno-common \
-O3 \
-std=gnu11 \
-Wall \
-Wextra \
-x ir \
-c \
$basename/out/$basename.ll -o $basename/out/$basename.o

clang \
-Wno-unused-command-line-argument \
-D__DEFINED_uint64_t \
--target=x86_64-unknown-linux-gnu \
-ftls-model=local-exec \
-ffast-math \
-fno-builtin-printf \
-fno-common \
-O3 \
-std=gnu11 \
-Wall \
-Wextra \
lib-zigzag/data.c $basename/main-no-snrt.c $basename/out/$basename.o -o $basename/out/main.o

# try adding in these flags to get the program to run!!
# /usr/bin/clang-17 -I/opt/snax-gemm/target/snitch_cluster/sw/snax/gemm/include -Wno-unused-command-line-argument -I/opt/snax-gemm/target/snitch_cluster/sw/runtime/rtl-generic/src -I/opt/snax-gemm/target/snitch_cluster/sw/runtime/common -I/opt/snax-gemm/sw/snRuntime/api -I/opt/snax-gemm/sw/snRuntime/src -I/opt/snax-gemm/sw/snRuntime/src/omp/ -I/opt/snax-gemm/sw/snRuntime/api/omp/ -I/opt/snax-gemm/sw/math/arch/riscv64/bits/ -I/opt/snax-gemm/sw/math/arch/generic -I/opt/snax-gemm/sw/math/src/include -I/opt/snax-gemm/sw/math/src/internal -I/opt/snax-gemm/sw/math/include/bits -I/opt/snax-gemm/sw/math/include -I/repo/runtime/include -D__DEFINED_uint64_t --target=riscv32-unknown-elf -mcpu=generic-rv32 -march=rv32imafdzfh -mabi=ilp32d -mcmodel=medany -ftls-model=local-exec -ffast-math -fno-builtin-printf -fno-common -O3 -std=gnu11 -Wall -Wextra -x ir -c out/$basename.ll12 -o $basename.o
# /usr/bin/clang-17 -I/opt/snax-gemm/target/snitch_cluster/sw/snax/gemm/include -Wno-unused-command-line-argument -I/opt/snax-gemm/target/snitch_cluster/sw/runtime/rtl-generic/src -I/opt/snax-gemm/target/snitch_cluster/sw/runtime/common -I/opt/snax-gemm/sw/snRuntime/api -I/opt/snax-gemm/sw/snRuntime/src -I/opt/snax-gemm/sw/snRuntime/src/omp/ -I/opt/snax-gemm/sw/snRuntime/api/omp/ -I/opt/snax-gemm/sw/math/arch/riscv64/bits/ -I/opt/snax-gemm/sw/math/arch/generic -I/opt/snax-gemm/sw/math/src/include -I/opt/snax-gemm/sw/math/src/internal -I/opt/snax-gemm/sw/math/include/bits -I/opt/snax-gemm/sw/math/include -I/repo/runtime/include -D__DEFINED_uint64_t --target=riscv32-unknown-elf -mcpu=generic-rv32 -march=rv32imafdzfh -mabi=ilp32d -mcmodel=medany -ftls-model=local-exec -ffast-math -fno-builtin-printf -fno-common -O3 -std=gnu11 -Wall -Wextra -c main.c -o main.o
# /usr/bin/clang-17 -I/opt/snax-gemm/target/snitch_cluster/sw/snax/gemm/include -Wno-unused-command-line-argument -I/opt/snax-gemm/target/snitch_cluster/sw/runtime/rtl-generic/src -I/opt/snax-gemm/target/snitch_cluster/sw/runtime/common -I/opt/snax-gemm/sw/snRuntime/api -I/opt/snax-gemm/sw/snRuntime/src -I/opt/snax-gemm/sw/snRuntime/src/omp/ -I/opt/snax-gemm/sw/snRuntime/api/omp/ -I/opt/snax-gemm/sw/math/arch/riscv64/bits/ -I/opt/snax-gemm/sw/math/arch/generic -I/opt/snax-gemm/sw/math/src/include -I/opt/snax-gemm/sw/math/src/internal -I/opt/snax-gemm/sw/math/include/bits -I/opt/snax-gemm/sw/math/include -I/repo/runtime/include -D__DEFINED_uint64_t --target=riscv32-unknown-elf -mcpu=generic-rv32 -march=rv32imafdzfh -mabi=ilp32d -mcmodel=medany -ftls-model=local-exec -ffast-math -fno-builtin-printf -fno-common -O3 -std=gnu11 -Wall -Wextra -c data.c -o data.o
# /usr/bin/clang-17 /opt/snax-gemm/target/snitch_cluster/sw/snax/gemm/build/snax-gemm-lib.o -fuse-ld=/usr/bin/ld.lld-17 -L/opt/snitch-llvm/lib/clang/12.0.1/lib/ -L/opt/snitch-llvm/riscv32-unknown-elf/lib/ --target=riscv32-unknown-elf -mcpu=generic-rv32 -march=rv32imafdzfh -mabi=ilp32d -mcmodel=medany -T/opt/snax-gemm/sw/snRuntime/base.ld -L/opt/snax-gemm/target/snitch_cluster/sw/runtime/rtl-generic -L/opt/snax-gemm/target/snitch_cluster/sw/runtime/rtl-generic/build -nostdlib -lclang_rt.builtins-riscv32 -lc -lsnRuntime $basename.o main.o data.o -o $basename.x
# rm -fr ./logs

# clang -Wno-unused-command-line-argument -D__DEFINED_uint64_t --target=riscv32-unknown-elf \
# -mcpu=generic-rv32 -march=rv32imafdzfh -mabi=ilp32d -mcmodel=medany -ftls-model=local-exec \
# -ffast-math -fno-builtin-printf -fno-common -O3 -std=gnu11 -Wall -Wextra -x ir -c \
# $basename/out/$basename.ll -o $basename/out/$basename.o
# #/opt/snax-gemm/target/snitch_cluster/sw/snax/gemm/build/snax-gemm-lib.o -fuse-ld=/usr/bin/ld.lld-17 -L/opt/snitch-llvm/lib/clang/12.0.1/lib/ -L/opt/snitch-llvm/riscv32-unknown-elf/lib/ --target=riscv32-unknown-elf -mcpu=generic-rv32 -march=rv32imafdzfh -mabi=ilp32d -mcmodel=medany -T/opt/snax-gemm/sw/snRuntime/base.ld -L/opt/snax-gemm/target/snitch_cluster/sw/runtime/rtl-generic -L/opt/snax-gemm/target/snitch_cluster/sw/runtime/rtl-generic/build -nostdlib -lclang_rt.builtins-riscv32 -lc -lsnRuntime

# # echo "Link together to get an executable."
# clang -Wno-unused-command-line-argument -D__DEFINED_uint64_t --target=riscv32-unknown-elf \
# -mcpu=generic-rv32 -march=rv32imafdzfh -mabi=ilp32d -mcmodel=medany -ftls-model=local-exec \
# -ffast-math -fno-builtin-printf -fno-common -O3 -std=gnu11 -Wall -Wextra \
# -nostdlib -lclang_rt.builtins-riscv32 \
# lib-zigzag/data.c $basename/main-no-snrt.c $basename/out/$basename.o -o $basename/out/main.o

#-nostdlib -lclang_rt.builtins-riscv32 -lc -lsnRuntime

# old and good v
# echo "C to object file."
# llc out/$basename.ll -o out/$basename.o -filetype=obj
# clang -c $basename/out/$basename.ll -o $basename/out/$basename.o

# # echo "Link together to get an executable."
# clang lib-zigzag/data.c $basename/main-no-snrt.c $basename/out/$basename.o -o $basename/out/main.o


# old and good ^


# echo "Run it."
./$basename/out/main.o

