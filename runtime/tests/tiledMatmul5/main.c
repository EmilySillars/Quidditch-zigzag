#include "stdint.h"
#include <stdio.h>
#include <stdlib.h>
#include <team_decls.h>
#include "../lib-zigzag/data.h"
#include "../lib-zigzag/memref.h"

/*
 * These libraries are included from github.com/KULeuven-MICAS/snitch_cluster
 * Interested users, might want to look at:
 *
 * /sw/snRuntime/api
 * /target/snitch_cluster/sw/runtime/rtl/src
 * /target/snitch_cluster/sw/runtime/common
 * */


/* These libraries are included from github.com/KULeuven-MICAS/snitch_cluster
 * Interested users, might want to look at:
 *
 * /target/snitch_cluster/sw/snax/gemm/include"
 * /target/snitch_cluster/sw/snax/mac/include"
 *
 * */

// Kernel provided via external definition
                                
extern void _mlir_ciface_mlirFunc(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                           TwoDMemrefI32_t *c);
// this tile_compute function is not used in this program
extern void _mlir_ciface_tile_compute(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                TwoDMemrefI32_t *c);
// compute mat mul
void cCodeEquivalentThreeLoops(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
                               TwoDMemrefI32_t *z);
// helper functions
void cCodeEquivalent(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y, TwoDMemrefI32_t *z);
void print2DMemRefI8_t(TwoDMemrefI8_t *x, int32_t width);
void print2DMemRefI32_t(TwoDMemrefI32_t *x, int32_t width);
void print2DMemRefI32_t_notASquare(TwoDMemrefI32_t *x, int32_t stride_x, int32_t stride_y);
// some more c functions that the mlir code has access to - not used in this program
void _mlir_ciface_hola(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c){
  printf("hola world!\n");
}
int trouble = 0; // bad global integer - TODO: get rid of this
void _mlir_ciface_dispatch_to_accelerator(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c){
  printf("calling tile compute... %d\n",trouble);
  trouble ++;
//   (void)snrt_mcycle();
//   _mlir_ciface_tile_compute(a, b, c);
//   snrt_cluster_hw_barrier();
//   (void)snrt_mcycle();
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

// helper funcs below
void print2DMemRefI8_t(TwoDMemrefI8_t *x, int32_t width) {
  printf("[\n");
  // we ASSUME a square 2D array
  int32_t col = 0;
  for (int i = 0; i < width * width; i++) {
    if (col == width) {
      col = 0;
      printf("\n %d ", x->aligned_data[i]);

    } else {
      printf(" %d ", x->aligned_data[i]);
    }
    col++;
  }
  printf("]\n");
}

void print2DMemRefI32_t(TwoDMemrefI32_t *x, int32_t width) {
  printf("[\n");
  // we ASSUME a square 2D array
  int32_t col = 0;
  for (int i = 0; i < width * width; i++) {
    if (col == width) {
      col = 0;
      printf("\n %d ", x->aligned_data[i]);

    } else {
      printf(" %d ", x->aligned_data[i]);
    }
    col++;
  }
  printf("]\n");
}

void print2DMemRefI32_t_notASquare(TwoDMemrefI32_t *x, int32_t stride_x, int32_t stride_y) {
  printf("[\n");
  int32_t col = 0;
  for (int i = 0; i < stride_x*stride_y; i++) {
    if (col == stride_x) {
      col = 0;
      printf("\n %d ", x->aligned_data[i]);

    } else {
      printf(" %d ", x->aligned_data[i]);
    }
    col++;
  }
  printf("]\n");
}

void cCodeEquivalentThreeLoops(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
                               TwoDMemrefI32_t *z) {
  // printf("M_size is %d and N_size is %d\n",M_size, N_size);
  // for (int i = 0; i < M_size * N_size; i++) {
  //   z->aligned_data[i] = x->aligned_data[i] * y->aligned_data[i];
  // }
  int z_index, x_index, y_index = 0;
  for (int d0 = 0; d0 < MAT_WIDTH; d0++) {
    for (int d1 = 0; d1 < MAT_WIDTH; d1++) {
      for (int d2 = 0; d2 < MAT_WIDTH; d2++) {
        // arg7[d0][d1] += arg3[d0][d2] * arg4[d2][d1]; // and this is a MAC!
        z_index = (d0 * MAT_WIDTH) + d1;
        x_index = (d0 * MAT_WIDTH) + d2;
        y_index = (d2 * MAT_WIDTH) + d1;
        z->aligned_data[z_index] +=
            x->aligned_data[x_index] * y->aligned_data[y_index];
      }
    }
  }
}