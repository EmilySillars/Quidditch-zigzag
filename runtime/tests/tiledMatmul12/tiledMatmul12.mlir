#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({
// declaring external MLIR functions (implementations in C)
"func.func"() <{function_type = (
    i32) // coreID
    -> (), sym_name = "wait_for_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = () -> (), sym_name = "wait_for_all_accelerators", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = (i32, i32,i32,i32,i32,i32,i32,i32) 
    -> (), sym_name = "save_outer_loop_counters", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = (
    i32, // coreID
    memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
    memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<104x1xi32, strided<[104, 1], offset: ?>>)  // output slice
    -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type =  (
  memref<2x16xi8>, 
  memref<16x2xi8, strided<[1,16]>>, 
  memref<2x2xi32, strided<[16,1]>>) 
  -> (), sym_name = "hola", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = (
  memref<104x13xi8, strided<[1, 104], offset: ?>>, 
  memref<104x13xi8, strided<[1, 104], offset: ?>>) 
  -> (), sym_name = "memrefCopy8bit", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

"func.func"() <{function_type = (
  memref<104x104xi8, strided<[104, 1], offset: ?>>, 
  memref<104x104xi8, strided<[104, 1], offset: ?>>) 
  -> (), sym_name = "memrefCopy8bit_I_104x104", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = (
  memref<104x104xi8, strided<[1, 104], offset: ?>>, 
  memref<104x104xi8, strided<[1, 104], offset: ?>>) 
  -> (), sym_name = "memrefCopy8bit_W_104x104", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

"func.func"() <{function_type = (
  memref<104x1xi32, strided<[104, 1], offset: ?>>, 
  memref<104x1xi32, strided<[104, 1], offset: ?>>) 
  -> (), sym_name = "memrefCopy32bit", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

"func.func"() <{function_type = (
  memref<104x13xi32, strided<[104, 1], offset: ?>>, 
  memref<104x13xi32, strided<[104, 1], offset: ?>>) 
  -> (), sym_name = "memrefCopy32bit_O_104x13", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()


"func.func"() <{function_type = (
  memref<104x1xi32, strided<[104, 1], offset: ?>>, 
  memref<104x1xi32, strided<[104, 1], offset: ?>>) 
  -> (), sym_name = "memrefCopy32bit_O_104x1", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()


"func.func"() <{function_type = 
    (i32,                                               // coreID
    memref<104x104xi8, strided<[104, 1], offset: ?>>,   // input L3
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

    // tell core where we are in the outer for loops
    func.call @save_outer_loop_counters(%zero_i32,%zero_i32,%zero_i32,%zero_i32,%zero_i32,%zero_i32,%zero_i32,%zero_i32)
    : (i32, i32,i32,i32,i32,i32,i32,i32) -> ()

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


// computation performed by accelerator as part of tiled matmul
  "func.func"() <{function_type = (
    memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
    memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<104x1xi32, strided<[104, 1], offset: ?>>,
    i32, i32,i32,i32,i32,i32,i32,i32)  // output slice
    -> (), sym_name = "tiledMatmul12_kernel"}> ({
  ^bb0(
    %arg0: memref<104x104xi8, strided<[104, 1], offset: ?>>, 
    %arg1: memref<104x1xi8, strided<[1, 104], offset: ?>>, 
    %arg2: memref<104x1xi32, strided<[104, 1], offset: ?>>,
    %counter_0 : i32, 
    %counter_1 : i32, 
    %counter_2 : i32, 
    %counter_3 : i32, 
    %counter_4 : i32, 
    %counter_5 : i32, 
    %counter_6 : i32, 
    %counter_7 : i32
    ):

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

"func.func"() <{function_type = 
    (i32,                                               // coreID
    memref<104x104xi8, strided<[104, 1], offset: ?>>,   // input L3
    memref<104x104xi8, strided<[1, 104], offset: ?>>,   // weight L3
    memref<104x104xi32, strided<[104, 1], offset: ?>>,  // output L3
    memref<104x104xi8, strided<[104,1], offset: ?>>,    // input slice L1
    memref<104x104xi8, strided<[1, 104], offset: ?>>,   // weight slice L1
    memref<104x104xi32, strided<[104, 1], offset: ?>>)  // output slice  L1
    -> (), sym_name = "dmaCore"}> ({
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

    // tell core where we are in the outer for loops
    func.call @save_outer_loop_counters(%zero_i32,%zero_i32,%zero_i32,%zero_i32,%zero_i32,%zero_i32,%zero_i32,%zero_i32)
    : (i32, i32,i32,i32,i32,i32,i32,i32) -> ()

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


// computation performed by accelerator as part of tiled matmul
  "func.func"() <{function_type = (
    memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
    memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<104x1xi32, strided<[104, 1], offset: ?>>,
    i32, i32,i32,i32,i32,i32,i32,i32)  // output slice
    -> (), sym_name = "computeCore"}> ({
  ^bb0(
    %arg0: memref<104x104xi8, strided<[104, 1], offset: ?>>, 
    %arg1: memref<104x1xi8, strided<[1, 104], offset: ?>>, 
    %arg2: memref<104x1xi32, strided<[104, 1], offset: ?>>,
    %a1_c : i32, 
    %b1_c : i32, 
    %c1_c : i32, 
    %c2_c : i32, 
    %a1_bk_sz_c : i32, 
    %b1_bk_sz_c : i32, 
    %c1_bk_sz_c : i32, 
    %c2_bk_sz_c : i32
    ):

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



}) : () -> ()