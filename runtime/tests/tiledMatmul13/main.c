// adapted from
// https://github.com/KULeuven-MICAS/snax-mlir/blob/f651860981efe0da84c0e5231bfcb03faf16890a/kernels/simple_matmul/main.c

#include <Quidditch/zigzag_dispatch/zigzag_dispatch.h>

#include <assert.h>
#include <cluster_interrupt_decls.h>
#include <riscv.h>
#include <snitch_cluster_defs.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <team_decls.h>

#include "../lib-zigzag/zigzag_utils.h"

uint32_t snrt_l1_start_addr();
uint32_t snrt_l1_end_addr();

// External functions implemented in MLIR
extern void _mlir_ciface_tiled_matmul(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                      TwoDMemrefI32_t *c,
                                      TwoDMemrefI32_t *l1OTile);
extern void _mlir_ciface_matmul_accelerator_work(TwoDMemrefI8_t *a,
                                                 TwoDMemrefI8_t *b,
                                                 TwoDMemrefI32_t *c);
extern void _mlir_ciface_dummy2(uint32_t coreID, TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                       TwoDMemrefI32_t *c,
                                       TwoDMemrefI8_t *sliceI,
                                       TwoDMemrefI8_t *sliceW,
                                       TwoDMemrefI32_t *sliceO);


