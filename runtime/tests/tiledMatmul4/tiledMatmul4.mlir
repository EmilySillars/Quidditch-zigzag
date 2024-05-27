#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({
 
  "func.func"() <{function_type = (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, memref<2048x2048xi32>) -> (), sym_name = "simple_matmul"}> ({
  ^bb0(%arg0: memref<2048x2048xi8>, %arg1: memref<2048x2048xi8, strided<[1, 2048]>>, %arg2: memref<2048x2048xi32>):
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
    }) : (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, i32, i32, memref<2048x2048xi32>) -> ()
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()

  // "func.func"() <{function_type = (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, memref<2048x2048xi32>) -> (), sym_name = "simple_matmul"}> ({
  // ^bb0(%arg0: memref<2048x2048xi8>, %arg1: memref<2048x2048xi8, strided<[1, 2048]>>, %arg2: memref<2048x2048xi32>):
  //   %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
  //   "linalg.generic"(%arg0, %arg1, %0, %0, %arg2) <{indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d2, d1)>, affine_map<(d0, d1, d2) -> ()>, affine_map<(d0, d1, d2) -> ()>, affine_map<(d0, d1, d2) -> (d0, d1)>], iterator_types = [#linalg.iterator_type<parallel>, #linalg.iterator_type<parallel>, #linalg.iterator_type<reduction>], operandSegmentSizes = array<i32: 4, 1>}> ({
  //   ^bb0(%arg3: i8, %arg4: i8, %arg5: i32, %arg6: i32, %arg7: i32):
  //     %1 = "arith.extsi"(%arg3) : (i8) -> i32
  //     %2 = "arith.subi"(%1, %arg5)  : (i32, i32) -> i32
  //     %3 = "arith.extsi"(%arg4) : (i8) -> i32
  //     %4 = "arith.subi"(%3, %arg6)  : (i32, i32) -> i32
  //     %5 = "arith.muli"(%2, %4)  : (i32, i32) -> i32
  //     %6 = "arith.addi"(%arg7, %5) : (i32, i32) -> i32
  //     "linalg.yield"(%6) : (i32) -> ()
  //   }) : (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, i32, i32, memref<2048x2048xi32>) -> ()
  //   "func.return"() : () -> ()
  // }) {llvm.emit_c_interface}: () -> ()

// void mlir_qmat_transformed(squareMat *a, squareMat *b, squareMat *c,
//                            squareMat *dummy) {
//   transposeSquareMat(b, dummy);
//   // only square matrices allowed
//   size_t d0_1_bk_sz = a->len / 4;
//   size_t d1_1_bk_sz = a->len / 2;
//   size_t d1_2_bk_sz = d1_1_bk_sz / 2;
//   size_t d2_1_bk_sz = a->len / 2;

//   for (size_t d0_1 = 0; d0_1 < 4; d0_1++) {
//     for (size_t d0_2 = 0; d0_2 < 4; d0_2++) {
//       for (size_t d1_1 = 0; d1_1 < 2; d1_1++) {
//         for (size_t d1_2 = 0; d1_2 < 2; d1_2++) {
//           for (size_t d1_3 = 0; d1_3 < 4; d1_3++) {
//             for (size_t d2_1 = 0; d2_1 < 2; d2_1++) {
//               for (size_t d2_2 = 0; d2_2 < 8;
//                    d2_2++) { // technically spacially unrolled, but won't show
//                              // that here
//                 size_t d0 = d0_1 * d0_1_bk_sz + d0_2;
//                 size_t d1 = d1_1 * d1_1_bk_sz + d1_2 * d1_2_bk_sz + d1_3;
//                 size_t d2 = d2_1 * d2_1_bk_sz + d2_2;
//                 c->mat[d0][d1] += a->mat[d0][d2] * b->mat[d2][d1];
//               }
//             }
//           }
//         }
//       }
//     }
//   }
// }

