# Quidditch ZigZag Fork

Run and Test examples on *Verilator Simulating Snitch*.

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

Run cmake on the project:

```
cd build && cmake .. -GNinja -DCMAKE_TOOLCHAIN_FILE=../toolchain/ToolchainFile.cmake
```

##### HelloWorld

```
ninja HelloWorld
```

## Run

##### HelloWorld

From inside build directory with:

```
ctest -R HelloWorld
```

## Test

##### HelloWorld

From inside build directory with:

```
../../toolchain/bin/snitch_cluster.vlt tests/HelloWorld
```

