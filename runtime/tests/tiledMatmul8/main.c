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

// pwd && touch ../tests/$basename/out/stderr.txt
// $SPIKE/spike -m0x10000000:0x40000,0x80000000:0x80000000 --disable-dtb -p9
// tests/${basename^} 2> ../tests/$basename/out/stderr.txt

// // C Program for the above approach
// #include<stdio.h>
// int main()
// {
//     int i, n=2;
//     char str[50];

//     //open file sample.txt in write mode
//     FILE *fptr = fopen("sample.txt", "w");
//     if (fptr == NULL)
//     {
//         printf("Could not open file");
//         return 0;
//     }

//     for (i = 0; i < n; i++)
//     {
//         puts("Enter a name");
//         scanf("%[^\n]%*c", str);
//         fprintf(fptr,"%d.%s\n", i, str);
//     }
//     fclose(fptr);

//     return 0;
// }

int main() {
  if(snrt_is_dm_core()){
    dmaCore_wakeUpCore3();
    waitForDone();
  }

  if (!snrt_is_dm_core()) {
    if (snrt_cluster_core_idx() == 3) {
      computeCore_incrementBins();
      // stuck here
      return 0;
    } else {  // all other compute cores exit
      return 0;
    }
  }
  // dma core down here
  //dmaCore_wakeUpCore3();

  // this does not work vvv
  //   printBins();
  //   wake_up_compute_cores3();
  //   printf("wasting time...\n");
  //   tell_compute_cores_to_exit3(); // no change
  //   printBins();
  // this does not work ^^^
  return 0;
}
