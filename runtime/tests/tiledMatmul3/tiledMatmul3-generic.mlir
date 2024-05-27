#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({
  "func.func"() <{function_type = (memref<27x27xi8>, memref<27x27xi8, strided<[1, 27]>>, memref<27x27xi32>) -> (), sym_name = "simple_matmul"}> ({
  ^bb0(%arg0: memref<27x27xi8>, %arg1: memref<27x27xi8, strided<[1, 27]>>, %arg2: memref<27x27xi32>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "linalg.generic"(%arg0, %arg1, %0, %0, %arg2) <{indexing_maps = [#map, #map1, #map2, #map2, #map3], iterator_types = [#linalg.iterator_type<parallel>, #linalg.iterator_type<parallel>, #linalg.iterator_type<reduction>], operandSegmentSizes = array<i32: 4, 1>}> ({
    ^bb0(%arg3: i8, %arg4: i8, %arg5: i32, %arg6: i32, %arg7: i32):
      %1 = "arith.extsi"(%arg3) : (i8) -> i32
      %2 = "arith.subi"(%1, %arg5) : (i32, i32) -> i32
      %3 = "arith.extsi"(%arg4) : (i8) -> i32
      %4 = "arith.subi"(%3, %arg6) : (i32, i32) -> i32
      %5 = "arith.muli"(%2, %4) : (i32, i32) -> i32
      %6 = "arith.addi"(%arg7, %5) : (i32, i32) -> i32
      "linalg.yield"(%6) : (i32) -> ()
    }) : (memref<27x27xi8>, memref<27x27xi8, strided<[1, 27]>>, i32, i32, memref<27x27xi32>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()

  "func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32, strided<[16, 1]>>) -> (), sym_name = "tiled_matmul"}> ({
  ^bb0(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8, strided<[1, 16]>>, %arg2: memref<16x16xi32, strided<[16, 1]>>):
    %0 = "arith.constant"() <{value = 4 : index}> : () -> index
    %1 = "arith.constant"() <{value = 8 : index}> : () -> index
    %2 = "arith.constant"() <{value = 4 : index}> : () -> index
    %3 = "arith.constant"() <{value = 8 : index}> : () -> index
    %4 = "arith.constant"() <{value = 0 : index}> : () -> index
    %5 = "arith.constant"() <{value = 1 : index}> : () -> index
    %6 = "arith.constant"() <{value = 2 : index}> : () -> index
    %7 = "arith.constant"() <{value = 4 : index}> : () -> index
    %8 = "arith.constant"() <{value = 8 : index}> : () -> index
    %9 = "arith.constant"() <{value = 16 : index}> : () -> index
    "scf.for"(%4, %7, %5) ({
    ^bb0(%arg3: index):
      "scf.for"(%4, %7, %5) ({
      ^bb0(%arg4: index):
        "scf.for"(%4, %6, %5) ({
        ^bb0(%arg5: index):
          "scf.for"(%4, %6, %5) ({
          ^bb0(%arg6: index):
            "scf.for"(%4, %7, %5) ({
            ^bb0(%arg7: index):
              "scf.for"(%4, %6, %5) ({
              ^bb0(%arg8: index):
                "scf.for"(%4, %8, %5) ({
                ^bb0(%arg9: index):
                  %10 = "arith.muli"(%arg3, %0) : (index, index) -> index
                  %11 = "arith.addi"(%10, %arg4) : (index, index) -> index
                  %12 = "arith.muli"(%arg5, %1) : (index, index) -> index
                  %13 = "arith.muli"(%arg6, %2) : (index, index) -> index
                  %14 = "arith.addi"(%12, %13) : (index, index) -> index
                  %15 = "arith.addi"(%14, %arg7) : (index, index) -> index
                  %16 = "arith.muli"(%arg8, %3) : (index, index) -> index
                  %17 = "arith.addi"(%16, %arg9) : (index, index) -> index
                  %18 = "memref.load"(%arg0, %11, %17) : (memref<16x16xi8>, index, index) -> i8
                  %19 = "arith.extsi"(%18) : (i8) -> i32
                  %20 = "memref.load"(%arg1, %17, %15) : (memref<16x16xi8, strided<[1, 16]>>, index, index) -> i8
                  %21 = "arith.extsi"(%20) : (i8) -> i32
                  %22 = "memref.load"(%arg2, %11, %15) : (memref<16x16xi32, strided<[16, 1]>>, index, index) -> i32
                  %23 = "arith.muli"(%19, %21) : (i32, i32) -> i32
                  %24 = "arith.addi"(%23, %22) : (i32, i32) -> i32
                  "memref.store"(%24, %arg2, %11, %15) : (i32, memref<16x16xi32, strided<[16, 1]>>, index, index) -> ()
                  "scf.yield"() : () -> ()
                }) : (index, index, index) -> ()
                "scf.yield"() : () -> ()
              }) : (index, index, index) -> ()
              "scf.yield"() : () -> ()
            }) : (index, index, index) -> ()
            "scf.yield"() : () -> ()
          }) : (index, index, index) -> ()
          "scf.yield"() : () -> ()
        }) : (index, index, index) -> ()
        "scf.yield"() : () -> ()
      }) : (index, index, index) -> ()
      "scf.yield"() : () -> ()
    }) : (index, index, index) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()
 
  "func.func"() <{function_type = (memref<2x16xi8>, memref<16x2xi8, strided<[1, 16]>>, memref<2x2xi32, strided<[16, 1]>>) -> (), sym_name = "tile_compute"}> ({
  ^bb0(%arg0: memref<2x16xi8>, %arg1: memref<16x2xi8, strided<[1, 16]>>, %arg2: memref<2x2xi32, strided<[16, 1]>>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "linalg.generic"(%arg0, %arg1, %0, %0, %arg2) <{indexing_maps = [#map, #map1, #map2, #map2, #map3], iterator_types = [#linalg.iterator_type<parallel>, #linalg.iterator_type<parallel>, #linalg.iterator_type<reduction>], operandSegmentSizes = array<i32: 4, 1>}> ({
    ^bb0(%arg3: i8, %arg4: i8, %arg5: i32, %arg6: i32, %arg7: i32):
      %1 = "arith.extsi"(%arg3) : (i8) -> i32
      %2 = "arith.subi"(%1, %arg5) : (i32, i32) -> i32
      %3 = "arith.extsi"(%arg4) : (i8) -> i32
      %4 = "arith.subi"(%3, %arg6) : (i32, i32) -> i32
      %5 = "arith.muli"(%2, %4) : (i32, i32) -> i32
      %6 = "arith.addi"(%arg7, %5) : (i32, i32) -> i32
      "linalg.yield"(%6) : (i32) -> ()
    }) : (memref<2x16xi8>, memref<16x2xi8, strided<[1, 16]>>, i32, i32, memref<2x2xi32, strided<[16, 1]>>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()
 
  "func.func"() <{function_type = (memref<2x16xi8>, memref<16x2xi8, strided<[1, 16]>>, memref<2x2xi32, strided<[16, 1]>>) -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({
  }) {llvm.emit_c_interface} : () -> ()
 
  "func.func"() <{function_type = (memref<2x16xi8>, memref<16x2xi8, strided<[1, 16]>>, memref<2x2xi32, strided<[16, 1]>>) -> (), sym_name = "hola", sym_visibility = "private"}> ({
  }) {llvm.emit_c_interface} : () -> ()

  "func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32, strided<[16, 1]>>) -> (), sym_name = "break_mats_into_tiles"}> ({
  ^bb0(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8, strided<[1, 16]>>, %arg2: memref<16x16xi32, strided<[16, 1]>>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 0 : index}> : () -> index
    %2 = "arith.constant"() <{value = 1 : index}> : () -> index
    %3 = "arith.constant"() <{value = 16 : index}> : () -> index
    %4 = "arith.constant"() <{value = 2 : index}> : () -> index
    "scf.for"(%1, %3, %4) ({
    ^bb0(%arg3: index):
      "scf.for"(%1, %2, %2) ({
      ^bb0(%arg4: index):
        "scf.for"(%1, %3, %4) ({
        ^bb0(%arg5: index):
          %5 = "memref.subview"(%arg0, %arg5, %arg4) <{operandSegmentSizes = array<i32: 1, 2, 0, 0>, static_offsets = array<i64: -9223372036854775808, -9223372036854775808>, static_sizes = array<i64: 2, 16>, static_strides = array<i64: 1, 1>}> : (memref<16x16xi8>, index, index) -> memref<2x16xi8, strided<[16, 1], offset: ?>>
          %6 = "memref.cast"(%5) : (memref<2x16xi8, strided<[16, 1], offset: ?>>) -> memref<2x16xi8>
          %7 = "memref.subview"(%arg1, %arg4, %arg3) <{operandSegmentSizes = array<i32: 1, 2, 0, 0>, static_offsets = array<i64: -9223372036854775808, -9223372036854775808>, static_sizes = array<i64: 16, 2>, static_strides = array<i64: 1, 1>}> : (memref<16x16xi8, strided<[1, 16]>>, index, index) -> memref<16x2xi8, strided<[1, 16], offset: ?>>
          %8 = "memref.cast"(%7) : (memref<16x2xi8, strided<[1, 16], offset: ?>>) -> memref<16x2xi8, strided<[1, 16]>>
          %9 = "memref.subview"(%arg2, %arg5, %arg3) <{operandSegmentSizes = array<i32: 1, 2, 0, 0>, static_offsets = array<i64: -9223372036854775808, -9223372036854775808>, static_sizes = array<i64: 2, 2>, static_strides = array<i64: 1, 1>}> : (memref<16x16xi32, strided<[16, 1]>>, index, index) -> memref<2x2xi32, strided<[16, 1], offset: ?>>
          %10 = "memref.cast"(%9) : (memref<2x2xi32, strided<[16, 1], offset: ?>>) -> memref<2x2xi32, strided<[16, 1]>>
          "func.call"(%6, %8, %10) <{callee = @hola}> : (memref<2x16xi8>, memref<16x2xi8, strided<[1, 16]>>, memref<2x2xi32, strided<[16, 1]>>) -> ()
          "scf.yield"() : () -> ()
        }) : (index, index, index) -> ()
        "scf.yield"() : () -> ()
      }) : (index, index, index) -> ()
      "scf.yield"() : () -> ()
    }) : (index, index, index) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()
  
  "func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32, strided<[16, 1]>>) -> (), sym_name = "break_mats_into_tiles2"}> ({
  ^bb0(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8, strided<[1, 16]>>, %arg2: memref<16x16xi32, strided<[16, 1]>>):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 0 : index}> : () -> index
    %2 = "arith.constant"() <{value = 1 : index}> : () -> index
    %3 = "arith.constant"() <{value = 16 : index}> : () -> index
    %4 = "arith.constant"() <{value = 2 : index}> : () -> index
    %5 = "arith.constant"() <{value = 0 : index}> : () -> index
    %6 = "arith.constant"() <{value = 0 : index}> : () -> index
    %7 = "arith.constant"() <{value = 0 : index}> : () -> index
    %8 = "memref.subview"(%arg0, %7, %6) <{operandSegmentSizes = array<i32: 1, 2, 0, 0>, static_offsets = array<i64: -9223372036854775808, -9223372036854775808>, static_sizes = array<i64: 2, 16>, static_strides = array<i64: 1, 1>}> : (memref<16x16xi8>, index, index) -> memref<2x16xi8, strided<[16, 1], offset: ?>>
    %9 = "memref.cast"(%8) : (memref<2x16xi8, strided<[16, 1], offset: ?>>) -> memref<2x16xi8>
    %10 = "memref.subview"(%arg1, %6, %5) <{operandSegmentSizes = array<i32: 1, 2, 0, 0>, static_offsets = array<i64: -9223372036854775808, -9223372036854775808>, static_sizes = array<i64: 16, 2>, static_strides = array<i64: 1, 1>}> : (memref<16x16xi8, strided<[1, 16]>>, index, index) -> memref<16x2xi8, strided<[1, 16], offset: ?>>
    %11 = "memref.cast"(%10) : (memref<16x2xi8, strided<[1, 16], offset: ?>>) -> memref<16x2xi8, strided<[1, 16]>>
    %12 = "memref.subview"(%arg2, %7, %5) <{operandSegmentSizes = array<i32: 1, 2, 0, 0>, static_offsets = array<i64: -9223372036854775808, -9223372036854775808>, static_sizes = array<i64: 2, 2>, static_strides = array<i64: 1, 1>}> : (memref<16x16xi32, strided<[16, 1]>>, index, index) -> memref<2x2xi32, strided<[16, 1], offset: ?>>
    %13 = "memref.cast"(%12) : (memref<2x2xi32, strided<[16, 1], offset: ?>>) -> memref<2x2xi32, strided<[16, 1]>>
    "func.call"(%9, %11, %13) <{callee = @hola}> : (memref<2x16xi8>, memref<16x2xi8, strided<[1, 16]>>, memref<2x2xi32, strided<[16, 1]>>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()

  "func.func"() <{function_type = (memref<27x27xi8>, memref<27x27xi8, strided<[1, 27]>>, memref<27x27xi32>) -> (), sym_name = "mlirFunc"}> ({
  ^bb0(%arg0: memref<27x27xi8>, %arg1: memref<27x27xi8, strided<[1, 27]>>, %arg2: memref<27x27xi32>):
    %0 = "memref.cast"(%arg2) : (memref<27x27xi32>) -> memref<27x27xi32, strided<[27, 1]>>
    "func.call"(%arg0, %arg1, %0) <{callee = @tiled_matmul}> : (memref<27x27xi8>, memref<27x27xi8, strided<[1, 27]>>, memref<27x27xi32, strided<[27, 1]>>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) : () -> ()

