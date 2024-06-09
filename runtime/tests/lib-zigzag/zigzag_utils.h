// all the defintions needed for ZigZag integration

#include "memref.h" // from KULeuven's snax-mlir repo

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