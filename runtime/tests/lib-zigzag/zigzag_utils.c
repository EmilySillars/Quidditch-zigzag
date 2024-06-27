#include "zigzag_utils.h"

void set_accelerator_computation(void (*k)(void *arg0, void *arg1,
                                           void *arg2)) {
  set_kernel(k);
}

void host_acc_perform_kernel_together(kernel_ptr k, void *arg0, void *arg1,
                                      void *arg2, void *arg3) {
  if (k == (kernel_ptr)_mlir_ciface_tiled_matmul) {
    _mlir_ciface_tiled_matmul(arg0, arg1, arg2, arg3);
  } else if (k == (kernel_ptr)_mlir_ciface_dummy) {
    _mlir_ciface_dummy(arg0, arg1, arg2, arg3);
  }
}

void host_acc_perform_kernel_together_2_slices(kernel_ptr k, void *arg0, void *arg1,
                                      void *arg2, void *slice1, void *slice2) {
  _mlir_ciface_dummy(arg0, arg1, arg2, slice1);
  //_mlir_ciface_tiled_matmul_2_slices(arg0, arg1, arg2, slice1, slice2);
}

void _mlir_ciface_dispatch_to_accelerator(uint32_t accID, TwoDMemrefI8_t *arg0,
                                          TwoDMemrefI8_t *arg1,
                                          TwoDMemrefI32_t *arg2) {
  set_kernel_args(arg0, arg1, arg2);
  // perform tiled matmul on compute core # accID
  wake_up_compute_core(accID);
  wait_for_compute_core(accID);
}

// A C function accessible to MLIR
void _mlir_ciface_hola(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                       TwoDMemrefI32_t *c) {
  printf("hola world!\n");
}

// c-code implementation of matmul (to check correctness of MLIR)
void cCodeSquareMatmul(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
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

// printing functions
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

void print2DMemRefI32_t_notASquare(TwoDMemrefI32_t *x, int32_t stride_x,
                                   int32_t stride_y) {
  printf("[\n");
  int32_t col = 0;
  for (int i = 0; i < stride_x * stride_y; i++) {
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