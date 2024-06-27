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

int main() {
  if (!snrt_is_dm_core()) {
    compute_core_loop();
    return 0;
  }

  // Create memref objects for data stored in L3: 
  // output and weight
  TwoDMemrefI32_t memrefC;  // output
  memrefC.data = (int32_t *)malloc(sizeof(int32_t) * MAT_WIDTH_SQUARED);
  memrefC.aligned_data = memrefC.data;
  memrefC.offset = 0;
  TwoDMemrefI32_t memrefGolden; // ground truth output
  memrefGolden.data = (int32_t *)malloc(sizeof(int32_t) * MAT_WIDTH_SQUARED);
  memrefGolden.aligned_data = memrefGolden.data;
  memrefGolden.offset = 0;
  TwoDMemrefI8_t memrefB;  // weight
  memrefB.data = (int8_t *) malloc(sizeof(int8_t) * MAT_WIDTH_SQUARED);
  memrefB.aligned_data = memrefB.data;
  memrefB.offset = 0;

  // Create memref objects for data stored in L1: 
  // input, output-l1-slice, weight-l1-slice
  TwoDMemrefI8_t memrefA;  // input
  memrefA.data = (int8_t *)snrt_l1_start_addr();
  memrefA.aligned_data = memrefA.data;
  memrefA.offset = 0;
  TwoDMemrefI8_t memrefWSlice;  // weight-l1-slice: 104x13
  memrefWSlice.data =
      (int8_t *)(snrt_l1_start_addr() + (MAT_WIDTH*13));
  memrefWSlice.aligned_data = memrefWSlice.data;
  memrefWSlice.offset = 0;
  TwoDMemrefI32_t memrefOSlice;  // output-l1-slice: 104x13
  memrefOSlice.data = (int32_t *)(snrt_l1_start_addr() +
                                  (MAT_WIDTH*13*2));
  memrefOSlice.aligned_data = memrefOSlice.data;
  memrefOSlice.offset = 0;

  // initialize the matrices
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++) {
    memrefA.aligned_data[i] = (int8_t)2;
  }
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++) {
    memrefB.aligned_data[i] = (int8_t)3;
  }

  // perform C code matmul to get the ground truth
  cCodeSquareMatmul(&memrefA, &memrefB, &memrefGolden);

  // total hack.
 // cCodeSquareMatmul(&memrefA, &memrefB, &memrefC); // DELETE LATER!!!!

  set_accelerator_computation((kernel_ptr)_mlir_ciface_matmul_accelerator_work);
  //_mlir_ciface_dummy
  host_acc_perform_kernel_together_2_slices((kernel_ptr)_mlir_ciface_dummy,
                                   (void *)&memrefA, (void *)&memrefB,
                                   (void *)&memrefC, (void *)&memrefOSlice, (void *)&memrefWSlice);  
  // host_acc_perform_kernel_together((kernel_ptr)_mlir_ciface_tiled_matmul,
  //                                  (void *)&memrefA, (void *)&memrefB,
  //                                  (void *)&memrefC, (void *)&memrefOSlice);
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
    print2DMemRefI32_t(&memrefGolden, 104);
  } else {
    printf("Output Correct\n");
  }

  // free everything before exiting!
  free(memrefB.data);
  free(memrefC.data);
  free(memrefGolden.data);

  // tell all compute cores (really just compute core 0) to exit
  tell_compute_cores_to_exit();
  return nerr;
}
