#include "zigzag_utils.h"

void set_accelerator_computation(uint32_t accID, kernel_ptr k) {
  set_kernel(accID,k);
}

void host_acc_perform_kernel_together(kernel_ptr k, void *arg0, void *arg1,
                                      void *arg2, void *arg3) {
  if (k == (kernel_ptr)_mlir_ciface_tiled_matmul) {
    _mlir_ciface_tiled_matmul(arg0, arg1, arg2, arg3);
  } else if (k == (kernel_ptr)_mlir_ciface_dummy) {
    _mlir_ciface_dummy(arg0, arg1, arg2, arg3);
  }
}

void host_acc_perform_kernel_together_2_slices(kernel_ptr k, void *arg0,
                                               void *arg1, void *arg2,
                                               void *slice1, void *slice2) {
  // TODO: fix so this uses pinapple
  _mlir_ciface_pineapple(arg0, arg1, arg2, slice1, slice2);
  //_mlir_ciface_tiled_matmul_2_slices(arg0, arg1, arg2, slice1, slice2);
}

void _mlir_ciface_dispatch_to_accelerator(uint32_t accID, TwoDMemrefI8_t *arg0,
                                          TwoDMemrefI8_t *arg1,
                                          TwoDMemrefI32_t *arg2) {
  set_kernel_args(accID, arg0, arg1, arg2);
  // perform tiled matmul on compute core # accID
  wake_up_compute_core(accID);
}

void  _mlir_ciface_wait_for_accelerator(uint32_t accID){
  wait_for_compute_core(accID);
}

// A C function accessible to MLIR
void _mlir_ciface_hola(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                       TwoDMemrefI32_t *c) {
  printf("hola world!\n");
}

void _mlir_ciface_memrefCopy8bit(TwoDMemrefI8_t *src, TwoDMemrefI8_t *dst) {
  for (size_t row = 0; row < src->shape[0]; row++) {
    for (size_t col = 0; col < src->shape[1]; col++) {
      dst->aligned_data[dst->offset + (dst->stride[0] * row) +
                        (col * dst->stride[1])] =
          src->aligned_data[src->offset + (src->stride[0] * row) +
                            (col * src->stride[1])];
    }
  }
}

void _mlir_ciface_memrefCopy8bit_I_104x104(TwoDMemrefI8_t *src, TwoDMemrefI8_t *dst) {
  for (size_t row = 0; row < src->shape[0]; row++) {
    for (size_t col = 0; col < src->shape[1]; col++) {
      dst->aligned_data[dst->offset + (dst->stride[0] * row) +
                        (col * dst->stride[1])] =
          src->aligned_data[src->offset + (src->stride[0] * row) +
                            (col * src->stride[1])];
    }
  }
}

void _mlir_ciface_memrefCopy8bit_W_104x104(TwoDMemrefI8_t *src, TwoDMemrefI8_t *dst) {
  for (size_t row = 0; row < src->shape[0]; row++) {
    for (size_t col = 0; col < src->shape[1]; col++) {
      // printf("I see the value %d",dst->aligned_data[dst->offset + (dst->stride[0] * row) +
      //                   (col * dst->stride[1])]);
      dst->aligned_data[dst->offset + (dst->stride[0] * row) +
                        (col * dst->stride[1])] =
          src->aligned_data[src->offset + (src->stride[0] * row) +
                            (col * src->stride[1])];
    }
  }
}

void _mlir_ciface_memrefCopy32bit(TwoDMemrefI32_t *src, TwoDMemrefI32_t *dst) {
  for (size_t row = 0; row < src->shape[0]; row++) {
    for (size_t col = 0; col < src->shape[1]; col++) {
      dst->aligned_data[dst->offset + dst->stride[0] * row +
                        col * dst->stride[1]] =
          src->aligned_data[src->offset + src->stride[0] * row +
                            col * src->stride[1]];
    }
  }
}

void _mlir_ciface_memrefCopy32bit_O_104x13(TwoDMemrefI32_t *src, TwoDMemrefI32_t *dst){
  for (size_t row = 0; row < src->shape[0]; row++) {
    for (size_t col = 0; col < src->shape[1]; col++) {
      dst->aligned_data[dst->offset + dst->stride[0] * row +
                        col * dst->stride[1]] =
          src->aligned_data[src->offset + src->stride[0] * row +
                            col * src->stride[1]];
    }
  }
}

void _mlir_ciface_memrefCopy32bit_O_104x1(TwoDMemrefI32_t *src, TwoDMemrefI32_t *dst){
  for (size_t row = 0; row < src->shape[0]; row++) {
    for (size_t col = 0; col < src->shape[1]; col++) {
      dst->aligned_data[dst->offset + dst->stride[0] * row +
                        col * dst->stride[1]] =
          src->aligned_data[src->offset + src->stride[0] * row +
                            col * src->stride[1]];
    }
  }
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