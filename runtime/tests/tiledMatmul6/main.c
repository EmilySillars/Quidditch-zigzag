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
// $SPIKE/spike -m0x10000000:0x40000,0x80000000:0x80000000 --disable-dtb -p9 tests/${basename^} 2> ../tests/$basename/out/stderr.txt

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
  if (!snrt_is_dm_core()) {
    return compute_core_loop();
  }
  // quidditch_dispatch_set_kernel();
  // quidditch_dispatch_submit_workgroup(5);
  // quidditch_dispatch_quit();
  //wake_all_workers();
 // tell_compute_cores_to_exit();
  //setup_outputs();
 // close_outputs();
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
  return 0;
}
