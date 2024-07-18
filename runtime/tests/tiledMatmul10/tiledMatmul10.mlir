#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({

// declaring external MLIR functions (implementations in C)
"func.func"() <{function_type = (i32, memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1,104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type =  (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> (), sym_name = "hola", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type =  (memref<8x104xi32, strided<[104, 1], offset: ?>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "memrefCopy32bit", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = (
    i32) // coreID
    -> (), sym_name = "wait_for_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
    
// perform tiled matrix multiplication,
// dispatching part of the work to the accelerator!
  "func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104,1]>>, memref<104x104xi32, strided<[104,1]>>) -> (), sym_name = "tiled_matmul"}> ({
  ^bb0(%arg0: memref<104x104xi8>, %arg1: memref<104x104xi8, strided<[1,104]>>, %arg2: memref<104x104xi32, strided<[104,1]>>, %l1OSlice: memref<104x104xi32, strided<[104,1]>>):
    // indices
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %eight = arith.constant 8 : index
    %thirteen = arith.constant 13 : index  
    %oneOhFour = arith.constant 104 : index
    %d0_1_bk_sz = arith.constant 8 : index
    // constants
    %zero_i32 = arith.constant 0: i32
    %five_i32 = arith.constant 0: i32

    // enter scf FOR LOOP
    scf.for %d0_1 = %zero to %thirteen step %one iter_args() -> () { // this loop uses both L3 and L1

    %d0 = arith.muli %d0_1, %d0_1_bk_sz : index
	
	  // select a slice of output space on L3
    %outputTileL3 = memref.subview %arg2[%d0,%zero][8,104][1,1] 
    :  memref<104x104xi32, strided<[104,1]>> to memref<8x104xi32, strided<[104, 1], offset: ?>>

    // select a corresponding slice of output space on L1
    %outputTileL1 = memref.subview %l1OSlice[%zero,%zero][8,104][1,1] 
    :  memref<104x104xi32, strided<[104,1]>> to memref<8x104xi32, strided<[104, 1], offset: ?>>
    	
	  // select a slice of input data from L1
    %inputTile = memref.subview %arg0[%d0,%zero][8,104][1,1] 
    : memref<104x104xi8> to memref<8x104xi8, strided<[104, 1], offset: ?>>

    // dispatch mini matmul to accelerator
    func.call @dispatch_to_accelerator(%five_i32, %inputTile, %arg1, %outputTileL1) 
    : (i32, memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1,104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> ()

    func.call @wait_for_accelerator(%five_i32) : (i32) -> ()

    // memref.copy %outputTileL1, %outputTileL3 : memref<8x104xi32, strided<[104, 1], offset: ?>> to memref<8x104xi32, strided<[104, 1], offset: ?>>   
    func.call @memrefCopy32bit(%outputTileL1, %outputTileL3) : 
    (memref<8x104xi32, strided<[104, 1], offset: ?>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> ()

    // zero-out the L1 slice; there has to be a better way to do this, right?
    scf.for %i = %zero to %eight step %one iter_args() -> () { 
    scf.for %j = %zero to %oneOhFour step %one iter_args() -> () { 
     memref.store %zero_i32, %outputTileL1[%i, %j] :memref<8x104xi32, strided<[104, 1], offset: ?>>
    } // end of %i for
    } // end of %j for
    } // end of d0_1 for
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()


  // computation performed by accelerator as part of tiled matmul
  "func.func"() <{function_type = (memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1, 104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "matmul_accelerator_work"}> ({
  ^bb0(
    %arg0: memref<8x104xi8, strided<[104, 1], offset: ?>>, 
    %arg1: memref<104x104xi8, strided<[1,104]>>, 
    %arg2: memref<8x104xi32, strided<[104, 1], offset: ?>>):
    // tile sizes
    %d1_1_bk_sz = arith.constant 8 : index
    %d2_1_bk_sz = arith.constant 8 : index
    
    // indices
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %eight = arith.constant 8 : index
    %thirteen = arith.constant 13 : index

    // all the following inner loops should be executed on the accelerator
    scf.for %d1_1 = %zero to %thirteen step %one iter_args() -> () {  
    scf.for %d2_1 = %zero to %thirteen step %one iter_args () -> () {
    // the inner 3 loops will be spatially unrolled on the accelerator
    scf.for %d0_2 = %zero to %eight step %one iter_args() -> () {       
    scf.for %d1_2 = %zero to %eight step %one iter_args () -> () { 
    scf.for %d2_2 = %zero to %eight step %one iter_args () -> () {
     // %prod0 = arith.muli %d0_1, %d0_1_bk_sz : index
      %prod0 = arith.constant 0 : index
      %d0 = arith.addi %prod0, %d0_2 : index

      %prod1 = arith.muli %d1_1, %d1_1_bk_sz : index
      %d1 = arith.addi %prod1, %d1_2 : index

      %prod2 = arith.muli %d2_1, %d2_1_bk_sz : index
      %d2 = arith.addi %prod2, %d2_2 : index

      %inputElt = memref.load %arg0[%d0, %d2] : memref<8x104xi8, strided<[104, 1], offset: ?>>
      %inputEltCasted = arith.extsi  %inputElt : i8 to i32 
      
      %weightElt = memref.load %arg1[%d2, %d1] : memref<104x104xi8, strided<[1,104]>>
      %weightEltCasted = arith.extsi  %weightElt : i8 to i32 

      %outputElt = memref.load %arg2[%d0, %d1] : memref<8x104xi32, strided<[104, 1], offset: ?>>
      %prod = arith.muli %inputEltCasted, %weightEltCasted : i32

      %newOutputElt = arith.addi %prod, %outputElt : i32 
      memref.store %newOutputElt, %arg2[%d0, %d1] :memref<8x104xi32, strided<[104, 1], offset: ?>>

    } // end of d2_2 for
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