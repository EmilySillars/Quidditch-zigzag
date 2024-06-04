// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// #include "printf.h"
#include <Quidditch/janky_dispatch/janky_dispatch.h>
#include <stdio.h>
#include <assert.h>
#include <cluster_interrupt_decls.h>
#include <riscv.h>
#include <snitch_cluster_defs.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <team_decls.h>

// replacing snrt_cluster_compute_core_idx with 77
// replacing snrt_cluster_compute_core_num() with 78
// replacing snrt_cluster_dm_core_idx with 66
int main() {
    // uint32_t core_idx = snrt_global_core_idx();
    // uint32_t core_num = snrt_global_core_num();

    // printf("# hart %d global core %d(%d) ", snrt_hartid(),
    //        snrt_global_core_idx(), snrt_global_core_num());
    // printf("in cluster %d(%d) ", snrt_cluster_idx(), snrt_cluster_num());
    // printf("cluster core %d(%d) ", snrt_cluster_core_idx(),
    //        snrt_cluster_core_num());
    // printf("compute core %d(%d) ", 77,
    //        88);
    // printf("dm core %d(%d) ", 66,
    //        snrt_cluster_dm_core_num());
    // printf("compute: %d dm: %d ", snrt_is_compute_core(), snrt_is_dm_core());
    // printf("\n");

    // printf("# global mem [%#llx:%#llx] cluster mem [%#llx:%#llx] ",
    //        snrt_global_memory().start, snrt_global_memory().end,
    //        snrt_cluster_memory().start, snrt_cluster_memory().end);
    // printf("\n");

    return 0;
}
