

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

// void timefunc(void (*f)(), squareMat *a, squareMat *b, squareMat *c,
//               uint64_t n) {
//   time_t beforeTime, afterTime;
//   double diff;
//   char *fnm;

//   if (f == multmat) {
//     fnm = "multmat";
//     time(&beforeTime); // save time before execution
//     multmat(a, b, c);  // execute function multmat
//   } 
//   // else if (f == multmatTiled) {
//   //   fnm = "multmatTiled";
//   //   time(&beforeTime);     // save time before execution
//   //   multmatTiled(a, b, c); // execute function multmatTiled
//   // } 
//   else if (f == multmatTiledGeneral) {
//     fnm = "multmatTiledGeneral";
//     time(&beforeTime);               // save time before execution
//     multmatTiledGeneral(a, b, c, n); // execute function multmatTiledGeneral
//   } else {
//     fprintf(stderr, "ERR: function to time not recognized\n");
//     return;
//   }
//   time(&afterTime);                       // save time after execution
//   diff = difftime(afterTime, beforeTime); // compute difference
//   printf("Time to execute %s: %f\n", fnm, diff);
// }

// TODO: This should be cluster local.
static struct cluster_state_t {
  int bins[9];
  atomic_bool sleep[9];
  atomic_bool exit;
  int (*f)(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c);
  TwoDMemrefI8_t *a;
  TwoDMemrefI8_t *b;
  TwoDMemrefI32_t *c;
} cluster_state = {
    {0, 0, 0, 0, 0, 0, 0, 0, 0},
    {false, false, false, false, false, false, false, false, false},
    false};

// void set_kernel(int (*f)(void * args[]), void * args[]){
//   cluster_state.f = f;
//   cluster_state.args = args;
// }

void set_kernel(int (*f)(TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c), TwoDMemrefI8_t *a, TwoDMemrefI8_t *b, TwoDMemrefI32_t *c){
  cluster_state.f = f;
  cluster_state.a = a;
  cluster_state.b = b;
  cluster_state.c = c;
}

int compute_core_loop() {
  int error = 0;
  int result = 0;
  while (!cluster_state.exit) {
    // sleep
    cluster_state.sleep[snrt_cluster_core_idx()] = true;
    while (cluster_state.sleep[snrt_cluster_core_idx()]) {
      ;
    }
    // If didn't get woken up to exit,
    if (!cluster_state.exit) {
      // do something
      result = (*cluster_state.f)(cluster_state.a, cluster_state.b, cluster_state.c);
      error = error ? 1 : result; 
      cluster_state.bins[snrt_cluster_core_idx()]++;
    }
  }
  return error;
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