int main() {
  if (!snrt_is_dm_core()) {
    compute_core_loop();
    return 0;
  }

  uint32_t l1 = snrt_l1_start_addr();

  // Create memref objects for data stored in L3
  TwoDMemrefI8_t memrefA;  // weight 104x104xi8
  memrefA.data = (int8_t *)malloc(sizeof(int8_t) * MAT_WIDTH_SQUARED);
  memrefA.aligned_data = memrefA.data;
  memrefA.offset = 0;
  memrefA.shape[0] = 104;
  memrefA.shape[1] = 104;
  memrefA.stride[0] = 104;
  memrefA.stride[1] = 1;
  TwoDMemrefI8_t memrefB;  // weight 104x104xi8
  memrefB.data = (int8_t *)malloc(sizeof(int8_t) * MAT_WIDTH_SQUARED);
  memrefB.aligned_data = memrefB.data;
  memrefB.offset = 0;
  memrefB.shape[0] = 104;
  memrefB.shape[1] = 104;
  memrefB.stride[0] = 1;
  memrefB.stride[1] = 104;
  TwoDMemrefI32_t memrefC;  // output 104x104xi32
  memrefC.data = (int32_t *)malloc(sizeof(int32_t) * MAT_WIDTH_SQUARED);
  memrefC.aligned_data = memrefC.data;
  memrefC.offset = 0;
  memrefC.shape[0] = 104;
  memrefC.shape[1] = 104;
  memrefC.stride[0] = 104;
  memrefC.stride[1] = 1;
  TwoDMemrefI32_t memrefGolden;  // golden 104x104xi32
  memrefGolden.data = (int32_t *)malloc(sizeof(int32_t) * MAT_WIDTH_SQUARED);
  memrefGolden.aligned_data = memrefGolden.data;
  memrefGolden.offset = 0;
  memrefGolden.shape[0] = 104;
  memrefGolden.shape[1] = 104;
  memrefGolden.stride[0] = 104;
  memrefGolden.stride[1] = 1;

  // new L1 "allocations" for ex 11
 TwoDMemrefI8_t memrefInputSlice;  // input-l1: 104x104
  memrefInputSlice.data = (int8_t *)l1;
  memrefInputSlice.aligned_data = memrefInputSlice.data;
  memrefInputSlice.offset = 0;
  memrefInputSlice.shape[0] = 104;
  memrefInputSlice.shape[1] = 13;
  memrefInputSlice.stride[0] = 104;
  memrefInputSlice.stride[1] = 1;
  l1 += (sizeof(int8_t) * MAT_WIDTH_SQUARED);

  TwoDMemrefI8_t memrefWeightSlice;  // weight-l1-slice: 104x13
  memrefWeightSlice.data = (int8_t *)l1;
  memrefWeightSlice.aligned_data = memrefWeightSlice.data;
  memrefWeightSlice.offset = 0;
  memrefWeightSlice.shape[0] = 104;
  memrefWeightSlice.shape[1] = 13;
  memrefWeightSlice.stride[0] = 1;
  memrefWeightSlice.stride[1] = 104;
  l1 += (sizeof(int8_t) * MAT_WIDTH * 13);

  TwoDMemrefI32_t memrefOutputSlice;  // output-l1-slice: 104x13
  memrefOutputSlice.data = (int32_t *)l1;
  memrefOutputSlice.aligned_data = memrefOutputSlice.data;
  memrefOutputSlice.offset = 0;
  memrefOutputSlice.offset = 0;
  memrefOutputSlice.shape[0] = 104;
  memrefOutputSlice.shape[1] = 13;
  memrefOutputSlice.stride[0] = 104;
  memrefOutputSlice.stride[1] = 1;
  l1 += (sizeof(int32_t) * MAT_WIDTH * 13);

  // initialize the matrices
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++) {
    memrefA.aligned_data[i] = (int8_t)2;
  }
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++) {
    memrefB.aligned_data[i] = (int8_t)3;
  }
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++) {
    memrefC.aligned_data[i] = (int32_t)0;
  }
  
  // print2DMemRefI8_t(&memrefA,MAT_WIDTH);
  // print2DMemRefI8_t(&memrefB,MAT_WIDTH);
  // print2DMemRefI32_t(&memrefC,MAT_WIDTH);

  // perform C code matmul to get the ground truth
  cCodeSquareMatmul(&memrefA, &memrefB, &memrefGolden);

  // set_accelerator_computation(5, (kernel_ptr)_mlir_ciface_mango);
  set_accelerator_computation(5, (kernel_ptr)_mlir_ciface_tiledMatmul12_kernel);
  // host_acc_perform_kernel_together((kernel_ptr)_mlir_ciface_tiled_matmul,
  //                                  (void *)&memrefA, (void *)&memrefB,
  //                                  (void *)&memrefC, (void *)&memrefOSlice);

  // host_acc_perform_kernel_together_2_slices(
  //     (kernel_ptr)_mlir_ciface_pineapple, (void *)&memrefA, (void *)&memrefB,
  //     (void *)&memrefC, (void *)&memrefOutputSlice, (void *)&memrefWeightSlice);

  // _mlir_ciface_tiledMatmul12(5, &memrefA, &memrefB, &memrefC, 0, &memrefWeightSlice, &memrefOutputSlice);
  //_mlir_ciface_dummy2(5, &memrefA, &memrefB, &memrefC, &memrefInputSlice, &memrefWeightSlice, &memrefOutputSlice);
  _mlir_ciface_tiledMatmul12(5, &memrefA, &memrefB, &memrefC, &memrefInputSlice, &memrefWeightSlice, &memrefOutputSlice);

  //_mlir_ciface_tiledMatmul12(5, &memrefA, &memrefB, &memrefC, 0, &memrefWeightSlice, &memrefOutputSlice);

  // check for correctness
  int nerr = 0;
  for (int i = 0; i < MAT_WIDTH_SQUARED; i++) {
    int32_t error = memrefC.aligned_data[i] - memrefGolden.aligned_data[i];
    if (error != 0) {
      nerr += 1;
      printf(" i is %d and %d /= %d\n", i, memrefC.aligned_data[i],
             memrefGolden.aligned_data[i]);
      break;
    }
  }

  if (nerr != 0) {
    printf("Output does not match the golden value!\n");
    print2DMemRefI32_t(&memrefC, 104);
    // print2DMemRefI32_t(&memrefGolden, 104);
  } else {
    printf("Output Correct\n");
  }

  // free everything before exiting!
  free(memrefA.data);
  free(memrefB.data);
  free(memrefC.data);
  free(memrefGolden.data);

  // tell all compute cores (really just compute core 0) to exit
  tell_compute_cores_to_exit();
  return nerr;
}
