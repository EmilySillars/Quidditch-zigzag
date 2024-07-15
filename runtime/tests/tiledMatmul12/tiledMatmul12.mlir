#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({

// declaring external MLIR functions (implementations in C)
"func.func"() <{function_type = (
    i32, // coreID
    memref<104x104xi8, strided<[104,1]>>, // input
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
"func.func"() <{function_type = (memref<104x1xi32, strided<[104, 1], offset: ?>>, memref<104x1xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "memrefCopy32bit", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()


// perform tiled matrix multiplication,
// dispatching part of the work to the accelerator!
  "func.func"() <{function_type = 
  (memref<104x104xi8, strided<[104,1]>>,     // arg0 (input)
   memref<104x104xi8, strided<[1,104]>>,     // arg1 (weight)
   memref<104x104xi32, strided<[104,1]>>,    // arg2 (output)
   memref<104x104xi32, strided<[104,1]>>,    // arg3 (input space on l1)
   memref<104x104xi8, strided<[1,104]>>,     // arg4 (weight space on l1)
   memref<104x104xi32, strided<[104,1]>>     // arg3 (output space on l1)
  ) -> (), sym_name = "tiledMatmul12"}> ({
  ^bb0(%arg0: memref<104x104xi8, strided<[104,1]>>, 
       %arg1: memref<104x104xi8, strided<[1,104]>>, 
       %arg2: memref<104x104xi32, strided<[104,1]>>, 
       %inputL1: memref<104x104xi8, strided<[104,1]>>,
       %weightL1: memref<104x104xi8, strided<[1,104]>>,
       %outputL1: memref<104x104xi32, strided<[104,1]>>):
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

    // enter scf FOR LOOP
    // select vertical slices of O and W with dimensions (104 x 13)
    scf.for %b0_0 = %zero to %eight step %one iter_args() -> () { // this loop uses both L3 and L1    
    %b0 = arith.muli %b0_0, %b0_0_bk_sz : index   

    // Output Operand 
    // slice of L3 Output @(104x13)
    %verticalSliceOL3 = memref.subview %arg2[%zero, %b0][104,13][1,1] 
    :  memref<104x104xi32, strided<[104,1]>> to memref<104x13xi32, strided<[104, 1], offset: ?>>
    // slice of L1 Output @(104x13)
    %verticalSliceOL1 = memref.subview %outputL1[%zero,%zero][104,13][1,1]
    : memref<104x104xi32, strided<[104,1]>> to memref<104x13xi32, strided<[104,1], offset: ?>>

    // Weight Operand
    // slice of L3 Weight @(104x13)
    %verticalSliceWL3 = memref.subview %arg1[%zero, %b0][104,13][1,1] 
    :  memref<104x104xi8, strided<[1, 104]>> to memref<104x13xi8, strided<[1, 104], offset: ?>>
    // slice of L1 Weight @(104x13)
    %verticalSliceWL1 = memref.subview %weightL1[%zero, %zero][104,13][1,1] 
    :  memref<104x104xi8, strided<[1, 104]>> to memref<104x13xi8, strided<[1, 104], offset: ?>>
    // copy L3 Weight to L1
    func.call @memrefCopy8bit(%verticalSliceWL3,  %verticalSliceWL1) 
    : (memref<104x13xi8, strided<[1, 104], offset: ?>>, memref<104x13xi8, strided<[1, 104], offset: ?>>) -> ()
    
    // enter scf FOR LOOP
    // select vertical slices of each of O and W's vertical slices with dimensions (104x1) 
    scf.for %b1_0 = %zero to %thirteen step %one iter_args() -> () { // this loop uses both L3 and L1
        
    // slice of slice of L3 Output @(104x1)
    %vSliceOL3 = memref.subview %verticalSliceOL3[%zero, %b1_0][104,1][1,1] 
    :  memref<104x13xi32, strided<[104, 1], offset: ?>> to memref<104x1xi32, strided<[104, 1], offset: ?>>
    // slice of L1 output @(104x1)
    %vSliceOL1 = memref.subview %verticalSliceOL1[%zero, %b1_0][104,1][1,1]
    : memref<104x13xi32, strided<[104, 1], offset: ?>> to memref<104x1xi32, strided<[104, 1], offset: ?>>
    // copy L3 Output to L1
    func.call @memrefCopy32bit(%vSliceOL3,%vSliceOL1) : 
    (memref<104x1xi32, strided<[104, 1], offset: ?>>, memref<104x1xi32, strided<[104, 1], offset: ?>>) -> ()
    
    // slice of L1 Weight @(104x1)
    %vSliceWL1 = memref.subview %verticalSliceWL1[%zero,%b1_0][104,1][1,1]
    : memref<104x13xi8, strided<[1, 104], offset: ?>> to memref<104x1xi8, strided<[1, 104], offset: ?>> 

    func.call @dispatch_to_accelerator(%zero_i32, %arg0, %vSliceWL1, %vSliceOL1)
    : (
    i32, // coreID
    memref<104x104xi8, strided<[104,1]>>, // input
    memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<104x1xi32, strided<[104, 1], offset: ?>>)  // output slice
    -> ()

    // copy Output L1 back to L3
    func.call @memrefCopy32bit(%vSliceOL1,%vSliceOL3) : 
    (memref<104x1xi32, strided<[104, 1], offset: ?>>, memref<104x1xi32, strided<[104, 1], offset: ?>>) -> ()
    
    // zero-out the Output L1 slice; there has to be a better way to do this, right?
    scf.for %i = %zero to %oneOhFour step %one iter_args() -> () { 
     memref.store %zero_i32, %vSliceOL1[%i, %zero] : memref<104x1xi32, strided<[104, 1], offset: ?>>
    } // end of %i for

    } // end of b1_0 for
    } // end of b0_0 for
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()

// perform tiled matrix multiplication,
// dispatching part of the work to the accelerator!
  "func.func"() <{function_type = 
  (memref<104x104xi8>,                        // arg0 (input)
   memref<104x104xi8, strided<[1, 104]>>,     // arg1 (weight)
   memref<104x104xi32, strided<[104,1]>>,     // arg2 (output)
   memref<104x104xi32, strided<[104,1]>>,     // arg3 (output space on l1)
   memref<104x104xi8, strided<[1, 104]>>      // arg4 (weight space on l1)
  ) -> (), sym_name = "pineapple"}> ({
  ^bb0(%arg0: memref<104x104xi8>, 
       %arg1: memref<104x104xi8, strided<[1,104]>>, 
       %arg2: memref<104x104xi32, strided<[104,1]>>, 
       %outputL1: memref<104x104xi32, strided<[104,1]>>,
       %weightL1: memref<104x104xi8, strided<[1,104]>>): 

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

    // enter scf FOR LOOP
    // select vertical slices of O and W with dimensions (104 x 13)
    scf.for %b0_0 = %zero to %eight step %one iter_args() -> () { // this loop uses both L3 and L1    
    %b0 = arith.muli %b0_0, %b0_0_bk_sz : index   

    // Output Operand 
    // slice of L3 Output @(104x13)
    %verticalSliceOL3 = memref.subview %arg2[%zero, %b0][104,13][1,1] 
    :  memref<104x104xi32, strided<[104,1]>> to memref<104x13xi32, strided<[104, 1], offset: ?>>
    // slice of L1 Output @(104x13)
    %verticalSliceOL1 = memref.subview %outputL1[%zero,%zero][104,13][1,1]
    : memref<104x104xi32, strided<[104,1]>> to memref<104x13xi32, strided<[104,1], offset: ?>>

    // Weight Operand
    // slice of L3 Weight @(104x13)
    %verticalSliceWL3 = memref.subview %arg1[%zero, %b0][104,13][1,1] 
    :  memref<104x104xi8, strided<[1, 104]>> to memref<104x13xi8, strided<[1, 104], offset: ?>>
    // slice of L1 Weight @(104x13)
    %verticalSliceWL1 = memref.subview %weightL1[%zero, %zero][104,13][1,1] 
    :  memref<104x104xi8, strided<[1, 104]>> to memref<104x13xi8, strided<[1, 104], offset: ?>>
    // copy L3 Weight to L1
    func.call @memrefCopy8bit(%verticalSliceWL3,  %verticalSliceWL1) 
    : (memref<104x13xi8, strided<[1, 104], offset: ?>>, memref<104x13xi8, strided<[1, 104], offset: ?>>) -> ()
    
    // enter scf FOR LOOP
    // select vertical slices of each of O and W's vertical slices with dimensions (104x1) 
    scf.for %b1_0 = %zero to %thirteen step %one iter_args() -> () { // this loop uses both L3 and L1
        
    // slice of slice of L3 Output @(104x1)
    %vSliceOL3 = memref.subview %verticalSliceOL3[%zero, %b1_0][104,1][1,1] 
    :  memref<104x13xi32, strided<[104, 1], offset: ?>> to memref<104x1xi32, strided<[104, 1], offset: ?>>
    // slice of L1 output @(104x1)
    %vSliceOL1 = memref.subview %verticalSliceOL1[%zero, %b1_0][104,1][1,1]
    : memref<104x13xi32, strided<[104, 1], offset: ?>> to memref<104x1xi32, strided<[104, 1], offset: ?>>
    // copy L3 Output to L1
    func.call @memrefCopy32bit(%vSliceOL3,%vSliceOL1) : 
    (memref<104x1xi32, strided<[104, 1], offset: ?>>, memref<104x1xi32, strided<[104, 1], offset: ?>>) -> ()
    
    // slice of L1 Weight @(104x1)
    %vSliceWL1 = memref.subview %verticalSliceWL1[%zero,%b1_0][104,1][1,1]
    : memref<104x13xi8, strided<[1, 104], offset: ?>> to memref<104x1xi8, strided<[1, 104], offset: ?>> 

    func.call @dispatch_to_accelerator(%zero_i32, %arg0, %vSliceWL1, %vSliceOL1)
    : (
    i32, // coreID
    memref<104x104xi8>, // input
    memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<104x1xi32, strided<[104, 1], offset: ?>>)  // output slice
    -> ()

    // copy Output L1 back to L3
    func.call @memrefCopy32bit(%vSliceOL1,%vSliceOL3) : 
    (memref<104x1xi32, strided<[104, 1], offset: ?>>, memref<104x1xi32, strided<[104, 1], offset: ?>>) -> ()
    
    // zero-out the Output L1 slice; there has to be a better way to do this, right?
    scf.for %i = %zero to %oneOhFour step %one iter_args() -> () { 
     memref.store %zero_i32, %vSliceOL1[%i, %zero] : memref<104x1xi32, strided<[104, 1], offset: ?>>
    } // end of %i for

    } // end of b1_0 for
    } // end of b0_0 for
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()

  // computation performed by accelerator as part of tiled matmul
  "func.func"() <{function_type = (
    memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
    memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<104x1xi32, strided<[104, 1], offset: ?>>)  // output slice
    -> (), sym_name = "kernel_tiledMatmul12"}> ({
  ^bb0(
    %arg0: memref<104x104xi8, strided<[104, 1], offset: ?>>, 
    %arg1: memref<104x1xi8, strided<[1, 104], offset: ?>>, 
    %arg2: memref<104x1xi32, strided<[104, 1], offset: ?>>):

    // tile sizes
    %a0_0_bk_sz = arith.constant 13 : index
    %c0_0_bk_sz = arith.constant 8 : index
    
    // indices
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %eight = arith.constant 8 : index
    %thirteen = arith.constant 13 : index

    //constants
    %sixTwentyFour_i32 = arith.constant 624: i32
    %one_i32 = arith.constant 1 : i32

    // all the following inner loops should be executed on the accelerator
    scf.for %a0_0 = %zero to %eight step %one iter_args() -> () {  
    scf.for %c0_0 = %zero to %thirteen step %one iter_args () -> () {
    scf.for %c1_0 = %zero to %eight step %one iter_args() -> () {       
    scf.for %a1_0 = %zero to %thirteen step %one iter_args () -> () { 
      
      %prod0 = arith.muli %a0_0, %a0_0_bk_sz : index
      %a0 = arith.addi %prod0, %a1_0 : index

      %b0 = arith.constant 0 : index

      %prod1 = arith.muli %c0_0, %c0_0_bk_sz : index
      %c0 = arith.addi %prod1, %c1_0 : index

      // O[a][b]+=I[a][c]*W[c][b]
     
      %inputElt = memref.load %arg0[%a0, %c0] : memref<104x104xi8, strided<[104, 1], offset: ?>>
      %inputEltCasted = arith.extsi  %inputElt : i8 to i32 
      
      %weightElt = memref.load %arg1[%c0, %b0] : memref<104x1xi8, strided<[1, 104], offset: ?>>
      %weightEltCasted = arith.extsi  %weightElt : i8 to i32 

      %outputElt = memref.load %arg2[%a0, %b0] : memref<104x1xi32, strided<[104, 1], offset: ?>>
      %prod = arith.muli %inputEltCasted, %weightEltCasted : i32
      
      %newOutputElt = arith.addi %prod, %outputElt : i32 
      memref.store %newOutputElt, %arg2[%a0, %b0] : memref<104x1xi32, strided<[104, 1], offset: ?>> 
    } // end of d1_2 for
    } // end of d0_2 for
    } // end of d2_1 for
    } // end of d1_1 for
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()




// DUMMY KERNEL THAT ALWAYS RETURNS CORRECT SQUARE MATMUL ANSWER
  "func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104,1]>>, memref<104x104xi32, strided<[104,1]>>) -> (), sym_name = "dummy"}> ({
  ^bb0(%arg0: memref<104x104xi8>, %arg1: memref<104x104xi8, strided<[1,104]>>, %arg2: memref<104x104xi32, strided<[104,1]>>, %l1OSlice: memref<104x104xi32, strided<[104,1]>>):
    // tile sizes
    %d0_1_bk_sz = arith.constant 8 : index
    %d1_1_bk_sz = arith.constant 8 : index
    %d2_1_bk_sz = arith.constant 8 : index
    
    // indices
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %eight = arith.constant 8 : index
    %thirteen = arith.constant 13 : index

    // enter scf nested FOR LOOP
    scf.for %d0_1 = %zero to %thirteen step %one iter_args() -> () { // this loop uses both L3 and L1

    %outputTile = memref.subview %arg2[%d0_1,%zero][8,104][1,1] :  memref<104x104xi32, strided<[104,1]>> to memref<8x104xi32, strided<[104, 1], offset: ?>>

    %inputTile = memref.subview %arg0[%d0_1,%zero][8,104][1,1] : memref<104x104xi8> to memref<8x104xi8, strided<[104, 1], offset: ?>>

    // weight operand unchanged

    // all the following inner loops should be executed on the accelerator
    scf.for %d1_1 = %zero to %thirteen step %one iter_args() -> () {  
    scf.for %d2_1 = %zero to %thirteen step %one iter_args () -> () {
    // the inner 3 loops will be spatially unrolled on the accelerator
    scf.for %d0_2 = %zero to %eight step %one iter_args() -> () {       
    scf.for %d1_2 = %zero to %eight step %one iter_args () -> () { 
    scf.for %d2_2 = %zero to %eight step %one iter_args () -> () {
      %prod0 = arith.muli %d0_1, %d0_1_bk_sz : index
      %d0 = arith.addi %prod0, %d0_2 : index

      %prod1 = arith.muli %d1_1, %d1_1_bk_sz : index
      %d1 = arith.addi %prod1, %d1_2 : index

      %prod2 = arith.muli %d2_1, %d2_1_bk_sz : index
      %d2 = arith.addi %prod2, %d2_2 : index

      %inputElt = memref.load %arg0[%d0, %d2] : memref<104x104xi8>
      %inputEltCasted = arith.extsi  %inputElt : i8 to i32 
      
      %weightElt = memref.load %arg1[%d2, %d1] : memref<104x104xi8, strided<[1,104]>>
      %weightEltCasted = arith.extsi  %weightElt : i8 to i32 

      %outputElt = memref.load %arg2[%d0, %d1] : memref<104x104xi32, strided<[104,1]>> 
      %prod = arith.muli %inputEltCasted, %weightEltCasted : i32

      %newOutputElt = arith.addi %prod, %outputElt : i32 
      memref.store %newOutputElt, %arg2[%d0, %d1] : memref<104x104xi32, strided<[104,1]>>

    } // end of d2_2 for
    } // end of d1_2 for
    } // end of d0_2 for
    } // end of d2_1 for
    } // end of d1_1 for
    } // end of d0_1 for
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()

// regular matmul
"func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32>) -> (), sym_name = "kernel_matmul"}> ({
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
  }) {llvm.emit_c_interface}: () -> ()

}) : () -> ()