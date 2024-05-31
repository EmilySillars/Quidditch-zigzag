# Matrix Multiplication 8

- This example runs tiled matrix multiplication on the snitch DMA core.
- Tiling scheme is chosen by ZigZag.
- Dynamically Allocated Input
- Matrix size 600x600

[back to all tests](../../../zigzag-fork/README.md#Examples)

## I. Input to ZigZag

#### a. MLIR (use linalg-to-stream tool)

python xdsl_opt_main.py tests/matmul9.mlir -p linalg-to-stream; python run_zigzag.py

```
// matrices are 600 x 600
#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({
 
"func.func"() <{function_type = (memref<600x600xi8>, memref<600x600xi8, strided<[1, 600]>>, memref<600x600xi32>) -> (), sym_name = "simple_matmul"}> ({
  ^bb0(%arg0: memref<600x600xi8>, %arg1: memref<600x600xi8, strided<[1, 600]>>, %arg2: memref<600x600xi32>):
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
    }) : (memref<600x600xi8>, memref<600x600xi8, strided<[1, 600]>>, i32, i32, memref<600x600xi32>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()
  }) : () -> ()
```

#### b. Equivalent Python Workload Object? (directly passed to zigzag)

```
workload = {
    0: {
        "operator_type": "default",
        "equation": "O[d0][d1] += I[d0][d2] * W[d2][d1]",
        "dimension_relations": [],
        "loop_dim_size": {"D0": 600, "D1": 600, "D2": 600},
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
for d0; d0 < 600; d0++:
for d1; d1 < 600; d1++;
for d2; d2 < 600; d2++;
  arg7[d0][d1] += arg3[d0][d2] * arg4[d2][d1]; // and this is a MAC!
```

## II. Output from ZigZag

```
==============================================================================
Temporal Loops                         O            W            I            
==============================================================================
for D0 in [0, 15):                     l3           l3           l3           
------------------------------------------------------------------------------
  for D1 in [0, 5):                    l3           l3           l1           
------------------------------------------------------------------------------
    for D1 in [0, 15):                 l3           l3           l1           
------------------------------------------------------------------------------
      for D0 in [0, 5):                l1           l1           l1           
------------------------------------------------------------------------------
        for D2 in [0, 15):             rf_32b_O     l1           l1           
------------------------------------------------------------------------------
          for D2 in [0, 5):            rf_32b_O     l1           l1           
------------------------------------------------------------------------------
==============================================================================
Spatial Loops                                                                 
==============================================================================
            parfor D0 in [0, 8):                                              
------------------------------------------------------------------------------
            parfor D1 in [0, 8):                                              
------------------------------------------------------------------------------
            parfor D2 in [0, 8):                                              
------------------------------------------------------------------------------
```

## III. Manual Transformation

#### a. C code transformed

```
void matmul_transformed(squareMat *a, squareMat *b, squareMat *c,
                           squareMat *dummy) {
  // only square matrices allowed
  size_t d0_1_bk_sz = a->len / 15; // 600 / 15 = 40  
  size_t d1_1_bk_sz = a->len / 15; // 40
  size_t d2_1_bk_sz = a->len / 15; // 40
  size_t d0_2_bk_sz = a->len / 5;  // 40 / 5 = 8
  size_t d1_2_bk_sz = a->len / 5;  // 8
  size_t d2_2_bk_sz = a->len / 5;  // 8
  
  for (size_t d0_1 = 0; d0_1 < 15; d0_1++) {
   for (size_t d1_1 = 0; d1_1 < 5; d1_1++) {
    for (size_t d1_2 = 0; d1_2 < 15; d1_2++) {
     for (size_t d0_2 = 0; d0_2 < 5; d0_2++) {
      for (size_t d2_1 = 0; d2_1 < 15; d2_1++) {
       for (size_t d2_2 = 0; d2_2 < 5; d2_2++) {
       
        // these inner three loops should be spacially unrolled, 
        // but ignore for now...
        for (size_t d0_3 = 0; d0_3 < 8; d0_3++) {
         for (size_t d1_3 = 0; d1_3 < 8; d1_3++){
          for (size_t d2_3 = 0; d2_3 < 8; d2_3++) {
          
            // calculate indices
            size_t d0 = d0_1 * d0_1_bk_sz + d0_2 * d0_2_bk_sz + d0_3;
            size_t d1 = d1_1 * d1_1_bk_sz + d1_2 * d1_2_bk_sz + d1_3;
            size_t d2 = d2_1 * d2_1_bk_sz + d2_2 * d2_2_bk_sz + d2_3;

            //perform MAC
            c->mat[d0][d1] += a->mat[d0][d2] * b->mat[d2][d1];
          
          }
         }        
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
"func.func"() <{function_type = (memref<600x600xi8>, memref<600x600xi8, strided<[1, 600]>>, memref<600x600xi32, strided<[600,1]>>) -> (), sym_name = "tiled_matmul"}> ({
  ^bb0(%arg0: memref<600x600xi8>, %arg1: memref<600x600xi8, strided<[1,600]>>, %arg2: memref<600x600xi32, strided<[600,1]>>):
    %d0_1_bk_sz = arith.constant 15 : index
    %d0_2_bk_sz = arith.constant 40 : index
    %d0_3_bk_sz = arith.constant 5 : index
    %d1_1_bk_sz = arith.constant 15 : index
    %d1_2_bk_sz = arith.constant 40 : index
    %d1_3_bk_sz = arith.constant 5 : index
    %d2_1_bk_sz = arith.constant 15 : index
    %d2_2_bk_sz = arith.constant 40 : index
    %d2_3_bk_sz = arith.constant 5 : index

    // indices
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %fifteen = arith.constant 15 : index
    %five = arith.constant 5: index
    %eight = arith.constant 8 : index

    // enter scf nested FOR LOOP
    scf.for %d0_1 = %zero to %fifteen step %one iter_args() -> () {
    scf.for %d1_1 = %zero to %five step %one iter_args() -> () {    
    scf.for %d1_2 = %zero to %fifteen step %one iter_args() -> () {  
    scf.for %d0_2 = %zero to %five step %one iter_args () -> () { 
    scf.for %d2_1 = %zero to %fifteen step %one iter_args () -> () {
    scf.for %d2_2 = %zero to %five step %one iter_args () -> () {
    scf.for %d0_3 = %zero to %eight step %one iter_args () -> () {
    scf.for %d1_3 = %zero to %eight step %one iter_args () -> () {
    scf.for %d2_3 = %zero to %eight step %one iter_args () -> () {

    // calculate indices
    %prod0_1 = arith.muli %d0_1, %d0_1_bk_sz : index
    %prod0_2 = arith.muli %d0_2, %d0_2_bk_sz : index
    %sum_0 = arith.addi %prod0_1, %prod0_2 : index
    %d0 = arith.addi %sum_0, %d0_3 : index

    %prod1_1 = arith.muli %d1_1, %d1_1_bk_sz : index
    %prod1_2 = arith.muli %d1_2, %d1_2_bk_sz : index
    %sum_1 = arith.addi %prod1_1, %prod1_2 : index
    %d1 = arith.addi %sum_1, %d1_3 : index

    %prod2_1 = arith.muli %d2_1, %d2_1_bk_sz : index
    %prod2_2 = arith.muli %d2_2, %d2_2_bk_sz : index
    %sum_2 = arith.addi %prod2_1, %prod2_2 : index
    %d2 = arith.addi %sum_2, %d2_3 : index

      // input slice
      %inputElt = memref.load %arg0[%d0, %d2] : memref<600x600xi8>
      %inputEltCasted = arith.extsi  %inputElt : i8 to i32 
      // weight slide
      %weightElt = memref.load %arg1[%d2, %d1] : memref<600x600xi8, strided<[1,600]>>
      %weightEltCasted = arith.extsi  %weightElt : i8 to i32 
      // output slice
      %outputElt = memref.load %arg2[%d0, %d1] : memref<600x600xi32, strided<[600,1]>> //memref<1x1xi8>
      %prod = arith.muli %inputEltCasted, %weightEltCasted : i32
      %newOutputElt = arith.addi %prod, %outputElt : i32 
      // update output
      memref.store %newOutputElt, %arg2[%d0, %d1] : memref<600x600xi32, strided<[600,1]>>
    }
    }
    } 
    } 
    } 
    } 
    } 
    } 
    } 

    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()
```

## IV. Running the transformed MLIR on Snitch

```
cd runtime/tests
```

spike: 

```
sh zigzag-spike-build-and-run.sh tiledMatmul9.mlir
```

verilator:

```
 
sh zigzag-verilator-build-and-run.sh tiledMatmul9.mlir
```

