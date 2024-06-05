#include "stdint.h"
#include <stdio.h>
#include <stdlib.h>
#include <team_decls.h>
#include "../lib-zigzag/data.h"
#include "../lib-zigzag/memref.h"
#include <Quidditch/zigzag_dispatch/zigzag_dispatch.h>
#include <snitch_cluster_defs.h>

// Kernel provided via external definition
                                
extern void _mlir_ciface_tile_compute(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                TwoDMemrefI32_t *c);

extern void _mlir_ciface_mlirFunc(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                           TwoDMemrefI32_t *c);

int trouble = 0; 

void cCodeEquivalentThreeLoops(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
                               TwoDMemrefI32_t *z);
void cCodeEquivalent(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y, TwoDMemrefI32_t *z);
void print2DMemRefI8_t(TwoDMemrefI8_t *x, int32_t width);
void print2DMemRefI32_t(TwoDMemrefI32_t *x, int32_t width);
void print2DMemRefI32_t_notASquare(TwoDMemrefI32_t *x, int32_t stride_x, int32_t stride_y);


void _mlir_ciface_hola(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c){
  printf("hola world!\n");
}

void _mlir_ciface_dispatch_to_accelerator(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c){
  printf("calling tile compute... %d\n",trouble);
  trouble++;
}

#define MAT_WIDTH 104
#define MAT_WIDTH_SQUARED (MAT_WIDTH * MAT_WIDTH)

int main() {
  //if (!snrt_is_dm_core()) return 0;

  // If I am a compute core, standby for kernel execution.
  if (!snrt_is_dm_core()) {
    return quidditch_dispatch_enter_worker_loop();
    printf("IMPOSSIBLE\n");
  }

 // printf("I am the dma core with id %d\n",snrt_cluster_core_idx());
  // // If I reach after the above if-statement, I am the DMA core.
  // printf("SNRT_CLUSTER_CORE_NUM is %d\n",SNRT_CLUSTER_CORE_NUM);
  // printf("snrt_cluster_compute_core_num() is %d\n", snrt_cluster_compute_core_num());
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

  // Caculate the correct answer
  cCodeEquivalentThreeLoops(&memrefA, &memrefB, &memrefGolden);

  // -------------------------------------------------- V
  // Run the computation on a compute core??
  quidditch_dispatch_set_kernel();
  quidditch_dispatch_submit_workgroup(1);
  _mlir_ciface_mlirFunc(&memrefA, &memrefB, &memrefC);

  // I want that MLIR function to call a C function
  // -------------------------------------------------- ^

  // Check for correctness
  int nerr = 0;
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
    // print2DMemRefI32_t(&memrefC,16);
  } else {
    printf("Output Correct\n");
  }

  // free everything before exiting!
  free(memrefA.data);
  free(memrefB.data);
  free(memrefC.data);
  free(memrefGolden.data);

  // release all compute cores from the work loop
  quidditch_dispatch_quit(); 
 // printf("inside main after quidditch_dispatch_quit();\n");
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


  // print2DMemRefI8_t(&memrefA,16);
  // print2DMemRefI8_t(&memrefB,16);
  // print2DMemRefI32_t(&memrefC,16);
  
  // printf("Size of int8_t is %d\n", sizeof(int8_t));
  // printf("Size of int32_t is %d\n", sizeof(int32_t));
  // printf("sizeof(int8_t)*MAT_WIDTH is %u\n",sizeof(int8_t)*MAT_WIDTH_SQUARED);
  // printf("sizeof(int32_t)*MAT_WIDTH is %u\n\n",sizeof(int32_t)*MAT_WIDTH_SQUARED);

  // printf("memrefA.data: %x \nmemrefB.data %x \nmemrefC.data %x \ngolden.data %x\n", memrefA.data, memrefB.data, memrefC.data, memrefGolden.data);
  // printf("memrefA.data: %u \nmemrefB.data %u \nmemrefC.data %u \ngolden.data %u\n", memrefA.data, memrefB.data, memrefC.data, memrefGolden.data);

  // printf("PAMPLEMOUSSE VOLCANO: Initializing each matrix.\n");