# TiledMatmul3

This example runs tiled matrix multiplication on the snitch DMA core.
Tiling scheme is chosen by ZigZag.

[back to all tests](../../../zigzag-fork/README.md#Examples)

## I. Input to ZigZag

#### a. MLIR (use linalg-to-stream tool)

```
  "func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> (), sym_name = "simple_matmul"}> ({
  ^bb0(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8, strided<[1, 16]>>, %arg2: memref<16x16xi32>):
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
    }) : (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, i32, i32, memref<16x16xi32>) -> ()
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
        "loop_dim_size": {"D0": 16, "D1": 16, "D2": 16},
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
for d0; d0 < 16; d0++:
for d1; d1 < 16; d1++;
for d2; d2 < 16; d2++;
  arg7[d0][d1] += arg3[d0][d2] * arg4[d2][d1]; // and this is a MAC!
```

## II. Output from ZigZag

```
==========================================================================
Temporal Loops                     O            W            I            
==========================================================================
for D0 in [0, 4):                  l1           l1           l1           
--------------------------------------------------------------------------
  for D0 in [0, 4):                l1           l1           l1           
--------------------------------------------------------------------------
    for D1 in [0, 2):              l1           l1           l1           
--------------------------------------------------------------------------
      for D1 in [0, 2):            l1           l1           l1           
--------------------------------------------------------------------------
        for D1 in [0, 4):          l1           l1           l1           
--------------------------------------------------------------------------
          for D2 in [0, 2):        rf_32b_O     l1           l1           
--------------------------------------------------------------------------
==========================================================================
Spatial Loops                                                             
==========================================================================
            parfor D2 in [0, 8):                                          
--------------------------------------------------------------------------
SpatialMapping({'O': [[('D2', 8.0)], [], [], []], 'W': [[('D2', 8.0)], [], []], 'I': [[('D2', 8.0)], [], []]})
```

## III. Manual Transformation

#### a. C code transformed

```
void mlir_qmat_transformed(squareMat *a, squareMat *b, squareMat *c,
                           squareMat *dummy) {
  transposeSquareMat(b, dummy);
  // only square matrices allowed
  size_t d0_1_bk_sz = a->len / 4;
  size_t d1_1_bk_sz = a->len / 2;
  size_t d1_2_bk_sz = d1_1_bk_sz / 2;
  size_t d2_1_bk_sz = a->len / 2;

  for (size_t d0_1 = 0; d0_1 < 4; d0_1++) {
    for (size_t d0_2 = 0; d0_2 < 4; d0_2++) {
      for (size_t d1_1 = 0; d1_1 < 2; d1_1++) {
        for (size_t d1_2 = 0; d1_2 < 2; d1_2++) {
          for (size_t d1_3 = 0; d1_3 < 4; d1_3++) {
            for (size_t d2_1 = 0; d2_1 < 2; d2_1++) {
              for (size_t d2_2 = 0; d2_2 < 8;
                   d2_2++) { // technically spacially unrolled, but won't show
                             // that here
                size_t d0 = d0_1 * d0_1_bk_sz + d0_2;
                size_t d1 = d1_1 * d1_1_bk_sz + d1_2 * d1_2_bk_sz + d1_3;
                size_t d2 = d2_1 * d2_1_bk_sz + d2_2;
                c->mat[d0][d1] += a->mat[d0][d2] * b->mat[d2][d1];
              }
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
"func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32, strided<[16,1]>>) -> (), sym_name = "tiled_matmul"}> ({
  ^bb0(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8, strided<[1,16]>>, %arg2: memref<16x16xi32, strided<[16,1]>>):
    // block sizes
    %d0_1_bk_sz = arith.constant 4 : index
    %d1_1_bk_sz = arith.constant 8 : index
    %d1_2_bk_sz = arith.constant 4 : index
    %d2_1_bk_sz = arith.constant 8 : index

    // indices
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %two = arith.constant 2 : index
    %four = arith.constant 4 : index
    %eight = arith.constant 8 : index
    %sixteen = arith.constant 16 : index

    // enter scf nested FOR LOOP
    scf.for %d0_1 = %zero to %four step %one iter_args() -> () {
    scf.for %d0_2 = %zero to %four step %one iter_args() -> () {    
    scf.for %d1_1 = %zero to %two step %one iter_args() -> () {  
    scf.for %d1_2 = %zero to %two step %one iter_args () -> () { 
    scf.for %d1_3 = %zero to %four step %one iter_args () -> () {
    scf.for %d2_1 = %zero to %two step %one iter_args () -> () {
    scf.for %d2_2 = %zero to %eight step %one iter_args () -> () {
    
      //  size_t d0 = d0_1 * d0_1_bk_sz + d0_2;
      %prod0 = arith.muli %d0_1, %d0_1_bk_sz : index
      %d0 = arith.addi %prod0, %d0_2 : index
      
      // size_t d1 = d1_1 * d1_1_bk_sz + d1_2 * d1_2_bk_sz + d1_3;
      %prod1 = arith.muli %d1_1, %d1_1_bk_sz : index
      %prod1_2 = arith.muli %d1_2, %d1_2_bk_sz : index
      %sum1 = arith.addi %prod1, %prod1_2 : index
      %d1 = arith.addi %sum1, %d1_3 : index
      
      // size_t d2 = d2_1 * d2_1_bk_sz + d2_2;
      %prod2 = arith.muli %d2_1, %d2_1_bk_sz : index
      %d2 = arith.addi %prod2, %d2_2 : index
      
      // MAC c->mat[d0][d1] += a->mat[d0][d2] * b->mat[d2][d1];
      %inputElt = memref.load %arg0[%d0, %d2] : memref<16x16xi8>
      %inputEltCasted = arith.extsi  %inputElt : i8 to i32 
      %weightElt = memref.load %arg1[%d2, %d1] : memref<16x16xi8, strided<[1,16]>>
      %weightEltCasted = arith.extsi  %weightElt : i8 to i32 
      %prod = arith.muli %inputEltCasted, %weightEltCasted : i32
      %outputElt = memref.load %arg2[%d0, %d1] : memref<16x16xi32, strided<[16,1]>> 
      %newOutputElt = arith.addi %prod, %outputElt : i32 
      memref.store %newOutputElt, %arg2[%d0, %d1] : memref<16x16xi32, strided<[16,1]>>
    } // end of d2_2 for
    } // end of d2_1 for
    } // end of d1_3 for
    } // end of d1_2 for
    } // end of d1_1 for
    } // end of d0_2 for
    } // end of d0_1 for
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()
```

## IV. Running the transformed MLIR on Snitch

```
cd runtime/tests
```

spike: 
```
sh zigzag-spike-build-and-run.sh tiledMatmul2.mlir
```

verilator:
```
sh zigzag-verilator-build-and-run.sh tiledMatmul2.mlir
```

