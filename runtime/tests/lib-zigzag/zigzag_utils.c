#include "zigzag_utils.h"

void set_accelerator_kernel(void (*k)(void *arg0, void *arg1, void *arg2)) {
  set_kernel(k);
}

void _mlir_ciface_dispatch_to_accelerator(uint32_t accID, void *arg0, void *arg1,
                             void *arg2) {
  printf("dispatch to acc: accID is %d, a = %x, b = %x, c = %x\n",accID, arg0, arg1, arg2);
 // set_kernel_args(arg0, arg1, arg2);
  // perform tiled matmul on compute core # accID
  wake_up_compute_core(accID);
  wait_for_compute_core(accID);
}

/*

int foo(int cnt, ...);
To access variable arguments normally you use the definitions in <stdarg.h>
header in the following way:

int foo(int cnt, ...)
{
  va_list ap;  //pointer used to iterate through parameters
  int i, val;

  va_start(ap, cnt);    //Initialize pointer to the last known parameter

  for (i=0; i<cnt; i++)
  {
    val = va_arg(ap, int);  //Retrieve next parameter using pointer and size
    printf("%d ", val);     // Print parameter, an integer
  }

  va_end(ap);    //Release pointer. Normally do_nothing

  putchar('\n');
} */

// each example program should have its own implementation of this function

void host_acc_perform_kernel_together(kernel_ptr k, void *arg0, void *arg1,
                                      void *arg2, ...) {
  va_list cursor;
  va_start(cursor, arg2);
  if (k == (kernel_ptr)_mlir_ciface_kernel_matmul) {
    printf("hoodle\n");
    void *arg3 = va_arg(cursor, void *);
    uint32_t fourthArg = (uint32_t) arg3;
    printf("fourthArg is %d, a = %x, b = %x, c = %x\n",fourthArg, arg0, arg1,arg2);
    _mlir_ciface_tiled_matmul(arg0, arg1, arg2, arg3);
  }

  // switch (k) {
  //   case _mlir_ciface_kernel_matmul:
  //   void* arg3;
  //     for (size_t i = 0; i < 4; i++) {
  //     }
  //     break;
  //   default:
  //     // for (size_t i = 0; i < 5; i++) {
  //     // }
  //     break;
  // }
}

// c-code implementation of kernels (to check correctness of MLIR)
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
