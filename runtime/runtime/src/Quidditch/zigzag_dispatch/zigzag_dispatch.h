
#pragma once

#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>

#include "../../../../../runtime/tests/lib-zigzag/memref.h"

// dispatch using spinlocks

extern void _mlir_ciface_mlirFunc(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b,
                                  TwoDMemrefI32_t *c);

// select the kernel the compute cores should execute,
// and provide valid addresses for the kernel's arguments
void set_kernel(void (*f)(void *a, void *b, void *c),
                void *a, void *b, void *c);

// busy wait until DMA core says to exit or perform a computation
void compute_core_loop(void);

void tell_compute_cores_to_exit(void);
void wake_up_compute_cores(void);
void wake_up_compute_core(uint32_t coreID);

// wait for all compute cores to finish computing and return to "sleep"
void wait_for_all_compute_cores(void);

// wait for a particular compute core to finish computing and return to "sleep"
void wait_for_compute_core(uint32_t coreID);

// for debugging
void printBins(void);
