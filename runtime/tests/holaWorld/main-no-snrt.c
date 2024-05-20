#include "stdint.h"
#include <stdio.h>
#include "data.h"
#include "memref.h"


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

// meshRow, tileSize and meshCol are defined in snax-gemm-params.h v v v
// Copyright 2023 KU Leuven.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Xiaoling Yi <xiaoling.yi@esat.kuleuven.be>
#define tileSize 8
#define meshRow 8
#define meshCol 8
// meshRow, tileSize and meshCol are defined in snax-gemm-params.h ^ ^ ^

uint8_t Batch = 1;
// meshRow, tileSize and meshCol are defined in snax-gemm-params.h
uint8_t M_param = M_size / meshRow;
uint8_t K_param = K_size / tileSize;
uint8_t N_param = N_size / meshCol;
// Extracted from datagen.py in snitch_cluster repo
uint32_t strideInnermostA = 256;
uint32_t strideInnermostB = 256;
uint32_t strideInnermostC = 256;
uint32_t ldA = 512;
uint32_t ldB = 512;
uint32_t ldC = 512;
uint32_t strideA = 0;
uint32_t strideB = 0;
uint32_t strideC = 0;

// Kernel provided via external definition
extern void _mlir_ciface_tiled_matmul(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                TwoDMemrefI32_t *c);
                                
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
//   (void)snrt_mcycle();
//   _mlir_ciface_tile_compute(a, b, c);
//   snrt_cluster_hw_barrier();
//   (void)snrt_mcycle();
}

// ADDING EVEN SMALLER MATRICES TO TEST!
const int8_t little_A[256] = {
    1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,  2,  3,
    4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,  2,  3,  4,  5,  6,
    7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,  2,  3,  4,  5,  6,  7,  8,  9,
    10, 11, 12, 13, 14, 15, 16, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12,
    13, 14, 15, 16, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15,
    16, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,  2,
    3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,  2,  3,  4,  5,
    6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,  2,  3,  4,  5,  6,  7,  8,
    9,  10, 11, 12, 13, 14, 15, 16, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11,
    12, 13, 14, 15, 16, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14,
    15, 16, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,
    2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,  2,  3,  4,
    5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 1,  2,  3,  4,  5,  6,  7,
    8,  9,  10, 11, 12, 13, 14, 15, 16};
const int8_t little_B[256] = {
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3};
const int32_t little_golden[256] = {
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408, 408,
    408};

// void tile_compute(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c) {
//   (void)snrt_mcycle();
//   _mlir_ciface_simple_matmul(a, b, c);
//   snrt_cluster_hw_barrier();
//   (void)snrt_mcycle();
// }

int main() {

 // printf("PAMPLEMOUSSE VOLCANO: Setting up the data.\n");

  // Create memref objects for data stored in L3
  TwoDMemrefI8_t memrefA;
  memrefA.data = (int8_t *)&little_A;
  memrefA.aligned_data = memrefA.data;
  memrefA.offset = 0;
  memrefA.shape[0] = M_size;
  memrefA.shape[1] = M_size;

  printf("M_SIZE is %d", M_size)

  TwoDMemrefI8_t memrefB;
  memrefB.data = (int8_t *)&little_B;
  memrefB.aligned_data = memrefB.data;
  memrefB.offset = 0;

  TwoDMemrefI32_t memrefC;
  memrefC.data = (int32_t *)&C;
  memrefC.aligned_data = memrefC.data;
  memrefC.offset = 0;

  // -------------------------------------------------- V
  // I want a C function to call an MLIR function
  _mlir_ciface_mlirFunc(&memrefA, &memrefB, &memrefC);

  // I want that MLIR function to call a C function
  // -------------------------------------------------- ^

  int nerr = 0;
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

void cCodeEquivalent(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y, TwoDMemrefI32_t *z) {
  printf("M_size is %d and N_size is %d\n", M_size, N_size);
  for (int i = 0; i < M_size * N_size; i++) {
    z->aligned_data[i] =
        (int32_t)x->aligned_data[i] * (int32_t)y->aligned_data[i];
  }
}

void cCodeEquivalentThreeLoops(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
                               TwoDMemrefI32_t *z) {
  // printf("M_size is %d and N_size is %d\n",M_size, N_size);
  // for (int i = 0; i < M_size * N_size; i++) {
  //   z->aligned_data[i] = x->aligned_data[i] * y->aligned_data[i];
  // }
  int z_index, x_index, y_index = 0;
  for (int d0 = 0; d0 < M_size; d0++) {
    for (int d1 = 0; d1 < M_size; d1++) {
      for (int d2 = 0; d2 < M_size; d2++) {
        // arg7[d0][d1] += arg3[d0][d2] * arg4[d2][d1]; // and this is a MAC!
        z_index = (d0 * M_size) + d1;
        x_index = (d0 * M_size) + d2;
        y_index = (d2 * M_size) + d1;
        z->aligned_data[z_index] +=
            x->aligned_data[x_index] * y->aligned_data[y_index];
      }
    }
  }
}

/*
for d0; d0 < 16; d0++:
for d1; d1 < 16; d1++;
for d2; d2 < 16; d2++;
  arg7[d0][d1] += arg3[d0][d2] * arg4[d2][d1]; // and this is a MAC!
*/

/*
PLAN:
1) rewrite the single loop C code version as a two-loop code version?
2) Create equivalent python workload
3) transform based on this ouput
*/

/*
#define N_size 16
#define K_size 16
#define M_size 16

extern const int8_t A[256];
extern const int8_t B[256];
extern const int32_t C_golden[256];
extern const int32_t C[256];
uint8_t Batch = 1;
// meshRow, tileSize and meshCol are defined in snax-gemm-params.h
uint8_t M_param = M_size / meshRow;
uint8_t K_param = K_size / tileSize;
uint8_t N_param = N_size / meshCol;

// Extracted from datagen.py in snitch_cluster repo
uint32_t strideInnermostA = 256;
uint32_t strideInnermostB = 256;
uint32_t strideInnermostC = 256;
uint32_t ldA = 512;
uint32_t ldB = 512;
uint32_t ldC = 512;
uint32_t strideA = 0;
uint32_t strideB = 0;
uint32_t strideC = 0;

#define tileSize 8
#define meshRow 8
#define meshCol 8

struct TwoDMemrefI32 {
  int32_t *data; // allocated pointer: Pointer to data buffer as allocated,
                 // only used for deallocating the memref
  int32_t *aligned_data; // aligned pointer: Pointer to properly aligned data
                         // that memref indexes
  uint32_t offset;
  uint32_t shape[2];
  uint32_t stride[2];
};
*/

// void printTwoDMemrefI8_t(TwoDMemrefI8_t *x){
//   // we assume 16 x 16 shape right now
//   for(int i = 0; i < x->shape[0]; i++){
//     for(int j = 0; j < x->shape[1]; j++){
//       print()

//     }
//   }
//   printf(x->aligned_data[])

// }
// void printTwoDMemrefI32_t(TwoDMemrefI8_t *y){
//   // we assume 16 x 16 shape right now
// }