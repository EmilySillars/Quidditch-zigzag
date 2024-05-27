"builtin.module"() ({
 
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

  "func.func"() <{function_type = (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> (), sym_name = "tile_compute"}> ({
  ^bb0(%leftTileCasted: memref<2x16xi8>, %rightTileCasted: memref<16x2xi8, strided<[1,16]>>, %outputTileCasted: memref<2x2xi32, strided<[16,1]>>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32

    //feed computation to linalg generic (accelerator workload)
    "linalg.generic"(%leftTileCasted, %rightTileCasted, %0, %0, %outputTileCasted) <{
      indexing_maps = [
        affine_map<(d0, d1, d2) -> (d0, d2)>, 
        affine_map<(d0, d1, d2) -> (d2, d1)>, 
        affine_map<(d0, d1, d2) -> ()>, 
        affine_map<(d0, d1, d2) -> ()>, 
        affine_map<(d0, d1, d2) -> (d0, d1)>], 
        iterator_types = [
          #linalg.iterator_type<parallel>, 
          #linalg.iterator_type<parallel>, 
          #linalg.iterator_type<reduction>], 
          operandSegmentSizes = array<i32: 4, 1>}> ({
    ^bb0(%arg3: i8, %arg4: i8, %arg5: i32, %arg6: i32, %arg7: i32):
      %1 = "arith.extsi"(%arg3) : (i8) -> i32
      %2 = "arith.subi"(%1, %arg5) : (i32, i32) -> i32
      %3 = "arith.extsi"(%arg4) : (i8) -> i32
      %4 = "arith.subi"(%3, %arg6) : (i32, i32) -> i32
      %5 = "arith.muli"(%2, %4) : (i32, i32) -> i32
      %6 = "arith.addi"(%arg7, %5) : (i32, i32) -> i32
      "linalg.yield"(%6) : (i32) -> ()
    }) : (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, i32, i32, memref<2x2xi32, strided<[16,1]>>) -> ()

    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()

// declaring an external MLIR function called dispatch_to_accelerator
"func.func"() <{function_type =  (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

// declaring an external MLIR function called hola
"func.func"() <{function_type =  (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> (), sym_name = "hola", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()


"func.func"() <{function_type = (memref<16x16xi8, 0 : i32>, memref<16x16xi8, strided<[1, 16]>, 0 : i32>, memref<16x16xi32, strided<[16,1]>, 0 : i32>) -> (), sym_name = "break_mats_into_tiles"}> ({
  ^bb0(%arg0: memref<16x16xi8, 0 : i32>, %arg1: memref<16x16xi8, strided<[1,16]>, 0 : i32>, %arg2: memref<16x16xi32, strided<[16,1]>, 0 : i32>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %sixteen = arith.constant 16 : index
    %two = arith.constant 2 : index

    // enter scf nested FOR LOOP
    scf.for %k = %zero to %sixteen step %two iter_args() -> () {
    scf.for %j = %zero to %one step %one iter_args() -> () {    
    scf.for %i = %zero to %sixteen step %two iter_args() -> () {    
    // pull out left tile
    %leftTile = memref.subview %arg0[%i,%j][2,16][1,1] : memref<16x16xi8> to memref<2x16xi8, strided<[16, 1], offset: ?>>
    %leftTileCasted = memref.cast %leftTile : memref<2x16xi8, strided<[16, 1], offset: ?>> to memref<2x16xi8>    
    // pull out right tile
    %rightTile = memref.subview %arg1[%j,%k][16,2][1,1] : memref<16x16xi8, strided<[1,16]>> to memref<16x2xi8, strided<[1,16], offset: ?>>
    %rightTileCasted = memref.cast %rightTile : memref<16x2xi8, strided<[1,16], offset: ?>> to memref<16x2xi8, strided<[1,16]>>
    // pull out output tile
    %outputTile = memref.subview %arg2[%i,%k][2,2][1,1] : memref<16x16xi32, strided<[16,1]>> to memref<2x2xi32, strided<[16,1], offset: ?>>
    %outputTileCasted = memref.cast %outputTile : memref<2x2xi32, strided<[16,1], offset: ?>> to memref<2x2xi32, strided<[16,1]>>  
    
    func.call @hola(%leftTileCasted, %rightTileCasted, %outputTileCasted) :(memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> ()
    
    } // end of i for
    } // end of j for
    } // end of k for
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()

  "func.func"() <{function_type = (memref<16x16xi8, 0 : i32>, memref<16x16xi8, strided<[1, 16]>, 0 : i32>, memref<16x16xi32, strided<[16,1]>, 0 : i32>) -> (), sym_name = "break_mats_into_tiles2"}> ({
  ^bb0(%arg0: memref<16x16xi8, 0 : i32>, %arg1: memref<16x16xi8, strided<[1,16]>, 0 : i32>, %arg2: memref<16x16xi32, strided<[16,1]>, 0 : i32>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %zero = arith.constant 0 : index
    %one = arith.constant 1: index
    %sixteen = arith.constant 16 : index
    %two = arith.constant 2 : index
    %k = arith.constant 0 : index
    %j = arith.constant 0 : index  
    %i = arith.constant 0 : index
    // pull out left tile
    %leftTile = memref.subview %arg0[%i,%j][2,16][1,1] : memref<16x16xi8> to memref<2x16xi8, strided<[16, 1], offset: ?>>
    %leftTileCasted = memref.cast %leftTile : memref<2x16xi8, strided<[16, 1], offset: ?>> to memref<2x16xi8>    
    // pull out right tile
    %rightTile = memref.subview %arg1[%j,%k][16,2][1,1] : memref<16x16xi8, strided<[1,16]>> to memref<16x2xi8, strided<[1,16], offset: ?>>
    %rightTileCasted = memref.cast %rightTile : memref<16x2xi8, strided<[1,16], offset: ?>> to memref<16x2xi8, strided<[1,16]>>
    // pull out output tile
    %outputTile = memref.subview %arg2[%i,%k][2,2][1,1] : memref<16x16xi32, strided<[16,1]>> to memref<2x2xi32, strided<[16,1], offset: ?>>
    %outputTileCasted = memref.cast %outputTile : memref<2x2xi32, strided<[16,1], offset: ?>> to memref<2x2xi32, strided<[16,1]>>  
    
    func.call @hola(%leftTileCasted, %rightTileCasted, %outputTileCasted) :(memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> ()

  "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()

  // an MLIR func that we would like to have eventually call C code
  "func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> (), sym_name = "mlirFunc"}> ({
  ^bb0(%arg0: memref<16x16xi8, 0 : i32>, %arg1: memref<16x16xi8, strided<[1,16]>, 0 : i32>, %arg2: memref<16x16xi32>):
    %arg2_diff_stride = memref.cast %arg2 : memref<16x16xi32> to memref<16x16xi32, strided<[16, 1]>>
    //func.call @simple_matmul(%arg0, %arg1, %arg2) : (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> ()
    func.call @tiled_matmul(%arg0, %arg1, %arg2_diff_stride) : (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32, strided<[16, 1]>>) -> ()
 "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()


}) : () -> ()
