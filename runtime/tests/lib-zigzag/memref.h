#pragma once

#include <stdint.h>
#include <stdio.h>

struct OneDMemrefI32 {
  int32_t *data; // allocated pointer: Pointer to data buffer as allocated,
                 // only used for deallocating the memref
  int32_t *aligned_data; // aligned pointer: Pointer to properly aligned data
                         // that memref indexes
  uint32_t offset;
  uint32_t shape[1];
  uint32_t stride[1];
};

struct TwoDMemrefI32 {
  int32_t *data; // allocated pointer: Pointer to data buffer as allocated,
                 // only used for deallocating the memref
  int32_t *aligned_data; // aligned pointer: Pointer to properly aligned data
                         // that memref indexes
  uint32_t offset;
  uint32_t shape[2];
  uint32_t stride[2];
};

struct TwoDMemrefI8 {
  int8_t *data; // allocated pointer: Pointer to data buffer as allocated,
                // only used for deallocating the memref
  int8_t *aligned_data; // aligned pointer: Pointer to properly aligned data
                        // that memref indexes
  uint32_t offset;
  uint32_t shape[2];
  uint32_t stride[2];
};

typedef struct OneDMemrefI32 OneDMemrefI32_t;
typedef struct TwoDMemrefI8 TwoDMemrefI8_t;
typedef struct TwoDMemrefI32 TwoDMemrefI32_t;

// we assume square matrices
#define MAT_WIDTH 104
#define MAT_WIDTH_SQUARED (MAT_WIDTH * MAT_WIDTH)

// compute mat mul
void cCodeEquivalentThreeLoops(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
                               TwoDMemrefI32_t *z);
// helper functions
void cCodeEquivalent(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y, TwoDMemrefI32_t *z);
void print2DMemRefI8_t(TwoDMemrefI8_t *x, int32_t width);
void print2DMemRefI32_t(TwoDMemrefI32_t *x, int32_t width);
void print2DMemRefI32_t_notASquare(TwoDMemrefI32_t *x, int32_t stride_x, int32_t stride_y);
