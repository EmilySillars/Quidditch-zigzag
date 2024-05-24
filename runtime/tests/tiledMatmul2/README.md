# TiledMatmul3

## I. Input to ZigZag

#### a. MLIR (use linalg-to-stream tool)

```
  "func.func"() <{function_type = (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, memref<2048x2048xi32>) -> (), sym_name = "simple_matmul"}> ({
  ^bb0(%arg0: memref<2048x2048xi8>, %arg1: memref<2048x2048xi8, strided<[1, 2048]>>, %arg2: memref<2048x2048xi32>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "linalg.generic"(%arg0, %arg1, %0, %0, %arg2) <{indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d2, d1)>, affine_map<(d0, d1, d2) -> ()>, affine_map<(d0, d1, d2) -> ()>, affine_map<(d0, d1, d2) -> (d0, d1)>], iterator_types = [#linalg.iterator_type<parallel>, #linalg.iterator_type<parallel>, #linalg.iterator_type<reduction>], operandSegmentSizes = array<i32: 4, 1>}> ({
    ^bb0(%arg3: i8, %arg4: i8, %arg5: i32, %arg6: i32, %arg7: i32):
      %1 = "arith.extsi"(%arg3) : (i8) -> i32
      %2 = "arith.subi"(%1, %arg5)  : (i32, i32) -> i32
      %3 = "arith.extsi"(%arg4) : (i8) -> i32
      %4 = "arith.subi"(%3, %arg6)  : (i32, i32) -> i32
      %5 = "arith.muli"(%2, %4)  : (i32, i32) -> i32
      %6 = "arith.addi"(%arg7, %5) : (i32, i32) -> i32
      "linalg.yield"(%6) : (i32) -> ()
    }) : (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, i32, i32, memref<2048x2048xi32>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()
```

#### b. Equivalent Python Workload Object? (directly passed to zigzag)

Need to double check if this workload object is correct!

```
workload = {
    0: {
        "operator_type": "default",
        "equation": "O[d0][d1] += I[d0][d2] * W[d2][d1]",
        "dimension_relations": [],
        "loop_dim_size": {"D0": 2048, "D1": 2048, "D2": 2048},
        "operand_precision": {"O": 32, "O_final": 32, "W": 8, "I": 8},
        "operand_source": {"W": [], "I": []},
        "constant_operands": ["I", "W"],
        "padding": {},
    }
}
```

#### c. C code Equivalent (cannot feed to zigzag; just for reference)

C-ish pseudocode (ignoring sign extension and subtracting 0 instructions)

```
for d0; d0 < 2048; d0++:
for d1; d1 < 2048; d1++;
for d2; d2 < 2048; d2++;
  arg7[d0][d1] += arg3[d0][d2] * arg4[d2][d1]; // and this is a MAC!
```

## II. Output from ZigZag

```
todo
```

## III. Manual Transformation

#### a. C code transformed

```
todo
```

#### b. MLIR transformed

```
todo
```

## IV. Running the transformed MLIR on Snitch

```
cd runtime/tests
```

spike: 
```
sh zigzag-spike-build-and-run.sh tiledMatmul3.mlir
```

verilator:
```
sh zigzag-verilator-build-and-run.sh tiledMatmul3.mlir
```

