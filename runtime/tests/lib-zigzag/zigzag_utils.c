#include "zigzag_utils.h"

void set_accelerator_kernel(void (*k)(void *arg0, void *arg1, void *arg2)) {
  set_kernel(k);
}

// TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
//                                TwoDMemrefI32_t *z
void _mlir_ciface_dispatch_to_accelerator(TwoDMemrefI8_t *accID, TwoDMemrefI8_t *arg0,
                                          TwoDMemrefI8_t *arg1, TwoDMemrefI32_t *arg2) {
  printf("dispatch to acc: arg0 = %x, arg1 = %x, arg2 = %x, arg3 is %x\n", (unsigned int)accID, (unsigned int)arg0,
        (unsigned int) arg1, (unsigned int)arg2);
  set_kernel_args(arg0, arg1, arg2);
  // perform tiled matmul on compute core # accID
  wake_up_compute_core(5);
  wait_for_compute_core(5);
  // wake_up_compute_core(accID);
  // wait_for_compute_core(accID);
}

void _mlir_ciface_modify_output(TwoDMemrefI8_t *arg0,TwoDMemrefI8_t *arg1,TwoDMemrefI32_t *arg2) {
  arg2->aligned_data[0] += 1;
}

void _mlir_ciface_print_my_arg(TwoDMemrefI8_t *arg) {
  printf("my arg is %x\n", (unsigned int)arg);
  print2DMemRefI8_t(arg, 5);
  arg->aligned_data[0] += 77;
  print2DMemRefI8_t(arg, 5);
}

void _mlir_ciface_print_my_arg2(uint64_t arg) {
  printf("my arg as an llvm ptr is %llx\n", arg);
}

void _mlir_ciface_print_my_arg3(uint64_t arg) {
  printf("my arg as an i64 is %llx\n", arg);
}

// void _mlir_ciface_dispatch_to_accelerator(void* accID, void *arg0,
//                                           void *arg1, void *arg2) {
//   printf("dispatch to acc: accID is %x, a = %x, b = %x, c = %x\n", accID, arg0,
//          arg1, arg2);
//   // set_kernel_args(arg0, arg1, arg2);
//   // perform tiled matmul on compute core # accID
//   wake_up_compute_core(5);
//   wait_for_compute_core(5);
//   // wake_up_compute_core(accID);
//   // wait_for_compute_core(accID);
// }

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
    void *arg3 = va_arg(cursor, void *);
    void *arg4 = va_arg(cursor, void *);
    void *arg5 = va_arg(cursor, void *);
    uint32_t fourthArg = (uint32_t)arg3;
    printf("host_acc_together: fourthArg is %d, a = %x, b = %x, c = %x\n",
           (unsigned int)fourthArg, (unsigned int)arg3, (unsigned int)arg4, (unsigned int)arg5);
    _mlir_ciface_tiled_matmul(arg0, arg1, arg2, arg3);
  }
  //_mlir_ciface_modify_output
}

void host_acc_perform_kernel_together2(kernel_ptr k, void *arg0, void *arg1,
                                       void *arg2, void *arg3) {
  if (k == (kernel_ptr)_mlir_ciface_kernel_matmul) {
    printf("host_acc_together: a = %x, b = %x, c = %x, fourthArg is %x \n",
          (unsigned int) arg0,(unsigned int) arg1, (unsigned int)arg2, (unsigned int)arg3);
    _mlir_ciface_tiled_matmul(arg0, arg1, arg2, arg3);
  }
  else if (k == (kernel_ptr)_mlir_ciface_modify_output) {
    printf("host_acc_together: a = %x, b = %x, c = %x, fourthArg is %x \n",
          (unsigned int) arg0,(unsigned int) arg1, (unsigned int)arg2, (unsigned int)arg3);
    _mlir_ciface_tiled_matmul(arg0, arg1, arg2, arg3);
  }
  else if(k == (kernel_ptr)_mlir_ciface_accelerator_work) {
    printf("host_acc_together: a = %x, b = %x, c = %x, fourthArg is %x \n",
          (unsigned int) arg0,(unsigned int) arg1, (unsigned int)arg2, (unsigned int)arg3);
    _mlir_ciface_tiled_matmul(arg0, arg1, arg2, arg3);

  }
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

void matmul_transformed(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
                               TwoDMemrefI32_t *z) {
  // only square matrices allowed
  size_t d0_1_bk_sz = MAT_WIDTH / 13;  // 8
  size_t d1_1_bk_sz = MAT_WIDTH / 13;  // 8
  size_t d2_1_bk_sz = MAT_WIDTH / 13;  // 8
   
  for (size_t d0_1 = 0; d0_1 < 13; d0_1++) { // 13 8-elt-row chunks
  
  // everything inside here should be dispatched to the accelerator (I think)
   for (size_t d1_1 = 0; d1_1 < 13; d1_1++) {
    for (size_t d2_1 = 0; d2_1 < 13; d2_1++) {
    
     // these inner three loops should be spacially unrolled, but ignore for now...
     for (size_t d0_2 = 0; d0_2 < 8; d0_2++) {
      for (size_t d1_2 = 0; d1_2 < 8; d1_2++) {
       for (size_t d2_2 = 0; d2_2 < 8; d2_2++) {
       
        // calculate indices
        size_t d0 = d0_1 * d0_1_bk_sz + d0_2;
        size_t d1 = d1_1 * d1_1_bk_sz + d1_2;
        size_t d2 = d2_1 * d2_1_bk_sz + d2_2;
        
        //perform MAC
        size_t z_index = (d0 * MAT_WIDTH) + d1;
        size_t x_index = (d0 * MAT_WIDTH) + d2;
        size_t y_index = (d2 * MAT_WIDTH) + d1;
        z->aligned_data[z_index] +=
            x->aligned_data[x_index] * y->aligned_data[y_index];
       }
      }
     }
    }
   }
  }                           
}

void matmul_transformed2(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
                               TwoDMemrefI32_t *z) {
  // only square matrices allowed
  size_t d0_1_bk_sz = MAT_WIDTH / 13;  // 8
  size_t d1_1_bk_sz = MAT_WIDTH / 13;  // 8
  size_t d2_1_bk_sz = MAT_WIDTH / 13;  // 8
   
  for (size_t d0_1 = 0; d0_1 < 13; d0_1++) { // 13 8-elt-row chunks
  
  // everything inside here should be dispatched to the accelerator (I think)
   for (size_t d1_1 = 0; d1_1 < 13; d1_1++) {
    for (size_t d2_1 = 0; d2_1 < 13; d2_1++) {
    
     // these inner three loops should be spacially unrolled, but ignore for now...
     for (size_t d0_2 = 0; d0_2 < 8; d0_2++) {
      for (size_t d1_2 = 0; d1_2 < 8; d1_2++) {
       for (size_t d2_2 = 0; d2_2 < 8; d2_2++) {
       
        // calculate indices
        //size_t d0 = d0_1 * d0_1_bk_sz + d0_2;
        size_t d0 = d0_2;
        size_t d1 = d1_1 * d1_1_bk_sz + d1_2;
        size_t d2 = d2_1 * d2_1_bk_sz + d2_2;
        
        //perform MAC
        size_t z_index = (d0 * MAT_WIDTH) + d1;
        size_t x_index = (d0 * MAT_WIDTH) + d2;
        size_t y_index = (d2 * MAT_WIDTH) + d1;
        z->aligned_data[z_index] +=
            x->aligned_data[x_index] * y->aligned_data[y_index];
        //z->aligned_data[z_index] = d0_1;
       }
      }
     }
    }
   }
  }                           
}