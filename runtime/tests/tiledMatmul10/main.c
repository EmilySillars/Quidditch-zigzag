// adapted from
// https://github.com/KULeuven-MICAS/snax-mlir/blob/f651860981efe0da84c0e5231bfcb03faf16890a/kernels/simple_matmul/main.c

#include <Quidditch/zigzag_dispatch/zigzag_dispatch.h>

#include <assert.h>
#include <cluster_interrupt_decls.h>
#include <riscv.h>
#include <snitch_cluster_defs.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <team_decls.h>

#include "../lib-zigzag/zigzag_utils.h"
// #include <stdarg.h>

uint32_t snrt_l1_start_addr();
uint32_t snrt_l1_end_addr();

/*
All ZigZag sees is a memory hierarchy attached to a MAC array.
It recommends an optimal tiling scheme, but to implement it,
we need to carry out the correct movement of data tiles such that
everything is where it's supposed to be when each PE within the mac array runs.
We need to divide the computation and the memory transfers using a
"host-accelerator" abstraction.

Q: What level of memory is the accelerator writing its results to?
A: This marks the "host-accelerator" memory hierarchy divide;
any level of memory (and corresponding data x-fers)
ABOVE the level of memory where accelerator writes its results
is the responsiblity of the host.

We need to express the host-accelerator abstraction (using zigzag)
as well as the C-mlir abstraction (a pain in the neck)
and the DMA core - Compute Core abstraction (snitch).

"Host" (DMA core):
- allocate matrices
- set accelerator kernel (which calls set compute core kernel,
                         (which always has at most 3 args, so just setting
function pointer))
- call host-acc-perform-kernel-together (a variable length C function that
                                         picks the correct MLIR function
                                         based on the acc-kernel-workload to
execute) In MLIR, repeat for all tiles of input: select tiles and send to the
compute core (dispatch_to_accelerator) VIA a C function call which takes the 3
kernel args then copy l1 result tiles back to L3 (part of the memory transfers
needed to implement tiling scheme)

"Accelerator" (compute core):
- performs computation that takes in 3 arguments
- writes results to L1
- (that's it!)



*/

// Kernels provided via external definition
// extern void _mlir_ciface_kernel_matmul(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
//                                 TwoDMemrefI32_t *c);
extern void _mlir_ciface_matmul(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                TwoDMemrefI32_t *c);
extern void _mlir_ciface_accelerator_work(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                          TwoDMemrefI32_t *c);

void tiled_matmul_kernel(void *a, void *b, void *c, void *l1OTile) {
  TwoDMemrefI8_t *x = (TwoDMemrefI8_t *)a;
  TwoDMemrefI8_t *y = (TwoDMemrefI8_t *)b;
  TwoDMemrefI32_t *z = (TwoDMemrefI32_t *)c;
  TwoDMemrefI32_t *zz = (TwoDMemrefI32_t *)l1OTile;
  //_mlir_ciface_tiled_matmul(x, y, z, zz);
  _mlir_ciface_matmul(x, y, z);  // PINEAPPLE FIX THIS LATER!
  //_mlir_ciface_accelerator_work(x,y,z);
}
extern void _mlir_ciface_tiled_matmul(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                      TwoDMemrefI32_t *c,
                                      TwoDMemrefI32_t *l1OTile);
extern void _mlir_ciface_dummy(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                               TwoDMemrefI32_t *c, TwoDMemrefI32_t *d);
extern void _mlir_ciface_matmul_tiled_subviews(TwoDMemrefI8_t *a,
                                               TwoDMemrefI8_t *b,
                                               TwoDMemrefI32_t *c);
// this tile_compute function is not used in this program
extern void _mlir_ciface_tile_compute(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                      TwoDMemrefI32_t *c);
extern void _mlir_ciface_sendWorkToAccelerator(TwoDMemrefI8_t *a,
                                               TwoDMemrefI8_t *b,
                                               TwoDMemrefI32_t *c) {
  // set_kernel(_mlir_ciface_accelerator_work, (void *)a, (void *)b, (void *)c,
  // (void *)0);
  wake_up_compute_core(5);
  wait_for_compute_core(5);
}
// some more c functions that the mlir code has access to - not used in this
// program
void _mlir_ciface_hola(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                       TwoDMemrefI32_t *c) {
  printf("hola world!\n");
}
// int trouble = 0;  // bad global integer - TODO: get rid of this
// void _mlir_ciface_dispatch_to_accelerator(TwoDMemrefI8_t *a, TwoDMemrefI8_t
// *b,
//                                           TwoDMemrefI32_t *c) {
//   printf("calling tile compute... %d\n", trouble);
//   trouble++;
// }

// kernels to run on accelerators
void matmul_kernel(void *a, void *b, void *c) {
  TwoDMemrefI8_t *x = (TwoDMemrefI8_t *)a;
  TwoDMemrefI8_t *y = (TwoDMemrefI8_t *)b;
  TwoDMemrefI32_t *z = (TwoDMemrefI32_t *)c;
  _mlir_ciface_matmul(x, y, z);
}

