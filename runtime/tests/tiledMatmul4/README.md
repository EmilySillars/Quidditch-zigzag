# Matrix Multiplication 4

- This example runs tiled matrix multiplication on the snitch DMA core.
- Tiling scheme is chosen by ZigZag.
- Dynamically Allocated Input
- Matrix size 17 x 17

[back to all tests](../../../zigzag-fork/README.md#Examples)

## I. Input to ZigZag

#### a. MLIR (use linalg-to-stream tool)

python xdsl_opt_main.py tests/matmul5.mlir -p linalg-to-stream; python run_zigzag.py

```
// matrices are 17 x 17
#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({
 
"func.func"() <{function_type = (memref<17x17xi8>, memref<17x17xi8, strided<[1, 17]>>, memref<17x17xi32>) -> (), sym_name = "simple_matmul"}> ({
  ^bb0(%arg0: memref<17x17xi8>, %arg1: memref<17x17xi8, strided<[1, 17]>>, %arg2: memref<17x17xi32>):
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
    }) : (memref<17x17xi8>, memref<17x17xi8, strided<[1, 17]>>, i32, i32, memref<17x17xi32>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()
  }) : () -> ()
```

#### b. Equivalent Python Workload Object? (directly passed to zigzag)

```
workload = {
    0: {
        "operator_type": "default",
        "equation": "O[d0][d1] += I[d0][d2] * W[d2][d1]",
        "dimension_relations": [],
        "loop_dim_size": {"D0": 17, "D1": 17, "D2": 17},
        "operand_precision": {"O": 32, "O_final": 32, "W": 8, "I": 8},
        "operand_source": {"W": [], "I": []},
        "constant_operands": ["I", "W"],
        "padding": {"D0": (0, 0), "D2": (0, 0)},
    }
}
```

#### c. C code Equivalent (cannot feed to zigzag; just for reference)

C-ish pseudocode (ignoring sign extension and subtracting 0 instructions)

```
for d0; d0 < 17; d0++:
for d1; d1 < 17; d1++;
for d2; d2 < 17; d2++;
  arg7[d0][d1] += arg3[d0][d2] * arg4[d2][d1]; // and this is a MAC!
```

## II. Output from ZigZag

```
========================================================================
Temporal Loops                   O            W            I            
========================================================================
for D0 in [0, 3):                l1           l1           l1           
------------------------------------------------------------------------
  for D1 in [0, 3):              l1           l1           l1           
------------------------------------------------------------------------
    for D2 in [0, 3):            rf_32b_O     l1           l1           
------------------------------------------------------------------------
========================================================================
Spatial Loops                                                           
========================================================================
      parfor D1 in [0, 6):                                              
------------------------------------------------------------------------
      parfor D0 in [0, 6):                                              
------------------------------------------------------------------------
      parfor D2 in [0, 6):                                              
------------------------------------------------------------------------
```

## III. Manual Transformation

#### a. C code transformed

```
void matmul_transformed(squareMat *a, squareMat *b, squareMat *c,
                           squareMat *dummy) {
  // only square matrices allowed
  size_t d0_1_bk_sz = a->len / 3;   
  size_t d1_1_bk_sz = a->len / 3;
  size_t d2_1_bk_sz = a->len / 3;
  
  for (size_t d0_1 = 0; d0_1 < 3; d0_1++) {
   for (size_t d1_1 = 0; d1_1 < 3; d1_1++) {
    for (size_t d2_1 = 0; d2_1 < 3; d2_1++) {
    
     // these inner three loops should be spacially unrolled, but ignore for now...
     for (size_t d1_2 = 0; d1_2 < 6; d1_2++) {
      for (size_t d0_2 = 0; d0_2 < 6; d0_2++) {
       for (size_t d2_2 = 0; d2_2 < 6; d2_2++) {
       
        // calculate indices
        size_t d0 = d0_1 * d0_1_bk_sz + d0_2;
        size_t d1 = d1_1 * d1_1_bk_sz + d1_2;
        size_t d2 = d2_1 * d2_1_bk_sz + d2_2;
        
        //perform MAC
        c->mat[d0][d1] += a->mat[d0][d2] * b->mat[d2][d1];
       }
      }
     }
    }
   }
  }                           
}
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
sh zigzag-spike-build-and-run.sh tiledMatmul4.mlir
```

verilator:

```
 
sh zigzag-verilator-build-and-run.sh tiledMatmul4.mlir
```

