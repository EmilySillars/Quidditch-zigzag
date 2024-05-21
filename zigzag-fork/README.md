# ZigZag Manual Transformations

Run and Test examples with *Verilator and Spike Simulating Snitch*.

Before doing anything,

- remember to add your MLIR LLVM build to your install path, for example:
  ```
  export PATH=/home/hoppip/llvm-project-pistachio/build-riscv/bin:$PATH # or
  export PATH=/home/hoppip/llvm-project-17/build-riscv/bin:$PATH
  ```

- remember to set the RISCV environment variable to your risc-v toolchain install path, for example:
  ```
  export PATH="/home/hoppip/riscv/bin:$PATH"
  ```

- remember to set the SPIKE environment variable to your spike riscv-isa-sim build directory, for example:
  ```
  export SPIKE="/home/hoppip/riscv-isa-sim/build"
  export SPIKE="/home/hoppip/riscv-32/bin" # not this
  export SPIKE="/home/hoppip/riscv-isa-sim"
  ```

  

## Current Status

- Hola World (which calls a C function from MLIR) runs with snitch verliator and non-snitch x86 cpu
- Regular Matmul and Tiled Matmul both run with snitch verilator but  **segfault** on non-snitch x86 cpu

  Best guess of cause: my lowering of MLIR to llvm is not adequate
  - My lowering script: [compile-for-riscv.sh](../runtime/tests/compile-for-riscv.sh)
  - Snax-MLIR's lowering script: [run_simple_matmul.sh](https://github.com/EmilySillars/snax-mlir-zigzag/blob/zigzag-to-snax/kernels/simple_matmul2/call-c-from-mlir/run_simple_matmul.sh)

## Build + Run MLIR DNN Kernels

### 1. with Verilator Simulating Snitch (cycle accurate)

1) navigate to the tests directory: `cd runtime/tests`

2) run the following script with the name of the kernel's mlir source file; for example, `holaWorld.mlir`
   ```
   sh zigzAG-build-and-run.sh holaWorld.mlir
   ```

#### Examples

- HolaWorld: [MLIR](../runtime/tests/hola-world/matmul-tiled.mlir) calling [C code](../runtime/tests/hola-world/main.c)

  ```
  sh zigzag-verilator-build-and-run.sh holaWorld.mlir
  ```

- Matmul
  ```
  sh zigzag-verilator-build-and-run.sh matmul.mlir
  ```
- Tiled Matmul (but runs slow)
  ```
  sh zigzag-verilator-build-and-run.sh tiledMatmul.mlir
  ```

### 2. with Spike Simulating Snitch (faster)

1. navigate to the tests directory: `cd runtime/tests`

2. run the following script with the name of the kernel's mlir source file; for example, `holaWorld.mlir`
   ```
   sh zigzag-spike-build-and-run.sh holaWorld.mlir
   ```

### 3. on x86 CPU (Reality Check) (segfaults! need to debug!)

Before starting, make sure to add your MLIR LLVM build to your path. For example,

```
export PATH=/home/hoppip/llvm-project-pistachio/build-riscv/bin:$PATH # for regulr  mlir-opt
export PATH=/home/hoppip/llvm-project-17/build-riscv/bin:$PATH
```

- [MLIR](../runtime/tests/hola-world/matmul-tiled.mlir) calling [C code](../runtime/tests/hola-world/main-no-snrt.c)
  

from inside `runtime/tests/hola-world` directory,

  ```
  sh ../run-w-x86.sh matmul-tiled.mlir
  ```

- Regular Matmul ***(not working! need to fix!)***
  

from inside `runtime/tests/matmul` directory,

  ```
  sh ../run-w-x86.sh matmul.mlir
  ```

- Tiled Matmul (2x16 and 16x2 shaped tiles)  ***(not working! need to fix!)***

 from inside `runtime/tests/tiled-matmul-2x16` directory,
  ```
  sh ../run-w-x86.sh matmul-tiled.mlir
  ```

