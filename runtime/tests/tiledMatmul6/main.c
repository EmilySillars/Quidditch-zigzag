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
    return quidditch_dispatch_enter_worker_loop();
  }
  quidditch_dispatch_set_kernel();
  quidditch_dispatch_submit_workgroup(5);
  quidditch_dispatch_quit();
  printf("about to return 0");
  return 0;
}
