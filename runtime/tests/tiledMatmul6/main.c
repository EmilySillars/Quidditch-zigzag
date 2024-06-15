// adapted from
// https://github.com/KULeuven-MICAS/snax-mlir/blob/f651860981efe0da84c0e5231bfcb03faf16890a/kernels/simple_matmul/main.c

#include <stdlib.h>
#include <assert.h>
#include <cluster_interrupt_decls.h>
#include <riscv.h>
#include <snitch_cluster_defs.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <team_decls.h>
#include <Quidditch/zigzag_dispatch/zigzag_dispatch.h>
#include "../lib-zigzag/zigzag_utils.h"

// Kernel provided via external definition                                
extern void _mlir_ciface_matmul(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                           TwoDMemrefI32_t *c);
// this tile_compute function is not used in this program
extern void _mlir_ciface_tile_compute(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                TwoDMemrefI32_t *c);
// some more c functions that the mlir code has access to - not used in this program
void _mlir_ciface_hola(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c){
  printf("hola world!\n");
}
int trouble = 0; // bad global integer - TODO: get rid of this
void _mlir_ciface_dispatch_to_accelerator(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c){
  printf("calling tile compute... %d\n",trouble);
  trouble ++;
}

// only kernel supported
void matmul_kernel(void *a, void *b, void *c){
  TwoDMemrefI8_t *x = (TwoDMemrefI8_t *) a;
  TwoDMemrefI8_t *y = (TwoDMemrefI8_t *) b;
  TwoDMemrefI32_t *z = (TwoDMemrefI32_t *) c;
  _mlir_ciface_matmul(x,y,z);
}

int main() {
  if (!snrt_is_dm_core()) {
    compute_core_loop();
    return 0;
  }

  //printf("I am the DMA core with id %d", snrt_cluster_core_idx());

  // Create memref objects for data stored in L3
  TwoDMemrefI8_t memrefA;
  memrefA.data = (int8_t *) malloc(sizeof(int8_t)*MAT_WIDTH_SQUARED); 
  memrefA.aligned_data = memrefA.data;
  memrefA.offset = 0;
  TwoDMemrefI8_t memrefB;
  memrefB.data = (int8_t *) malloc(sizeof(int8_t)*MAT_WIDTH_SQUARED);
  memrefB.aligned_data = memrefB.data;
  memrefB.offset = 0;
  TwoDMemrefI32_t memrefC;
  memrefC.data = (int32_t *) malloc(sizeof(int32_t)*MAT_WIDTH_SQUARED);
  memrefC.aligned_data = memrefC.data;
  memrefC.offset = 0;
  TwoDMemrefI32_t memrefGolden;
  memrefGolden.data = (int32_t *) malloc(sizeof(int32_t)*MAT_WIDTH_SQUARED);
  memrefGolden.aligned_data = memrefGolden.data;
  memrefGolden.offset = 0;

  // initialize the matrices
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++){
    memrefA.aligned_data[i] = (int8_t) 2;
  }
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++){
    memrefB.aligned_data[i] = (int8_t) 3;
  }

  // perform C code matmul to get the ground truth
  cCodeEquivalentThreeLoops(&memrefA, &memrefB, &memrefGolden);

  // perform matmul on compute core #5
  set_kernel(matmul_kernel, (void *) &memrefA, (void *) &memrefB, (void*) &memrefC);
  wake_up_compute_core(5);
  wait_for_compute_core(5);

  // check for correctness
  int nerr = 0;
  for (int i = 0; i < MAT_WIDTH_SQUARED; i++) {
    int32_t error = memrefC.aligned_data[i] - memrefGolden.aligned_data[i];
    if (error != 0){
      nerr += 1;
      printf(" i is %d and %d /= %d\n",i,memrefC.aligned_data[i],memrefGolden.aligned_data[i]);
      break;
    }
  }

  if (nerr != 0) {
    printf("Output does not match the golden value!\n");
  } else {
    printf("Output Correct\n");
  }

  // free everything before exiting!
  free(memrefA.data);
  free(memrefB.data);
  free(memrefC.data);
  free(memrefGolden.data);

  // tell all compute cores (really just compute core 5) to exit
  tell_compute_cores_to_exit(); 
  return nerr;
}
