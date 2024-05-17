"builtin.module"() ({

  // declaring an external MLIR function called hola
"func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> (), sym_name = "debug", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

 
  "func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> (), sym_name = "simple_matmul"}> ({
  ^bb0(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8, strided<[1, 16]>>, %arg2: memref<16x16xi32>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
    "linalg.generic"(%arg0, %arg1, %0, %0, %arg2) <{indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d2, d1)>, affine_map<(d0, d1, d2) -> ()>, affine_map<(d0, d1, d2) -> ()>, affine_map<(d0, d1, d2) -> (d0, d1)>], iterator_types = [#linalg.iterator_type<parallel>, #linalg.iterator_type<parallel>, #linalg.iterator_type<reduction>], operandSegmentSizes = array<i32: 4, 1>}> ({
    ^bb0(%arg3: i8, %arg4: i8, %arg5: i32, %arg6: i32, %arg7: i32):
      //func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
      %1 = "arith.extsi"(%arg3) : (i8) -> i32
      //func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
      %2 = "arith.subi"(%1, %arg5)  : (i32, i32) -> i32
      //func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
      %3 = "arith.extsi"(%arg4) : (i8) -> i32
      //func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
      %4 = "arith.subi"(%3, %arg6)  : (i32, i32) -> i32
      //func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
      %5 = "arith.muli"(%2, %4)  : (i32, i32) -> i32
      //func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
      %6 = "arith.addi"(%arg7, %5) : (i32, i32) -> i32
      //func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
      "linalg.yield"(%6) : (i32) -> ()
    }) : (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, i32, i32, memref<16x16xi32>) -> ()
    func.call @debug(%arg0, %arg1, %arg2 ):(memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> () // debugging
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()


  // an MLIR func that we would like to have eventually call C code
  "func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> (), sym_name = "mlirFunc"}> ({
  ^bb0(%arg0: memref<16x16xi8, 0 : i32>, %arg1: memref<16x16xi8, strided<[1,16]>, 0 : i32>, %arg2: memref<16x16xi32>):
     func.call @simple_matmul(%arg0, %arg1, %arg2 ): (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32>) -> ()
    //%arg2_diff_stride = memref.cast %arg2 : memref<16x16xi32> to memref<16x16xi32, strided<[16, 1]>>
    //func.call @break_mats_into_tiles2(%arg0, %arg1, %arg2_diff_stride) : (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32, strided<[16, 1]>>) -> ()
 "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()

}) : () -> ()
