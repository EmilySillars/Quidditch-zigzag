# Quidditch-Zigzag Forked Repo

Run and Test MLIR examples with *Verilator and Spike Simulating Snitch*.

##### Current Status

- this repo deals with everything inside the blue box
- red text means WIP/next steps
- Check [ZigZig Integration Status Slides](https://docs.google.com/presentation/d/1-YQwx20RkEFZoqrMr_WQOjtFaXDR8e_lfNbEfbl83HA/edit?usp=sharing) for more info

![this repo deals with everything in the blue box](blue-box.png)

## Example Programs

*Before doing anything, remember to [set your environment variables correctly](#Setup), either manually or by editing [setup.sh]([./setup.sh](https://github.com/EmilySillars/Quidditch-zigzag/blob/manual-transformations/zigzag-fork/setup.sh))* and then running `. setup.sh` 

```
cd runtime/tests
```

- **HolaWorld** ([MLIR](../runtime/tests/hola-world/matmul-tiled.mlir) calling [C code](../runtime/tests/hola-world/main.c) which prints a greeting)

  ```
  sh zigzag-spike-build-and-run.sh holaWorld.mlir
  ```

- **Matrix Multiplication** 16 x 16 2D matrices; statically allocated

  ```
  sh zigzag-verilator-build-and-run.sh matmul.mlir
  ```

- **Tiled Matrix Multiplication** 16 x 16 2D matrices; statically allocated (runs slow on verilator)

  ```
  sh zigzag-spike-build-and-run.sh tiledMatmul.mlir
  ```

- **Tiled Matrix Multiplication 2** [(details here)](../runtime/tests/tiledMatmul2/README.md) 16 x 16 2D matrices; statically allocated; zizag tiled

  ```
  sh zigzag-spike-build-and-run.sh tiledMatmul2.mlir
  ```

- **Tiled Matrix Multiplication 3** ([details here](../runtime/tests/tiledMatmul3/README.md) 16 x 16 2D matrices; dynamically allocated; zizag tiled

- ~~**Tiled Matrix Multiplication 3** [(details here)](../runtime/tests/tiledMatmul3/README.md) 2048 x 2048 2D matrices~~

## Build + Run + Test

### 1. with Verilator Simulating Snitch (slow, cycle accurate)

1) navigate to the tests directory: `cd runtime/tests`

2) run the following script with the name of the kernel's mlir source file; for example, `holaWorld.mlir`
   ```
   sh zigzag-build-and-run.sh holaWorld.mlir
   ```

### 2. with Spike Simulating Snitch (faster, not cycle accurate)

1. navigate to the tests directory: `cd runtime/tests`

2. run the following script with the name of the kernel's mlir source file; for example, `holaWorld.mlir`
   ```
   sh zigzag-spike-build-and-run.sh holaWorld.mlir
   ```

### 3. on x86 CPU (Reality Check) (segfaults! need to debug!)

1) navigate to the tests directory: `cd runtime/tests`

2) run the following script with the name of the kernel's mlir source file; for example, `holaWorld.mlir`

  ```
  sh ../run-w-x86.sh matmul-tiled.mlir
  ```

**Tests Not Working**

- `sh run-w-x86.sh matmul.mlir` (not working! need to fix!)

- `sh run-w-x86.sh matmul-tiled.mlir` (not working! need to fix!)

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

### 2. Set up Snitch-Specific Spike

