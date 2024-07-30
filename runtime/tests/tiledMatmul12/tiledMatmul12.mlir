#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> ()>
#map3 = affine_map<(d0, d1, d2) -> (d0, d1)>
"builtin.module"() ({
// declaring external MLIR functions (implementations in C)
"func.func"() <{function_type = () -> index, sym_name = "myID", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

"func.func"() <{function_type = (
    index) // coreID
    -> (), sym_name = "wait_for_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = () -> (), sym_name = "wait_for_all_accelerators", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = ( index,index,index,index,index,index,index,index) 
    -> (), sym_name = "save_outer_loop_counters", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
// "func.func"() <{function_type = (
//     index, // coreID
//     memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
//     memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
//     memref<104x1xi32, strided<[104, 1], offset: ?>>)  // output slice
//     -> (), sym_name = "dispatch_to_accelerator", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()

"func.func"() <{function_type = (
                index, 
                memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
                memref<26x104xi8, strided<[1, 104], offset: ?>>,   // weight slice
                memref<8x8xi32, strided<[104, 1], offset: ?>>)  // output slice
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
  memref<26x104xi8, strided<[1, 104], offset: ?>>, 
  memref<26x104xi8, strided<[1, 104], offset: ?>>) 
  -> (), sym_name = "memrefCopy8bit_W_26x104", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()
"func.func"() <{function_type = (
  memref<8x8xi32, strided<[104, 1], offset: ?>>, 
  memref<8x8xi32, strided<[104, 1], offset: ?>>) 
  -> (), sym_name = "memrefCopy32bit_O_8x8", sym_visibility = "private"}> ({}) {llvm.emit_c_interface}: () -> ()


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
    (index,                                               // coreID
    memref<104x104xi8, strided<[104, 1], offset: ?>>,   // input L3
    memref<104x104xi8, strided<[1, 104], offset: ?>>,   // weight L3
    memref<104x104xi32, strided<[104, 1], offset: ?>>,  // output L3
    memref<104x104xi8, strided<[104,1], offset: ?>>,    // input slice L1
    memref<104x104xi8, strided<[1, 104], offset: ?>>,   // weight slice L1
    memref<104x104xi32, strided<[104, 1], offset: ?>>)  // output slice  L1
    -> (), sym_name = "tiledMatmul12"}> ({
  ^bb0(%coreID : index,
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
    func.call @save_outer_loop_counters(%b1_0,%b1_0,%b1_0,%b1_0,%b1_0,%b1_0,%b1_0,%b1_0)
    : (index,index,index,index,index,index,index,index) -> ()

    // Now that all the slices are in L1, give the rest of the work to a core
    // func.call @dispatch_to_accelerator(%coreID, %inputL1, %sliceWL1_2, %sliceOL1_2)
    // : (
    // index, // coreID
    // memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
    // memref<104x1xi8, strided<[1, 104], offset: ?>>,   // weight slice
    // memref<104x1xi32, strided<[104, 1], offset: ?>>)  // output slice
    // -> ()

    func.call @wait_for_accelerator(%coreID) : (index) -> ()

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
    index,index,index,index,index,index,index,index)  
    -> (), sym_name = "tiledMatmul12_kernel"}> ({
  ^bb0(
    %arg0: memref<104x104xi8, strided<[104, 1], offset: ?>>, 
    %arg1: memref<104x1xi8, strided<[1, 104], offset: ?>>, 
    %arg2: memref<104x1xi32, strided<[104, 1], offset: ?>>,
    %counter_0 : index, 
    %counter_1 : index, 
    %counter_2 : index, 
    %counter_3 : index, 
    %counter_4 : index, 
    %counter_5 : index, 
    %counter_6 : index, 
    %counter_7 : index
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
    (index,                                              // coreID
    memref<104x104xi8, strided<[104, 1], offset: ?>>,   // input L3
    memref<104x104xi8, strided<[1, 104], offset: ?>>,   // weight L3
    memref<104x104xi32, strided<[104, 1], offset: ?>>,  // output L3
    memref<104x104xi8, strided<[104,1], offset: ?>>,    // input slice L1
    memref<104x104xi8, strided<[1, 104], offset: ?>>,   // weight slice L1
    memref<104x104xi32, strided<[104, 1], offset: ?>>)  // output slice  L1
    -> (), sym_name = "dmaCore"}> ({
  ^bb0(%coreID : index,
       %input: memref<104x104xi8, strided<[104, 1], offset: ?>>, 
       %weight: memref<104x104xi8, strided<[1,104], offset: ?>>, 
       %output: memref<104x104xi32, strided<[104,1], offset: ?>>, 
       %inputL1: memref<104x104xi8, strided<[104,1], offset: ?>>,
       %weightL1: memref<104x104xi8, strided<[1,104], offset: ?>>,
       %outputL1: memref<104x104xi32, strided<[104,1], offset: ?>>): 

      // indices
      %zero = arith.constant 0 : index
      %one = arith.constant 1 : index
      %four = arith.constant 4 : index
      %two = arith.constant  2 : index
      %eight = arith.constant  8 : index
      %thirteen = arith.constant 13 : index  
      // tile sizes
      %a1_bk_sz = arith.constant 8 : index
      %b1_bk_sz = arith.constant 8 : index
      %c1_bk_sz = arith.constant 13 : index
      %c2_bk_sz = arith.constant 26 : index
    
      // constants
      // %zero_i32 = arith.constant 0: i32
      // %sixTwentyFour_i32 = arith.constant 624: i32
      // %one_i32 = arith.constant 1 : i32
      // %three_i8 = arith.constant 3 : i8

      // copy input from L3 to L1
      func.call @memrefCopy8bit_I_104x104(%input,  %inputL1) 
      : (memref<104x104xi8, strided<[104, 1], offset: ?>>, memref<104x104xi8, strided<[104, 1], offset: ?>>) -> ()
     

      scf.for %c2 = %zero to %four step %one iter_args() -> () {
        
        // copy weight slice 26x104 from L3 to L1
        %slice_W_L3_offset = arith.muli %c2, %c2_bk_sz : index
        %slice_W_L3 = memref.subview %weight[%slice_W_L3_offset, %zero][26,104][1,1]
        :  memref<104x104xi8, strided<[1,104], offset: ?>> to memref<26x104xi8, strided<[1, 104], offset: ?>>
        %slice_W_L1 = memref.subview %weightL1[%slice_W_L3_offset, %zero][26,104][1,1]
        :  memref<104x104xi8, strided<[1,104], offset: ?>> to memref<26x104xi8, strided<[1, 104], offset: ?>>
        func.call @memrefCopy8bit_W_26x104( %slice_W_L3,   %slice_W_L1)
        : (memref<26x104xi8, strided<[1, 104], offset: ?>>,memref<26x104xi8, strided<[1, 104], offset: ?>>) -> ()
       
        scf.for %c1 = %zero to %two step %one iter_args() -> () {
          scf.for %b1 = %zero to %thirteen step %one iter_args() -> () {
            scf.for %a1 = %zero to %thirteen step %one iter_args() -> () {
              
              // copy output tile 8x8 from L3 to L1.
              %slice_O_L3_offset_r = arith.muli %a1, %a1_bk_sz : index
              %slice_O_L3_offset_c = arith.muli %b1, %b1_bk_sz : index
              %slice_O_L3 = memref.subview %output[%slice_O_L3_offset_r,%slice_O_L3_offset_c][8,8][1,1]
              : memref<104x104xi32, strided<[104, 1], offset: ?>>  to  memref<8x8xi32, strided<[104, 1], offset: ?>>
              %slice_O_L1 = memref.subview %outputL1[%slice_O_L3_offset_r,%slice_O_L3_offset_c][8,8][1,1]
              : memref<104x104xi32, strided<[104, 1], offset: ?>>  to  memref<8x8xi32, strided<[104, 1], offset: ?>>
              func.call @memrefCopy32bit_O_8x8(%slice_O_L3, %slice_O_L1)
              : (memref<8x8xi32, strided<[104, 1], offset: ?>>,memref<8x8xi32, strided<[104, 1], offset: ?>>) -> ()
              
              // save outer loop counters for use by all 8 cores
              func.call @save_outer_loop_counters(%a1,%b1,%c1,%c2,%a1_bk_sz,%b1_bk_sz,%c1_bk_sz,%c2_bk_sz)
              : (index,index,index,index,index,index,index,index) -> ()
              
              // dispatch tile computation work to each core
              scf.for %id = %zero to %eight step %one iter_args() -> (){
                func.call @dispatch_to_accelerator(%id, %inputL1, %slice_W_L1, %slice_O_L1)
                : (
                index, 
                memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
                memref<26x104xi8, strided<[1, 104], offset: ?>>,   // weight slice
                memref<8x8xi32, strided<[104, 1], offset: ?>>)  // output slice
                -> ()

              }
              // wait for all compute cores
              func.call @wait_for_all_accelerators() : () -> ()
              // copy output tile from L1 to L3.
              func.call @memrefCopy32bit_O_8x8(%slice_O_L1, %slice_O_L3)
              : (memref<8x8xi32, strided<[104, 1], offset: ?>>,memref<8x8xi32, strided<[104, 1], offset: ?>>) -> ()
            }

          }

        }

      }
  "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()


// computation performed by accelerator as part of tiled matmul
  "func.func"() <{function_type = (
    memref<104x104xi8, strided<[104, 1], offset: ?>>, // input
    memref<26x104xi8, strided<[1, 104], offset: ?>>,   // weight slice
    memref<8x8xi32, strided<[104, 1], offset: ?>>,
    index,index,index,index,index,index,index,index)  // output slice
    -> (), sym_name = "computeCore"}> ({
  ^bb0(
    %arg0: memref<104x104xi8, strided<[104, 1], offset: ?>>, 
    %arg1: memref<26x104xi8, strided<[1, 104], offset: ?>>, 
    %arg2: memref<8x8xi32, strided<[104, 1], offset: ?>>,
    %a1 : index, 
    %b1 : index, 
    %c1 : index, 
    %c2 : index, 
    %a1_bk_sz : index, 
    %b1_bk_sz : index, 
    %c1_bk_sz : index, 
    %c2_bk_sz : index
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
    %b0_bk_sz = arith.divui %b1_bk_sz, %eight : index
    %c0_bk_sz = arith.divui %c1_bk_sz , %thirteen : index
    %a0_bk_sz =  arith.divui %a1_bk_sz , %eight : index

    scf.for %b0 = %zero to %eight step %one iter_args() -> () { 
       scf.for %c0 = %zero to %thirteen step %one iter_args() -> () {

        %a0 = func.call @myID() : () -> (index) // spacial unrolling of a0
        %o_a = arith.muli %a0, %a0_bk_sz : index 
        %o_b = arith.muli %b0, %b0_bk_sz : index 
      
        // intermediate results
        %c_prod_0 = arith.muli %c0, %c0_bk_sz : index
        %c_prod_1 = arith.muli %c1, %c1_bk_sz : index
        %c_prod_2 = arith.muli %c2, %c2_bk_sz : index
        %c_sum_2_1 = arith.addi %c_prod_2, %c_prod_1 : index
        %a_prod_0 = arith.muli %a0, %a0_bk_sz : index
        %a_prod_1 = arith.muli %a1, %a1_bk_sz : index
        %b_prod_1 = arith.muli %b1, %b1_bk_sz : index   

        %w_c = arith.addi %c_prod_1, %c_prod_0 : index 
        %w_b = arith.addi %b_prod_1, %o_b : index        

        //     i_a = a1*a1_bk_sz + a0*a0_bk_sz;
        %i_a = arith.addi %a_prod_1, %a_prod_0 : index        
        //     i_c = c2*c2_bk_sz + c1*c1_bk_sz + c0*c0_bk_sz;
        %i_c = arith.addi %c_sum_2_1, %c_prod_0 : index     

        // update output cell: outputTile[o_a][o_b] += inputTile[i_a][i_c] * weightTile[w_c][w_b]
        %inputElt = memref.load %arg0[%i_a, %i_c] : memref<104x104xi8, strided<[104, 1], offset: ?>>
        %inputEltCasted = arith.extsi  %inputElt : i8 to i32 

        %weightElt = memref.load %arg1[%w_c, %w_b] : memref<26x104xi8, strided<[1, 104], offset: ?>>
        %weightEltCasted = arith.extsi  %weightElt : i8 to i32 

        %outputElt = memref.load %arg2[%o_a, %o_b] : memref<8x8xi32, strided<[104, 1], offset: ?>>
              
        %prod = arith.muli %inputEltCasted, %weightEltCasted : i32
        %newOutputElt = arith.addi %prod, %outputElt : i32

        //memref.store %newOutputElt, %arg2[%o_a, %o_b] : memref<8x8xi32, strided<[104, 1], offset: ?>>
        memref.store %sixTwentyFour_i32, %arg2[%o_a, %o_b] : memref<8x8xi32, strided<[104, 1], offset: ?>>
        //memref.store %sixTwentyFour_i32, %arg2[%zero, %zero] : memref<8x8xi32, strided<[104, 1], offset: ?>>
       }
    }
    "func.return"() : () -> ()
  }) {llvm.emit_c_interface}: () -> ()



}) : () -> ()