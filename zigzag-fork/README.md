# Quidditch ZigZag Fork

Run and Test examples on *Verilator Simulating Snitch*.

## Current Status

- Hola World (which calls a C function from MLIR runs on verliator and x86 cpu)
- Regular Matmul and Tiled Matmul are both **segfaulting** on x86 cpu

  Best guess of cause: my lowering of MLIR to llvm is not adequate
  - My lowering script: [compile-for-riscv.sh](../runtime/tests/compile-for-riscv.sh)
  - Snax-MLIR's lowering script: [run_simple_matmul.sh](https://github.com/EmilySillars/snax-mlir-zigzag/blob/zigzag-to-snax/kernels/simple_matmul2/call-c-from-mlir/run_simple_matmul.sh)

## Run MLIR DNN Kernels

### on Verilator Simulating Snitch

```
cd runtime/build/tests/<Test-name>
sh ../compile-for-riscv.sh <test-name>.mlir
cd ../../
cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake
ninja <Test-name>
../../toolchain/bin/snitch_cluster.vlt tests/<Test-name>
```

- [MLIR](../runtime/tests/hola-world/matmul-tiled.mlir) calling [C code](../runtime/tests/hola-world/main.c)
  from inside `runtime/tests/hola-world`,

  ```
  sh compile-for-riscv.sh matmul-tiled.mlir 
  ```

  Then from inside build directory, do

  ```
  cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake
  ninja HolaWorld
  ../../toolchain/bin/snitch_cluster.vlt tests/HolaWorld
  ```

- Regular Matmul??
- Tiled Matmul??

### on x86 CPU (Reality Check)

Before starting, make sure to add your MLIR LLVM build to your path. For example,

```
export PATH=/home/hoppip/llvm-project-pistachio/build-riscv/bin:$PATH
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

## Build 

Run cmake from inside the build directory with:

```
cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake
```

##### HelloWorld

```
ninja HelloWorld
```

##### HolaWorld

```
ninja HolaWorld
```

## Test

##### All Test Cases

From inside build directory with:

```
ctest
```

##### HelloWorld

From inside build directory with:

```
ctest -R HelloWorld
```

##### HolaWorld

From inside build directory with:

```
ctest -R HolaWorld
```

## Run

##### HelloWorld

From inside build directory with:

```
../../toolchain/bin/snitch_cluster.vlt tests/HelloWorld
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
