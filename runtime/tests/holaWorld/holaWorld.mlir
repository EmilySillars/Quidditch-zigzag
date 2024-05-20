"builtin.module"() ({
 
// declaring an external MLIR function called dispatch_to_accelerator
"func.func"() <{function_type =  (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

// declaring an external MLIR function called hola
"func.func"() <{function_type =  (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> (), sym_name = "hola", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

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
    func.call @break_mats_into_tiles2(%arg0, %arg1, %arg2_diff_stride) : (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32, strided<[16, 1]>>) -> ()
 "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()


}) : () -> ()