1. [clone the repo](https://github.com/opencompl/riscv-isa-sim/tree/CSR-Barrier) and switch to the  `origin/CSR-Barrier` branch:

   ```
   git clone https://github.com/opencompl/riscv-isa-sim.git
   git switch origin/CSR-Barrier
   ```

2. ```
   apt-get install device-tree-compiler libboost-regex-dev
   cd riscv-isa-sim
   mkdir build
   cd build
   ../configure --with-target=riscv32-unknown-elf --with-isa=RV32IMAFD --prefix=/home/hoppip/riscv-isa-sim/build
   make
   make install
   ```

### 3. Set Environment Variables 

Before running any examples,

- remember to add your MLIR LLVM build to your install path, for example:

  ```
  export PATH=/home/hoppip/llvm-project-pistachio/build-riscv/bin:$PATH # for regular mlir-opt
  export PATH=/home/hoppip/llvm-project-17/build-riscv/bin:$PATH        # for mlir-opt-17
  ```

- remember to set the RISCV environment variable to your risc-v toolchain install path, for example:

  ```
  export PATH="/home/hoppip/riscv/bin:$PATH"
  ```

- remember to set the SPIKE environment variable to your spike `riscv-isa-sim` build directory, for example:

  ```
  export SPIKE="/home/hoppip/riscv-isa-sim/build"
  ```

Automate this step by running [setup.sh](setup.sh)

```
. setup.sh
```

## Build + Run + Test (more steps, fewer shell scripts)

1. Run cmake from inside the build directory
   ```
   cd build
   cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake
   ```

2. Compile the MLIR needed by the test case
   ```
   cd tests
   sh compile-for-riscv.sh <testCaseName.mlir>
   cd .. # return to build directory
   ```

3. Build 

   ```ninja <TestCaseName>
   ninja <TestCaseName>
   ```

4. Run 
   a. using verilator: `../../toolchain/bin/snitch_cluster.vlt tests/<TestCaseName>`
   b. using spike: `$SPIKE/spike -m0x10000000:0x40000,0x80000000:0x80000000 --disable-dtb -p9 tests/<TestCaseName> ` 

5. Test

   using ctest: `ctest -R <TestCaseName>`

Example:

```
cd build
cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake
cd tests
sh compile-for-riscv.sh holaWorld.mlir
cd ..
ninja HolaWorld
../../toolchain/bin/snitch_cluster.vlt tests/HolaWorld                                    # verilator
$SPIKE/spike -m0x10000000:0x40000,0x80000000:0x80000000 --disable-dtb -p9 tests/HolaWorld # spike
ctest -R HolaWorld                                                                        # as a test
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

## Old notes to delete later

- Hola World (which calls a C function from MLIR) runs with snitch verliator and non-snitch x86 cpu

- Regular Matmul and Tiled Matmul both run with snitch verilator but  **segfault** on non-snitch x86 cpu

  Best guess of cause: my lowering of MLIR to llvm is not adequate

  - My lowering script: [compile-for-riscv.sh](../runtime/tests/compile-for-riscv.sh)
  - Snax-MLIR's lowering script: [run_simple_matmul.sh](https://github.com/EmilySillars/snax-mlir-zigzag/blob/zigzag-to-snax/kernels/simple_matmul2/call-c-from-mlir/run_simple_matmul.sh)

1) From section quarter it says: "Corresponde al inquilino el pago de los gastos que se ocasionen por la
   utilización de los servicios y suministros de la vivienda."

Does this refer to utilities? If it does, could the lease list them explicitly, something like, "El inquilino se hace cargo del pago de los gastos de agua y luz." instead?

2) Also from section quarter, it says: "También son responsables de pagar los servicios que puedan contratar a su propio nombre". What does this mean? Does this mean if the sink were to leak, the homeowners could hire a plumber to fix the problem and then I would be responsible to pay for it? Could we remove this line from the lease?

3) From section seven, it says: "La vivienda y el mobiliario se encuentran en perfecto estado de uso, limpieza y conservación. El inquilino se obliga a conservarla y devolverla en el mismo estado."

Could this line be replaced with, "Los muebles están en perfectas condiciones de uso pero no son nuevos y serán devueltos en el mismo estado."

4. When I visited the apartment, I noticed that the bathroom was smelly. Could we add the following to the bottom of section 7? "Al visitar el apartamento, el inquilino notó un olor a humedad que salía del baño, especialmente de debajo del lavabo. Ella cree que con una limpieza más profunda el olor desaparecerá (y planea realizar dicha limpieza cuando se mude), pero si descubre que hay un problema de plomería relacionado con este olor, no es responsable del costo de la reparación."

   

5. 

6. Upon visiting the apartment, the tenant noticed a musty oder coming from the bathroom, especially from under the sink. She believes with some more deep cleaning the smell will subside (and she plans to perform such cleaning when she moves in) but if she discovers there is a plumbing problem related to this smell, she is not responsible for the cost of repair.