"func.func"() <{function_type = (memref<16x16xi8>, memref<16x16xi8, strided<[1, 16]>>, memref<16x16xi32, strided<[16,1]>>) -> (), sym_name = "tiled_matmul"}> ({
  ^bb0(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8, strided<[1,16]>>, %arg2: memref<16x16xi32, strided<[16,1]>>):
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
//   size_t d0_1_bk_sz = a->len / 4;      // 16 / 4 = 4
//   size_t d1_1_bk_sz = a->len / 2;      // 16 / 2 = 8
//   size_t d1_2_bk_sz = d1_1_bk_sz / 2;  // 8 / 2 = 4
//   size_t d2_1_bk_sz = a->len / 2;      // 16 / 2 = 8

//   for (size_t d0_1 = 0; d0_1 < 4; d0_1++) {
//     for (size_t d0_2 = 0; d0_2 < 4; d0_2++) {
//       for (size_t d1_1 = 0; d1_1 < 2; d1_1++) {
//         for (size_t d1_2 = 0; d1_2 < 2; d1_2++) {
//           for (size_t d1_3 = 0; d1_3 < 4; d1_3++) {
//             for (size_t d2_1 = 0; d2_1 < 2; d2_1++) {
//               for (size_t d2_2 = 0; d2_2 < 8;
//                    d2_2++) { // technically spacially unrolled, but won't show
//                              // that here
//                 size_t d0 = d0_1 * d0_1_bk_sz + d0_2;
//                 size_t d1 = d1_1 * d1_1_bk_sz + d1_2 * d1_2_bk_sz + d1_3;
//                 size_t d2 = d2_1 * d2_1_bk_sz + d2_2;
//                 c->mat[d0][d1] += a->mat[d0][d2] * b->mat[d2][d1];

    // I need to go 7 loops deep!!!
    // enter scf nested FOR LOOP
    scf.for %d0_1 = %zero to %four step %one iter_args() -> () {
    scf.for %d0_2 = %zero to %four step %one iter_args() -> () {    
    scf.for %d1_1 = %zero to %two step %one iter_args() -> () {  
    scf.for %d1_2 = %zero to %two step %one iter_args () -> () { 
    scf.for %d1_3 = %zero to %four step %one iter_args () -> () {
    scf.for %d2_1 = %zero to %two step %one iter_args () -> () {
    scf.for %d2_2 = %zero to %eight step %one iter_args () -> () {
      %prod0 = arith.muli %d0_1, %d0_1_bk_sz : index
      %d0 = arith.addi %prod0, %d0_2 : index

      %prod1 = arith.muli %d1_1, %d1_1_bk_sz : index
      %prod1_2 = arith.muli %d1_2, %d1_2_bk_sz : index
      %sum1 = arith.addi %prod1, %prod1_2 : index
      %d1 = arith.addi %sum1, %d1_3 : index

      %prod2 = arith.muli %d2_1, %d2_1_bk_sz : index
      %d2 = arith.addi %prod2, %d2_2 : index
      //%ctile = memref.subview %arg2[%d0,%d1][2,2][1,1] : memref<16x16xi32, strided<[16,1]>> to memref<2x2xi32, strided<[16,1], offset: ?>>
      //%ctile = memref.subview %arg2[%d0,%d1][2,2][1,1] : memref<?x?xi32, strided<[?,?]>> to memref<?x?xi32, strided<[?,?], offset: ?>>
      // memref.store %100, %A[%1, 1023] : memref<4x?xf32, #layout, memspace0>
      // %12 = memref.load %A[%1, %2] : memref<8x?xi32, #layout, memspace0>
      %inputElt = memref.load %arg0[%d0, %d2] : memref<16x16xi8>
      %inputEltCasted = arith.extsi  %inputElt : i8 to i32 
      %weightElt = memref.load %arg1[%d2, %d1] : memref<16x16xi8, strided<[1,16]>>
      %weightEltCasted = arith.extsi  %weightElt : i8 to i32 
      %outputElt = memref.load %arg2[%d0, %d1] : memref<16x16xi32, strided<[16,1]>> //memref<1x1xi8>
      %prod = arith.muli %inputEltCasted, %weightEltCasted : i32
      %newOutputElt = arith.addi %prod, %outputElt : i32 
      memref.store %newOutputElt, %arg2[%d0, %d1] : memref<16x16xi32, strided<[16,1]>>


    } // end of d2_2 for
    } // end of d2_1 for
    } // end of d1_3 for
    } // end of d1_2 for
    } // end of d1_1 for
    } // end of d0_2 for
    } // end of d0_1 for


    // enter scf nested FOR LOOP
    // scf.for %k = %zero to %sixteen step %two iter_args() -> () {
    // scf.for %j = %zero to %one step %one iter_args() -> () {    
    // scf.for %i = %zero to %sixteen step %two iter_args() -> () {    
    // // pull out left tile
    // %leftTile = memref.subview %arg0[%i,%j][2,16][1,1] : memref<16x16xi8> to memref<2x16xi8, strided<[16, 1], offset: ?>>
    // %leftTileCasted = memref.cast %leftTile : memref<2x16xi8, strided<[16, 1], offset: ?>> to memref<2x16xi8>    
    // // pull out right tile
    // %rightTile = memref.subview %arg1[%j,%k][16,2][1,1] : memref<16x16xi8, strided<[1,16]>> to memref<16x2xi8, strided<[1,16], offset: ?>>
    // %rightTileCasted = memref.cast %rightTile : memref<16x2xi8, strided<[1,16], offset: ?>> to memref<16x2xi8, strided<[1,16]>>
    // // pull out output tile
    // %outputTile = memref.subview %arg2[%i,%k][2,2][1,1] : memref<16x16xi32, strided<[16,1]>> to memref<2x2xi32, strided<[16,1], offset: ?>>
    // %outputTileCasted = memref.cast %outputTile : memref<2x2xi32, strided<[16,1], offset: ?>> to memref<2x2xi32, strided<[16,1]>>  
    
    // //func.call @hola(%leftTileCasted, %rightTileCasted, %outputTileCasted) :(memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, memref<2x2xi32, strided<[16,1]>>) -> ()

    // // feed computation to linalg generic (accelerator workload)
    // "linalg.generic"(%leftTileCasted, %rightTileCasted, %0, %0, %outputTileCasted) <{
    //   indexing_maps = [
    //     affine_map<(d0, d1, d2) -> (d0, d2)>, 
    //     affine_map<(d0, d1, d2) -> (d2, d1)>, 
    //     affine_map<(d0, d1, d2) -> ()>, 
    //     affine_map<(d0, d1, d2) -> ()>, 
    //     affine_map<(d0, d1, d2) -> (d0, d1)>], 
    //     iterator_types = [
    //       #linalg.iterator_type<parallel>, 
    //       #linalg.iterator_type<parallel>, 
    //       #linalg.iterator_type<reduction>], 
    //       operandSegmentSizes = array<i32: 4, 1>}> ({
    // ^bb0(%arg3: i8, %arg4: i8, %arg5: i32, %arg6: i32, %arg7: i32):
    //   %1 = "arith.extsi"(%arg3) : (i8) -> i32
    //   %2 = "arith.subi"(%1, %arg5) : (i32, i32) -> i32
    //   %3 = "arith.extsi"(%arg4) : (i8) -> i32
    //   %4 = "arith.subi"(%3, %arg6) : (i32, i32) -> i32
    //   %5 = "arith.muli"(%2, %4) : (i32, i32) -> i32
    //   %6 = "arith.addi"(%arg7, %5) : (i32, i32) -> i32
    //   "linalg.yield"(%6) : (i32) -> ()
    // }) : (memref<2x16xi8>, memref<16x2xi8, strided<[1,16]>>, i32, i32, memref<2x2xi32, strided<[16,1]>>) -> ()

    // } // end of i for
    // } // end of j for
    // } // end of k for
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
  "func.func"() <{function_type = (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, memref<2048x2048xi32>) -> (), sym_name = "mlirFunc"}> ({
  ^bb0(%arg0: memref<2048x2048xi8, 0 : i32>, %arg1: memref<2048x2048xi8, strided<[1,2048]>, 0 : i32>, %arg2: memref<2048x2048xi32>):
    %arg2_diff_stride = memref.cast %arg2 : memref<2048x2048xi32> to memref<2048x2048xi32, strided<[2048, 1]>>
    func.call @simple_matmul(%arg0, %arg1, %arg2) : (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, memref<2048x2048xi32>) -> ()
    //func.call @tiled_matmul(%arg0, %arg1, %arg2_diff_stride) : (memref<2048x2048xi8>, memref<2048x2048xi8, strided<[1, 2048]>>, memref<2048x2048xi32, strided<[2048, 1]>>) -> ()
 "func.return"() : () -> ()
  }) {llvm.emit_c_interface} : () -> ()


}) : () -> ()
