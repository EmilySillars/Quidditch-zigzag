// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// #include "printf.h"
#include <Quidditch/zigzag_dispatch/zigzag_dispatch.h>

#include <assert.h>
#include <cluster_interrupt_decls.h>
#include <riscv.h>
#include <snitch_cluster_defs.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <team_decls.h>

int main() {
  if (!snrt_is_dm_core()) {
    return compute_core_loop();
  }
 // this worvs vvv
  printBins(); // 0
  wake_up_compute_cores(); // 1
  wait_for_all_compute_cores();
  printBins();
  wake_up_compute_cores(); // 2
  wait_for_all_compute_cores();
  printBins();
  wake_up_compute_cores(); // 3
  wait_for_all_compute_cores();
  printBins();
  wake_up_compute_cores(); // 4
  wait_for_all_compute_cores();
  printBins();
  printf("telling compute cores to exit after waking up...\n");    
  tell_compute_cores_to_exit(); // no change
  printBins(); 
  // this works ^^^
  return 0;
}
