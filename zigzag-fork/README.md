# Quidditch ZigZag Fork

Run and Test examples on *Verilator Simulating Snitch*.

My examples

- Tiled Matmul running on the DMA Core: [C Code](../runtime/tests/tiled-matmul.c), MLIR

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

##### TiledMatmul

```
ninja TiledMatmul
```

## Run

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

##### TiledMatmul

From inside build directory with:

```
ctest -R TiledMatmul
```

## Test

##### HelloWorld

From inside build directory with:

```
../../toolchain/bin/snitch_cluster.vlt tests/HelloWorld
```

