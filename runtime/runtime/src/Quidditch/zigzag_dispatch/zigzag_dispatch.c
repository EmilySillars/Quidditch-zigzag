

#include "zigzag_dispatch.h"
#include "../../../../../runtime/tests/lib-zigzag/memref.h"
#include <assert.h>
#include <cluster_interrupt_decls.h>
#include <riscv.h>
#include <snitch_cluster_defs.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <team_decls.h>

// dispatch using spinlocks

// TODO: remove use of magic number 8
// TODO: This should be cluster local.
static struct cluster_state_t {
  int bins[9];
  atomic_bool sleep[9];
  atomic_bool exit;
  kernel_ptr k[9];
  void *a[9];
  void *b[9];
  void *c[9];
} cluster_state = {
    {0, 0, 0, 0, 0, 0, 0, 0, 0},
    {false, false, false, false, false, false, false, false, false},
    false,
    {0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0}
    };

void set_kernel(kernel_ptr g){
  for (size_t i = 0; i < 8; i++) {
    cluster_state.k[i] = g;
  }
}

void set_kernel_args(uint32_t coreID, void *a, void *b, void *c){
  cluster_state.a[coreID] = a;
  cluster_state.b[coreID] = b;
  cluster_state.c[coreID] = c;
}

void compute_core_loop() {
  uint32_t myId = snrt_cluster_core_idx();
  while (!cluster_state.exit) {
    // sleep
    cluster_state.sleep[myId] = true;
    while (cluster_state.sleep[myId]) {
      ;
    }
    // If didn't get woken up to exit,
    if (!cluster_state.exit) {
      // do something
      (*cluster_state.k[myId])(cluster_state.a[myId], cluster_state.b[myId], cluster_state.c[myId]);
      cluster_state.bins[myId]++;
    }
  }
}

void tell_compute_cores_to_exit() {
  cluster_state.exit = true;
  // cores can't cluster_state.exit until they wake up
  wake_up_compute_cores();
}

void wake_up_compute_core(uint32_t coreID) {
  cluster_state.sleep[coreID] = false;
}

void wake_up_compute_cores() {
  for (size_t i = 0; i < 8; i++) {
    cluster_state.sleep[i] = false;
  }
}

void wait_for_compute_core(uint32_t coreID) {
  while (!cluster_state.sleep[coreID]) {
  }
}

void wait_for_all_compute_cores() {
  while (!(cluster_state.sleep[0] && cluster_state.sleep[1] &&
           cluster_state.sleep[2] && cluster_state.sleep[3] &&
           cluster_state.sleep[4] && cluster_state.sleep[5] &&
           cluster_state.sleep[6] && cluster_state.sleep[7])) {
  }
}

void printBins() {
  printf("bins: %d %d %d %d %d %d %d %d %d\n", cluster_state.bins[0],
         cluster_state.bins[1], cluster_state.bins[2], cluster_state.bins[3],
         cluster_state.bins[4], cluster_state.bins[5], cluster_state.bins[6],
         cluster_state.bins[7], cluster_state.bins[8]);
}