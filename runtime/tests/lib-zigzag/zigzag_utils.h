// all the defintions needed for ZigZag integration
// we assume square matrices (for now)

#include "memref.h" // from KULeuven's snax-mlir repo: https://github.com/KULeuven-MICAS/snax-mlir/blob/4666236ffd848eff1a4634c824ad257ba68d9a64/runtime/include/memref.h
#include <stdarg.h>
#include <Quidditch/zigzag_dispatch/zigzag_dispatch.h>

#ifndef MAT_WIDTH
#define MAT_WIDTH 104
#endif
#define MAT_WIDTH_SQUARED (MAT_WIDTH * MAT_WIDTH)

// compute matrix multiplication (for checking mlir matmul correctness)
void cCodeEquivalentThreeLoops(TwoDMemrefI8_t *x, TwoDMemrefI8_t *y,
                               TwoDMemrefI32_t *z);

// printing functions to help with debugging
void print2DMemRefI8_t(TwoDMemrefI8_t *x, int32_t width);
void print2DMemRefI32_t(TwoDMemrefI32_t *x, int32_t width);
void print2DMemRefI32_t_notASquare(TwoDMemrefI32_t *x, int32_t stride_x, int32_t stride_y);

/*
All ZigZag sees is a memory hierarchy attached to a MAC array.
It recommends an optimal tiling scheme, but to implement it,
we need to carry out the correct movement of data tiles such that 
everything is where it's supposed to be when each PE within the mac array runs.
To implement the correct data movement for ZigZag's schedule,
we employ a "host-accelerator" abstraction.
*/

// DL Kernels Defined in MLIR
extern void _mlir_ciface_kernel_matmul(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                TwoDMemrefI32_t *c);
extern void _mlir_ciface_kernel_1dConv(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                TwoDMemrefI32_t *c);


void _mlir_ciface_print_my_arg(TwoDMemrefI8_t *arg);
void _mlir_ciface_print_my_arg2(uint64_t arg);
void _mlir_ciface_print_my_arg3(uint64_t arg);

// "Host" function calls

// tell the accelerator which kernel it should perform
// all kernels have three arguments, and are passed as function pointers
// for now, all accelerators must perform the same kernel
void set_accelerator_kernel(void (*k)(void *arg0, void *arg1, void *arg2));


void host_acc_perform_kernel_together(kernel_ptr k,void *arg0, void *arg1,
                                                void *arg2, ...);
// MLIR funcs for tiled kernels
extern void _mlir_ciface_dummy(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                               TwoDMemrefI32_t *c, TwoDMemrefI32_t *d);
extern void _mlir_ciface_tiled_matmul(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                      TwoDMemrefI32_t *c,
                                      TwoDMemrefI32_t *l1OTile);

// dispatch workload to accelerator with id accID
//void _mlir_ciface_dispatch_to_accelerator(void* accID, void* arg0, void* arg1, void* arg2);
void _mlir_ciface_dispatch_to_accelerator(TwoDMemrefI8_t *accID, TwoDMemrefI8_t *arg0,
                                          TwoDMemrefI8_t *arg1, TwoDMemrefI32_t *arg2);
void host_acc_perform_kernel_together2(kernel_ptr k, void *arg0, void *arg1,
                                      void *arg2, void* arg3);
/*
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
                         (which always has at most 3 args, so just setting function pointer))
- call host-acc-perform-kernel-together (a variable length C function that 
                                         picks the correct MLIR function
                                         based on the acc-kernel-workload to execute)
  In MLIR,
  repeat for all tiles of input:
    select tiles and send to the compute core (dispatch_to_accelerator)
    VIA a C function call which takes the 3 kernel args
    then copy l1 result tiles back to L3 (part of the memory transfers needed to implement tiling scheme)

"Accelerator" (compute core):
- performs computation that takes in 3 arguments
- writes results to L1
- (that's it!)
*/