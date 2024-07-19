# Matrix Multiplication 12

- This example runs tiled matrix multiplication on a snitch cluster of 8 compute cores.
- Tiling scheme is chosen by ZigZag using a [snitch cluster](https://github.com/EmilySillars/zigzag/blob/manual-examples/zigzag/inputs/hardware/snitch-cluster-only-integers.yaml) hardware description.
- Dynamically Allocated Input
- Matrix size 104 x 104

[back to all tests](../../../zigzag-fork/README.md#Examples)

## I. Input to ZigZag

#### a. MLIR (someday, use linalg-to-stream tool to convert to yaml...)

```
// matrices are 104 x 104
#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({
 
"func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32>) -> (), sym_name = "simple_matmul"}> ({
  ^bb0(%arg0: memref<104x104xi8>, %arg1: memref<104x104xi8, strided<[1, 104]>>, %arg2: memref<104x104xi32>):
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
    }) : (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, i32, i32, memref<104x104xi32>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()
  }) : () -> ()
```

#### b. Equivalent yaml Workload Object (directly passed to zigzag)

```
- id: 0 
  name: matmul_104_104  # name can be used to specify mapping
  operator_type: MatMul  # operator_type can be used to specify mapping
  equation: O[a][b]+=I[a][c]*W[c][b]
  dimension_relations: []
  loop_dims: [A,B,C]
  loop_sizes: [104, 104, 104]
  operand_precision:
    W: 8
    I: 8
    O: 32
    O_final: 32
  operand_source:
    I: 0
    W: 0
```

#### c. C code Equivalent (cannot feed to zigzag; just for reference)

C-ish pseudocode (ignoring sign extension and subtracting 0 instructions)

```
for d0; d0 < 104; d0++:
for d1; d1 < 104; d1++;
for d2; d2 < 104; d2++;
  arg7[d0][d1] += arg3[d0][d2] * arg4[d2][d1]; // and this is a MAC!
```

#### d. Snitch Compute Core Hardware Description

![hardware](../../../zigzag-fork/pngs/cluster.png)

- [This is the yaml fed to ZigZag](https://github.com/EmilySillars/zigzag/blob/manual-examples/zigzag/inputs/hardware/snitch-cluster-only-integers.yaml)

- Full documentation of feeding to ZigZag and getting output [here](https://github.com/EmilySillars/zigzag/blob/58e38adf8191e2b983c5e0ec97480ed97ef797dd/modeling-snitch-with-zigzag.md).

## II. Output from ZigZag

```
Loop ordering for matmul_104_104
=============================================================================================
Temporal Loops                      W                  O                  I                  
=============================================================================================
for B in [0, 13):                   l1                 l3                 l1                 
---------------------------------------------------------------------------------------------
  for A in [0, 8):                  l1                 l1                 l1                 
---------------------------------------------------------------------------------------------
    for C in [0, 13):               l1                 rf_x1_thru_x31     l1                 
---------------------------------------------------------------------------------------------
      for C in [0, 4):              rf_x1_thru_x31     rf_x1_thru_x31     l1                 
---------------------------------------------------------------------------------------------
        for C in [0, 2):            rf_x1_thru_x31     rf_x1_thru_x31     rf_x1_thru_x31     
---------------------------------------------------------------------------------------------
          for A in [0, 13):         rf_x1_thru_x31     rf_x1_thru_x31     rf_x1_thru_x31     
---------------------------------------------------------------------------------------------
=============================================================================================
Spatial Loops                                                                                
=============================================================================================
            parfor B in [0, 8):                                                              
---------------------------------------------------------------------------------------------
            parfor B in [0, 1):                                                              
---------------------------------------------------------------------------------------------
```

![hardware](../../../zigzag-fork/pngs/host-acc-div-tiledMatmul12.png)

Comments:

|                        |           | `B=8` |           | `B=13` |             | `A=8` |                 | `C=13` |         | `C=4` |           | `C=2` |             | `A=13`        |       |
| ---------------------- | --------- | ----- | --------- | ------ | ----------- | ----- | --------------- | ------ | ------- | ----- | --------- | ----- | ----------- | ------------- | ----- |
| `I[a][c]`              | `104x104` | `->`  | `104x104` | `->`   | `104x104`   | `->`  | `13x104`        | `->`   | `13x8`  | `->`  | `13x2`    | `->`  | `13x1`      | `->`          | `1x1` |
| `W[c][b]`              | `104x104` | `->`  | `104x13`  | `->`   | `104x1`     | `->`  | `104x1`         | `->`   | `8x1`   | `->`  | `2x1`     | `->`  | `1x1`       | `->`          | `1x1` |
| `O[a][b]`              | `104x104` | `->`  | `104x13`  | `->`   | `104x1`     | `->`  | `13x1`          | `->`   | `13x1`  | `->`  | `13x1`    | `->`  | `13x1`      | `->`          | `1x1` |
| **RF** 992 bits        |           |       | 0         |        | 0           |       | 0               |        | 104     |       | 15        |       | 27          |               | 3     |
| **L1** 128000 bits     |           |       | 1352      |        | 10816 + 104 |       | 1352 + 104 + 13 |        | 21      |       | 26        |       | 0           |               | 0     |
| **L3 **2147483648 bits |           |       | 10816     |        | 104         |       | 0               |        | 0       |       | 0         |       | 0           |               | 0     |
| `I tile`               |           |       | 1         |        | 1           |       | 8,1             |        | 13,8,1  |       | 4,13,8,1  |       | 2,4,13,8,1  | 13,2,4,13,8,1 |       |
| `W tile`               |           |       | 8         |        | 13,8        |       | 13,8            |        | 13,13,8 |       | 4,13,13,8 |       | 2,4,13,13,8 | 2,4,13,13,8   |       |
| `O tile`               |           |       | 8         |        | 13, 8       |       | 8,13,8          |        | 8,13,8  |       | 8,13,8    |       | 8,13,8      | 13,8,13,8     |       |



## III. Manual Transformation

#### a. C-ish pseudocode transformed based on "host vs. accelerator" divide

Host:

```
// recall:  O[a][b]+=I[a][c]*W[c][b]
void dmaCore (Matrix_104x104 i, Matrix_104x104 w, Matrix_104x104 o,) {
    // loop bounds
    size_t B_S = 8;
    size_t B_0 = 13;

    // block sizes
    size_t b_s_bk_sz = 13;
    size_t b_0_bk_sz = 1;
    
	// assume i and w are already in L1, and o is in L3
    for (size_t b_s = 0; b_s < B_S; b_s++) {
        size_t start = b_s * b_s_bk_sz;
        
        Matrix_104_13 w_tile = subtile(w, start, 104x13);
        
        Matrix_104_13 o_tile = subtile(o, start, 104x13);
        
        for (size_t b_0 = 0; b_0 < B_0; b_0++) {
            size_t start = b_0 * b_0_bk_sz;
            Matrix_104_1 o_tile2 = subtile(o, start, 104x1)
            Matrix_104_1 w_tile2 = subtile(w, start, 104x1)	

            // copy o_tile from L3 to L1
            Matrix_104_13 o_tile_L1;
            copyFromL3(o_tile2, o_tile2_L1);

            // deploy rest of work on compute core with id b_s
            computeCore(i, w_tile2, o_tile2_L1, b_s);
            
            PROBLEM: core ID doesn't change over these 13 iterations!

            
    	}
    }
    
    // synchronization ???
    // copy results from each compute core back to L3
    for (size_t b_s = 0; b_s < B_S; b_s++) {
                
        // deploy rest of work on compute core with id b_s
		waitForComputeCore(b_s);
		
		// copy o_tile2 from L1 back to L3
		copyFromL1(o_tile2_L1, o_tile2);
    }
}
```

Accelerator:

```
// recall:  O[a][b]+=I[a][c]*W[c][b]
// this example does not differentiate between L1 and registers, 
// because will not model register level loads at this level, nor the MLIR level

void computeCore (Matrix_104x104 i, Matrix_104x1 w, Matrix_104x1 o, int coreID) {
	if (myCoreId() != coreID) { return; }
	
	// loop bounds
	size_t A_0 = 8;
    size_t C_0 = 13;
    size_t C_1 = 4;
    size_t C_2 = 2;
    size_t A_1 = 13;
    
	// loop blocks
	size_t a_0_bk_sz = 13;
	size_t c_0_bk_sz = 8;
	size_t c_1_bk_sz = 2;
	size_t c_2_bk_sz = 1;
	size_t a_1_bk_sz = 1;
	
	
        for (size_t a_0 = 0; a_0 < A_0; a_0++) {
            start = a_0 * a_0_bk_sz;
            Matrix_13_104 i_tile = subtile(i, start, 13x104);
            Matrix_13_1 o_tile_tile = subtile(o, start, 13x1);	
            
            for (size_t c_0 = 0; c_0 < C_0; c_0++) {
                start = c_0 * c_0_bk_sz;
                Matrix_13_8 i_tile_tile = subtile(i_tile, start, 13x8);
                Matrix_8_1 w_tile_tile = subtile(w, start, 8x1);
                
                for (size_t c_1 = 0; c_1 < C_1; c_1++) {
                	start = c_1 * c_1_bk_sz;
                	Matrix_13_2 i_tile_tile_tile = subtile(i_tile_tile, start, 13x2);
                	Matrix_2_1 w_tile_tile_tile - subtile(w_tile_tile, start, 2x1);
                	
                    for (size_t c_2 = 0; c_2 < C_2; c_2++) {
                    	start = c_2 * c_2_bk_sz;
                    	Matrix_13x1 i_tile_4 = subtile(i_tile_tile_tile, start, 13x1);
                    	Matrix_1_1 w_tile_4 = subtile(w_tile_tile_tile, start, 1x1);   
                        
                        for (size_t a_1 = 0; a_1 < A_1; a_1++) {
                        	start = a_1 * a_1_bk_sz;
                        	Matrix_1_1 i_tile_5 = subtile(i_tile_4, start, 1x1);
                        	Matrix_1_1 o_tile_3 = subtile(o_tile_tile, start, 1x1)
                        	o_tile_3 += (i_tile_5 * w_tile_4);
                        }
                    }
                }
            }
        }
	
}
```

#### c. MLIR transformed based on L1 - L3 split ("host" vs "accelerator" divide)

Host:

```
"func.func"() <{function_type = 
    (i32,                                             // coreID
    memref<104x104xi8, strided<[104, 1], offset: ?>>, // input L3
    memref<104x104xi8, strided<[1, 104], offset: ?>>,   // weight L3
    memref<104x104xi32, strided<[104, 1], offset: ?>>,  // output L3
    memref<104x104xi8, strided<[104,1], offset: ?>>,    // input slice L1
    memref<104x104xi8, strided<[1, 104], offset: ?>>,   // weight slice L1
    memref<104x104xi32, strided<[104, 1], offset: ?>>)  // output slice  L1
    -> (), sym_name = "tiledMatmul12"}> ({
  ^bb0(%coreID : i32,
       %arg0: memref<104x104xi8, strided<[104, 1], offset: ?>>, 
       %arg1: memref<104x104xi8, strided<[1,104], offset: ?>>, 
       %arg2: memref<104x104xi32, strided<[104,1], offset: ?>>, 
       %inputL1: memref<104x104xi8, strided<[104,1], offset: ?>>,
       %weightL1: memref<104x104xi8, strided<[1,104], offset: ?>>,
       %outputL1: memref<104x104xi32, strided<[104,1], offset: ?>>): 

       // we start by moving the Input and Weight operands into L1:
      func.call @memrefCopy8bit_I_104x104(%arg0,  %inputL1) 
      : (memref<104x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[104, 1], offset: ?>>) -> ()
       func.call @memrefCopy8bit_W_104x104(%arg1,  %weightL1) 
      : (memref<104x104xi8, strided<[1,104], offset: ?>>, memref<104x104xi8, strided<[1,104], offset: ?>>) -> ()
      
        // indices
      %zero = arith.constant 0 : index
      %one = arith.constant 1: index
      %eight = arith.constant 8 : index
      %thirteen = arith.constant 13 : index  
      %oneOhFour = arith.constant 104 : index
  
      %b0_0_bk_sz = arith.constant 13 : index
      //%b1_0_bk_sz = arith.constant 8: index
    
      // constants
      %zero_i32 = arith.constant 0: i32
      %sixTwentyFour_i32 = arith.constant 624: i32
      %one_i32 = arith.constant 1 : i32
       %three_i8 = arith.constant 3 : i8

    // enter scf FOR LOOP
    // select slices of W and O with dimensions (104 x 13)
    scf.for %b0_0 = %zero to %eight step %one iter_args() -> () { // this loop uses both L3 and L1    
    %b0 = arith.muli %b0_0, %b0_0_bk_sz : index   
    // Weight Operand
    // slice of L1 Weight @(104x13)
    %sliceWL1 = memref.subview %weightL1[%zero, %zero][104,13][1,1] 
    :  memref<104x104xi8, strided<[1,104], offset: ?>> to memref<104x13xi8, strided<[1, 104], offset: ?>>
    // Output Operand 
    // slice of L3 Output @(104x13)
    %sliceOL3 = memref.subview %arg2[%zero, %b0][104,13][1,1] 
    : memref<104x104xi32, strided<[104,1], offset: ?>> to memref<104x13xi32, strided<[104, 1], offset: ?>>
    // slice of L1 Output @(104x13)
    %sliceOL1 = memref.subview %outputL1[%zero,%zero][104,13][1,1]
    : memref<104x104xi32, strided<[104,1], offset: ?>> to memref<104x13xi32, strided<[104,1], offset: ?>>

    // enter scf FOR LOOP
    // select slices of W and O with dimensions (104x1) 
    scf.for %b1_0 = %zero to %thirteen step %one iter_args() -> () { // this loop uses both L3 and L1
    // Weight Operand
    // slice of L1 Weight @(104x1)
    %sliceWL1_2 = memref.subview %sliceWL1[%zero,%b1_0][104,1][1,1]
    : memref<104x13xi8, strided<[1, 104], offset: ?>> to memref<104x1xi8, strided<[1, 104], offset: ?>>     
    // Output Operand    
    // slice of slice of L3 Output @(104x1)
    %sliceOL3_2 = memref.subview %sliceOL3[%zero, %b1_0][104,1][1,1] 
    :  memref<104x13xi32, strided<[104, 1], offset: ?>> to memref<104x1xi32, strided<[104, 1], offset: ?>>
    // slice of L1 output @(104x1)
    %sliceOL1_2 = memref.subview %sliceOL1[%zero, %b1_0][104,1][1,1]
    : memref<104x13xi32, strided<[104, 1], offset: ?>> to memref<104x1xi32, strided<[104, 1], offset: ?>>
    // We copy this slice of operand Output from L3 to L1
    func.call @memrefCopy32bit_O_104x1(%sliceOL3_2, %sliceOL1_2) : 
    (memref<104x1xi32, strided<[104, 1], offset: ?>>, memref<104x1xi32, strided<[104, 1], offset: ?>>) -> ()

    // Now that all the slices are in L1, give the rest of the work to a core
    func.call @dispatch_to_accelerator(%coreID, %inputL1, %sliceWL1_2, %sliceOL1_2)
    : (
    i32, // coreID
    memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
    memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<104x1xi32, strided<[104, 1], offset: ?>>)  // output slice
    -> ()

    func.call @wait_for_accelerator(%coreID) : (i32) -> ()

    // We copy L1 Output back to L3
    func.call @memrefCopy32bit_O_104x1(%sliceOL1_2, %sliceOL3_2) : 
    (memref<104x1xi32, strided<[104, 1], offset: ?>>, memref<104x1xi32, strided<[104, 1], offset: ?>>) -> ()

    // zero-out the Output L1 slice; there has to be a better way to do this, right?
    scf.for %i = %zero to %oneOhFour step %one iter_args() -> () { 
     memref.store %zero_i32, %sliceOL1_2[%i, %zero] : memref<104x1xi32, strided<[104, 1], offset: ?>>
    } // end of %i for
    } // end of b1_0 for
    } // end of b0_0 for
  "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()
```

Accelerator:

```
 // computation performed by accelerator as part of tiled matmul
  "func.func"() <{function_type = (
    memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
    memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<104x1xi32, strided<[104, 1], offset: ?>>)  // output slice
    -> (), sym_name = "tiledMatmul12_kernel"}> ({
  ^bb0(
    %arg0: memref<104x104xi8, strided<[104, 1], offset: ?>>, 
    %arg1: memref<104x1xi8, strided<[1, 104], offset: ?>>, 
    %arg2: memref<104x1xi32, strided<[104, 1], offset: ?>>):

    // indices
    %zero = arith.constant 0 : index
    %one = arith.constant 1 : index
    %oneOhFour = arith.constant 104 : index
    %eight = arith.constant 8 : index
    %thirteen = arith.constant 13 : index
    %four = arith.constant 4 : index
    %two = arith.constant 2 : index

    // integers
    %sixTwentyFour_i32 = arith.constant 624: i32
    %zero_i32 = arith.constant 0: i32

    // tile sizes
    %a0_bk_sz = arith.constant 13 : index
    %c0_bk_sz = arith.constant 8 : index
    %c1_bk_sz = arith.constant 2 : index
    %c2_bk_sz = arith.constant 1 : index
    %a1_bk_sz = arith.constant 1 : index

    // ignore register level tiling for now
    scf.for %a0 = %zero to %eight step %one iter_args() -> () { 
      scf.for %c0 = %zero to %thirteen step %one iter_args() -> () {
        scf.for %c1 = %zero to %four step %one iter_args() -> () { 
          scf.for %c2 = %zero to %two step %one iter_args() -> () { 
            scf.for %a1 = %zero to %thirteen step %one iter_args() -> () { 
              %prod_a0 = arith.muli %a0, %a0_bk_sz : index
              %prod_c0 = arith.muli %c0, %c0_bk_sz : index
              %prod_c1 = arith.muli %c1, %c1_bk_sz : index
              %prod_c2 = arith.muli %c2, %c2_bk_sz : index
              %prod_a1 = arith.muli %a1, %a1_bk_sz : index
              %sum_c_0_1 = arith.addi %prod_c0, %prod_c1 : index
              %a = arith.addi %prod_a0, %prod_a1 : index 
              %c = arith.addi %sum_c_0_1, %prod_c2 : index

              // recall:  O[a][b]+=I[a][c]*W[c][b]

              %inputElt = memref.load %arg0[%a, %c] : memref<104x104xi8, strided<[104, 1], offset: ?>>
              %inputEltCasted = arith.extsi  %inputElt : i8 to i32 

              %weightElt = memref.load %arg1[%c, %zero] : memref<104x1xi8, strided<[1, 104], offset: ?>>
              %weightEltCasted = arith.extsi  %weightElt : i8 to i32 

              %outputElt = memref.load %arg2[%a, %zero] : memref<104x1xi32, strided<[104, 1], offset: ?>>
              
              %prod = arith.muli %inputEltCasted, %weightEltCasted : i32
              %newOutputElt = arith.addi %prod, %outputElt : i32

              memref.store %newOutputElt, %arg2[%a, %zero] : memref<104x1xi32, strided<[104, 1], offset: ?>>
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
sh zigzag-spike-build-and-run.sh tiledMatmul12.mlir
```

verilator:

```
sh zigzag-verilator-build-and-run.sh tiledMatmul12.mlir
```