void dummy_kernel(void *a, void *b, void *c) {
  TwoDMemrefI8_t *x = (TwoDMemrefI8_t *)a;
  TwoDMemrefI8_t *y = (TwoDMemrefI8_t *)b;
  TwoDMemrefI32_t *z = (TwoDMemrefI32_t *)c;
  //_mlir_ciface_tiled_matmul(x, y, z, zz);
  _mlir_ciface_kernel_matmul(x, y, z);
}

void tiled_matmul_w_subviews_kernel(void *a, void *b, void *c) {
  TwoDMemrefI8_t *x = (TwoDMemrefI8_t *)a;
  TwoDMemrefI8_t *y = (TwoDMemrefI8_t *)b;
  TwoDMemrefI32_t *z = (TwoDMemrefI32_t *)c;
  _mlir_ciface_matmul_tiled_subviews(x, y, z);
}

void hola_kernel(void *a, void *b, void *c) {
  TwoDMemrefI8_t *x = (TwoDMemrefI8_t *)a;
  TwoDMemrefI8_t *y = (TwoDMemrefI8_t *)b;
  TwoDMemrefI32_t *z = (TwoDMemrefI32_t *)c;
  printf("fake kernel hola!\n");
}

int main() {
  if (!snrt_is_dm_core()) {
    compute_core_loop();
    return 0;
  }

  // Create memref objects for data stored in L3
  TwoDMemrefI32_t memrefC;  // output
  memrefC.data = (int32_t *)malloc(sizeof(int32_t) * MAT_WIDTH_SQUARED);
  memrefC.aligned_data = memrefC.data;
  memrefC.offset = 0;
  TwoDMemrefI32_t memrefGolden;
  memrefGolden.data = (int32_t *)malloc(sizeof(int32_t) * MAT_WIDTH_SQUARED);
  memrefGolden.aligned_data = memrefGolden.data;
  memrefGolden.offset = 0;

  // Create memref objects for data stored in L1
  TwoDMemrefI8_t memrefA;  // input
  memrefA.data = (int8_t *)snrt_l1_start_addr();
  memrefA.aligned_data = memrefA.data;
  memrefA.offset = 0;
  TwoDMemrefI8_t memrefB;  // weight
  memrefB.data =
      (int8_t *)(snrt_l1_start_addr() + sizeof(int8_t) * MAT_WIDTH_SQUARED);
  memrefB.aligned_data = memrefB.data;
  memrefB.offset = 0;

  // initialize the matrices
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++) {
    memrefA.aligned_data[i] = (int8_t)2;
  }
  for (size_t i = 0; i < MAT_WIDTH_SQUARED; i++) {
    memrefB.aligned_data[i] = (int8_t)3;
  }

  // perform C code matmul to get the ground truth
  cCodeEquivalentThreeLoops(&memrefA, &memrefB, &memrefGolden);

  // Create memref object for output slice stored in L1
  TwoDMemrefI32_t memrefOSlice;  // output
  memrefOSlice.data = (int32_t *)(snrt_l1_start_addr() +
                                  sizeof(int32_t) * MAT_WIDTH_SQUARED * 2);
  memrefOSlice.aligned_data = memrefOSlice.data;
  memrefOSlice.offset = 0;

  // prepare compute core for matmul operation
  // set_kernel(tiled_matmul_w_subviews_kernel, (void *)&memrefA, (void
  // *)&memrefB,
  //            (void *)&memrefC);

  // set_kernel(tiled_matmul_kernel, (void *)&memrefA, (void *)&memrefB,
  //            (void *)&memrefC, (void *) &memrefOSlice);
  printf("main: a = %x, b = %x, c = %x\n",&memrefA,&memrefB,&memrefC);
  set_kernel((kernel_ptr)_mlir_ciface_kernel_matmul);
  set_kernel_args((void *)&memrefA, (void *)&memrefB, (void *)&memrefC);
  // perform tiled matmul on compute core #5
  host_acc_perform_kernel_together((kernel_ptr)_mlir_ciface_kernel_matmul,
                                   &memrefA, (void *)&memrefB, (void *)&memrefC,
                                   87);
  // wake_up_compute_core(5);
  // wait_for_compute_core(5);

  // launch compute core 13 times
  // set_kernel(hola_kernel, (void *)&memrefA, (void *)&memrefB, (void
  // *)&memrefC); for (size_t i = 0; i < 13; i++) {
  //   wake_up_compute_core(5);
  //   wait_for_compute_core(5);
  // }

  // maybe we need to call tiled matmul and then modify tiledmatul to use
  // subviews and THEN dispatch part of the matmul to the compute core

  // check for correctness
  int nerr = 0;
  for (int i = 0; i < MAT_WIDTH_SQUARED; i++) {
    int32_t error = memrefC.aligned_data[i] - memrefGolden.aligned_data[i];
    if (error != 0) {
      nerr += 1;
      printf(" i is %d and %d /= %d\n", i, memrefC.aligned_data[i],
             memrefGolden.aligned_data[i]);
      break;
    }
  }

  if (nerr != 0) {
    printf("Output does not match the golden value!\n");
  } else {
    printf("Output Correct\n");
  }

  // free everything before exiting!
  free(memrefC.data);
  free(memrefGolden.data);

  // tell all compute cores (really just compute core 5) to exit
  tell_compute_cores_to_exit();
  return nerr;
}
