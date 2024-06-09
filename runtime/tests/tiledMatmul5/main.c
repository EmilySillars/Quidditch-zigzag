#include "stdint.h"
#include <stdio.h>
#include <stdlib.h>
#include <team_decls.h>
#include "../lib-zigzag/data.h"
#include "../lib-zigzag/memref.h"

// Kernel provided via external definition                                
extern void _mlir_ciface_mlirFunc(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
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


// we assume square matrices
#define MAT_WIDTH 104
#define MAT_WIDTH_SQUARED (MAT_WIDTH * MAT_WIDTH)

int main() {
  if (!snrt_is_dm_core()) {
    return 0;
  }

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


  // Call the MLIR tiled matmul function
  _mlir_ciface_mlirFunc(&memrefA, &memrefB, &memrefC);

  int nerr = 0;
  
  // check for correctness
  for (int i = 0; i < M_size * N_size; i++) {
    int32_t error = memrefC.aligned_data[i] - memrefGolden.aligned_data[i];  // C_golden[i];
    if (error != 0){
      nerr += 1;
      printf(" i is %d and %d /= %d\n",i,memrefC.aligned_data[i],memrefGolden.aligned_data[i]);
      break;
    }
  }

  if (nerr != 0) {
    printf("Output does not match the golden value!\n");
    // print2DMemRefI32_t(&memrefC,16); // debugging
  } else {
    printf("Output Correct\n");
  }

  // free everything before exiting!
  free(memrefA.data);
  free(memrefB.data);
  free(memrefC.data);
  free(memrefGolden.data);
  return nerr;
}