## Setup

### 1. Set up the Quidditch repo

1. Clone the repo with `--recursive` option: 

   ```
   git clone --recursive https://github.com/EmilySillars/Quidditch-zigzag.git
   ```

2. ````
   cd Quidditch-zigzag
   mkdir ./toolchain
   ````

3. ```
   sudo chmod 666 /var/run/docker.sock
   docker run --rm ghcr.io/opencompl/quidditch/toolchain:main tar -cC /opt/quidditch-toolchain . | tar -xC ./toolchain
   ```

4. Install python requirements:
   ```
   python -m pip install -r runtime/requirements.txt
   ```

5. Install blender: 
   ```
   cargo install bender
   ```

6. ```
   cd runtime && mkdir build
   ```

### 2. Set up Spike

1. [clone the repo](https://github.com/opencompl/riscv-isa-sim/tree/CSR-Barrier):

   ```
   git clone https://github.com/opencompl/riscv-isa-sim.git
   ```

2. ```
   $ apt-get install device-tree-compiler libboost-regex-dev
   $ cd riscv-isa-sim
   $ mkdir build
   $ cd build
   $ ../configure --prefix=/home/hoppip/riscv-isa-sim/build
   $ make
   $ [sudo] make install
   ```

Instead of the above instructions, I ran:

```
$ apt-get install device-tree-compiler libboost-regex-dev
$ cd riscv-isa-sim
$ mkdir build
$ cd build
$ ../configure --with-target=riscv32-unknown-elf --with-isa=RV32IMAFD --prefix=/home/hoppip/riscv-isa-sim/build
$ make
$ make install
```



3. Set the SPIKE environment variable to the location of your build directory:

   ```
   export SPIKE=/home/hoppip/riscv-isa-sim/build
   ```

## Build + Run + Test

1. Run cmake from inside the build directory
   ```
   cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake
   ```

2. Compile the MLIR needed by the test case
   ```
   cd tests
   sh compile-for-riscv.sh <testCaseName.mlir>
   cd .. # return to build directory
   ```

3. Build the test case

   ```ninja <TestCaseName>
   ninja <TestCaseName>
   ```

4. Run regularly with
   ```
   ../../toolchain/bin/snitch_cluster.vlt tests/<TestCaseName>
   ```

5. Run as an official test case with
   ```
   ctest -R <TestCaseName>
   ```

Example:

```
ninja HelloWorld
ctest -R HelloWorld
```

# Troubleshooting

Error:

```
In file included from main.c:1:
In file included from /home/hoppip/llvm-project-pistachio/build-riscv/lib/clang/18/include/stdint.h:52:
In file included from /usr/include/stdint.h:26:
In file included from /usr/include/bits/libc-header-start.h:33:
In file included from /usr/include/features.h:527:
/usr/include/gnu/stubs.h:7:11: fatal error: 'gnu/stubs-32.h' file not found
    7 | # include <gnu/stubs-32.h>
```

Solution:

```
sudo yum install glibc-devel.i686
```

from this link: https://superuser.com/questions/491504/how-do-i-install-package-libc6-dev-i386-on-fedora

Error:
```
sudo apt-get install device-tree-compiler libboost-regex-dev
Reading package lists... Done
Building dependency tree... Done
E: Unable to locate package device-tree-compiler
E: Unable to locate package libboost-regex-dev

```

Solution:

```
sudo yum install dtc
```

Error:
```
Error: cannot execute 32-bit program on RV64 hart
```

Potential Solution: Using [this source](https://stackoverflow.com/questions/74948567/the-32-bit-program-cannot-be-executed-with-risc-v-spike-cant-execute-32-bit-pr) as a guide, I tried adding the flag `--isa=rv32i` to the spike command:

```
$SPIKE/spike -m0x10000000:0x40000,0x80000000:0x80000000 --isa=RV32IMAFDC --disable-dtb -p9 tests/${basename^}
```

