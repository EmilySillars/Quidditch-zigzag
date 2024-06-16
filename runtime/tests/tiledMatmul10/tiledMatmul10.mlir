#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({

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


  "func.func"() <{function_type =  (memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1, 104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "sendWorkToAccelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()  

  // "func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104,1]>>) -> (), sym_name = "tiled_matmul"}> ({
  // ^bb0(%arg0: memref<104x104xi8>, %arg1: memref<104x104xi8, strided<[1,104]>>, %arg2: memref<104x104xi32, strided<[104,1]>>):
  //   // tile sizes
  //   %d0_1_bk_sz = arith.constant 8 : index
  //   %d1_1_bk_sz = arith.constant 8 : index
  //   %d2_1_bk_sz = arith.constant 8 : index
    
  //   // indices
  //   %zero = arith.constant 0 : index
  //   %one = arith.constant 1: index
  //   %eight = arith.constant 8 : index
  //   %thirteen = arith.constant 13 : index

  //   // enter scf nested FOR LOOP
  //   scf.for %d0_1 = %zero to %thirteen step %one iter_args() -> () {
  //   scf.for %d1_1 = %zero to %thirteen step %one iter_args() -> () {  
  //   scf.for %d2_1 = %zero to %thirteen step %one iter_args () -> () {
  //   scf.for %d0_2 = %zero to %eight step %one iter_args() -> () {       
  //   scf.for %d1_2 = %zero to %eight step %one iter_args () -> () { 
  //   scf.for %d2_2 = %zero to %eight step %one iter_args () -> () {
  //     %prod0 = arith.muli %d0_1, %d0_1_bk_sz : index
  //     %d0 = arith.addi %prod0, %d0_2 : index

  //     %prod1 = arith.muli %d1_1, %d1_1_bk_sz : index
  //     %d1 = arith.addi %prod1, %d1_2 : index

  //     %prod2 = arith.muli %d2_1, %d2_1_bk_sz : index
  //     %d2 = arith.addi %prod2, %d2_2 : index

  //     %inputElt = memref.load %arg0[%d0, %d2] : memref<104x104xi8>
  //     %inputEltCasted = arith.extsi  %inputElt : i8 to i32 
      
  //     %weightElt = memref.load %arg1[%d2, %d1] : memref<104x104xi8, strided<[1,104]>>
  //     %weightEltCasted = arith.extsi  %weightElt : i8 to i32 

  //     %outputElt = memref.load %arg2[%d0, %d1] : memref<104x104xi32, strided<[104,1]>> 
  //     %prod = arith.muli %inputEltCasted, %weightEltCasted : i32

  //     %newOutputElt = arith.addi %prod, %outputElt : i32 
  //     memref.store %newOutputElt, %arg2[%d0, %d1] : memref<104x104xi32, strided<[104,1]>>

  //   } // end of d2_2 for
  //   } // end of d1_2 for
  //   } // end of d0_2 for
  //   } // end of d2_1 for
  //   } // end of d1_1 for
  //   } // end of d0_1 for

  //   "func.return"() : () -> ()
  // }) {llvm.emit_c_interface}: () -> ()

   "func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104,1]>>) -> (), sym_name = "tiled_matmul_w_subviews"}> ({
  ^bb0(%arg0: memref<104x104xi8>, %arg1: memref<104x104xi8, strided<[1,104]>>, %arg2: memref<104x104xi32, strided<[104,1]>>):
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

    //%weightTile = %arg1 : memref<104x104xi8, strided<[1,104]>>// unchanged

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




  "func.func"() <{function_type = (memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1, 104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "accelerator_work"}> ({
  ^bb0(%arg0: memref<8x104xi8, strided<[104, 1], offset: ?>>, %arg1: memref<104x104xi8, strided<[1,104]>>, %arg2: memref<8x104xi32, strided<[104, 1], offset: ?>>):
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


 "func.func"() <{function_type = (memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1,104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "modify_output", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
 "func.func"() <{function_type = (memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1,104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
 

// perform tiled matrix multiplication,
// dispatching part of the work to the accelerator!

  "func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104,1]>>, memref<104x104xi32, strided<[104,1]>>) -> (), sym_name = "tiled_matmul"}> ({
  ^bb0(%arg0: memref<104x104xi8>, %arg1: memref<104x104xi8, strided<[1,104]>>, %arg2: memref<104x104xi32, strided<[104,1]>>, %l1OSlice: memref<104x104xi32, strided<[104,1]>>):
        // indices
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %two = arith.constant 2: index
    %five = arith.constant 5: index
    %eight = arith.constant 8 : index
    %nine = arith.constant 9 : index
    %ten = arith.constant 10 : index
    %eleven = arith.constant 11 : index
    %twelve = arith.constant 12 : index 
    %thirteen = arith.constant 13 : index  
    %oneOhFour = arith.constant 104 : index
    %d0_1_bk_sz = arith.constant 8 : index
    %zero_i32 = arith.constant 0: i32

   // scf.for %d0_1 = %zero to %oneOhFour step %eight iter_args() -> () {
    // select a slice of output space on L3
   // %outputTileL3 = memref.subview %arg2[%d0_1,%zero][8,104][1,1] 
   // :  memref<104x104xi32, strided<[104,1]>> to memref<8x104xi32, strided<[104, 1], offset: ?>>
    // select a corresponding slice of output space on L1
  //  %outputTileL1 = memref.subview %l1OSlice[%d0_1,%zero][8,104][1,1] 
  //  :  memref<104x104xi32, strided<[104,1]>> to memref<8x104xi32, strided<[104, 1], offset: ?>> 	
	  // select a slice of input data from L1
  //  %inputTile = memref.subview %arg0[%d0_1,%zero][8,104][1,1] 
  //  : memref<104x104xi8> to memref<8x104xi8, strided<[104, 1], offset: ?>>

  // 3328 elts incomplete when for loop is 0-9, which means 4 subviews are left, since 4 * 104 * 8 = 3328.
  // 2496 elts incomlpete when for loop is 0-10, which means 3 subviews are left, since 

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

    func.call @dispatch_to_accelerator(%inputTile, %inputTile, %arg1, %outputTileL1) 
    : (memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1,104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> ()

     memref.copy %outputTileL1, %outputTileL3 : memref<8x104xi32, strided<[104, 1], offset: ?>> to memref<8x104xi32, strided<[104, 1], offset: ?>>   
     
     // zero-out the L1 slice; there has to be a better way to do this, right?
     scf.for %i = %zero to %eight step %one iter_args() -> () { 
      scf.for %j = %zero to %oneOhFour step %one iter_args() -> () { 
      memref.store %zero_i32, %outputTileL1[%i, %j] :memref<8x104xi32, strided<[104, 1], offset: ?>>
      }
     }
     
    } // end of d0_1 for


    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()


 
  "func.func"() <{function_type = (memref<104x104xi8>) -> (), sym_name = "print_my_arg", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
  "func.func"() <{function_type = (!llvm.ptr) -> (), sym_name = "print_my_arg2", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
  "func.func"() <{function_type = (i64) -> (), sym_name = "print_my_arg3", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()


  "func.func"() <{function_type = (memref<104x104xi8>) -> (), sym_name = "sendingMemref"}> ({
  ^bb0(%arg0: memref<104x104xi8>):
    //func.call @dispatch_to_accelerator(%arg0, %arg0, %arg1, %arg2) : (memref<104x104xi8>, memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104,1]>>) -> ()
    
     %0 = memref.extract_aligned_pointer_as_index %arg0 : memref<104x104xi8> -> index
     %1 = arith.index_cast %0 : index to i64
     %2 = llvm.inttoptr %1 : i64 to !llvm.ptr
     //func.call @print_my_arg3(%1):(i64) -> ()
     //func.call @print_my_arg2(%2):(!llvm.ptr) -> ()
     func.call @print_my_arg(%arg0):(memref<104x104xi8>) -> ()
     //func.call @print_my_arg(%arg0):(memref<104x104xi8>) -> ()

    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()




// DUMMY THAT ALWAYS RETURNS CORRECT ANSWER
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

    //%weightTile = %arg1 : memref<104x104xi8, strided<[1,104]>>// unchanged

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


// declaring an external MLIR function called dispatch_to_accelerator
//"func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104,1]>>) -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
//"func.func"() <{function_type =  (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

// declaring an external MLIR function called hola
"func.func"() <{function_type =  (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> (), sym_name = "hola", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

//(memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1, 104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> ()
  // "func.func"() <{function_type =  (memref<8x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[1, 104]>>, memref<8x104xi32, strided<[104, 1], offset: ?>>) -> (), sym_name = "sendWorkToAccelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()  

  // an MLIR func that we would like to have eventually call C code
  "func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32>) -> (), sym_name = "mlirFunc"}> ({
  ^bb0(%arg0: memref<104x104xi8, 0 : i32>, %arg1: memref<104x104xi8, strided<[1,104]>, 0 : i32>, %arg2: memref<104x104xi32>):
    %arg2_diff_stride = memref.cast %arg2 : memref<104x104xi32> to memref<104x104xi32, strided<[104, 1]>>
    //func.call @simple_matmul(%arg0, %arg1, %arg2) : (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32>) -> ()
    func.call @tiled_matmul_w_subviews(%arg0, %arg1, %arg2_diff_stride) : (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104, 1]>>) -> ()
 "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()

  // an MLIR func that we would like to have eventually call C code
  "func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32>) -> (), sym_name = "matmul"}> ({
  ^bb0(%arg0: memref<104x104xi8, 0 : i32>, %arg1: memref<104x104xi8, strided<[1,104]>, 0 : i32>, %arg2: memref<104x104xi32>):
    %arg2_diff_stride = memref.cast %arg2 : memref<104x104xi32> to memref<104x104xi32, strided<[104, 1]>>
    func.call @kernel_matmul(%arg0, %arg1, %arg2) : (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32>) -> ()
"func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()

  "func.func"() <{function_type = (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32>) -> (), sym_name = "matmul_tiled_subviews"}> ({
  ^bb0(%arg0: memref<104x104xi8, 0 : i32>, %arg1: memref<104x104xi8, strided<[1,104]>, 0 : i32>, %arg2: memref<104x104xi32>):
    %arg2_diff_stride = memref.cast %arg2 : memref<104x104xi32> to memref<104x104xi32, strided<[104, 1]>>
    func.call @tiled_matmul_w_subviews(%arg0, %arg1, %arg2_diff_stride) : (memref<104x104xi8>, memref<104x104xi8, strided<[1, 104]>>, memref<104x104xi32, strided<[104,1]>>) -> ()
"func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()


}) : () -> ()