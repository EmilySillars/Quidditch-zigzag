

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

#include "zigzag_dispatch.h"

// TODO: This should be cluster local.
static struct worker_metadata_t {
  atomic_uint workers_waiting;
  atomic_bool exit;
} worker_metadata = {0, false};

// operation dumb down the code vvvvvvvvvvvvvvvvvvvvvvvvvv

int bins[9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
atomic_bool sleep[9] = {false, false, false, false, false,
                        false, false, false, false};
atomic_bool sleeping = true;
atomic_bool done = false;

int compute_core_loop() {
  // snrt_interrupt_enable(IRQ_M_CLUSTER);  // extremely important! enables
  //  interrupts on the cluster!!!
  bins[snrt_cluster_core_idx()] = snrt_cluster_core_idx();
  while (!worker_metadata.exit) {
    // sleep
    sleep[snrt_cluster_core_idx()] = true;
    while (sleep[snrt_cluster_core_idx()]) {
      ;
    }
    // If didn't get woken up to exit,
    if (!worker_metadata.exit) {
      // do something
      bins[snrt_cluster_core_idx()]++;
    }
  }
  // snrt_interrupt_disable(IRQ_M_CLUSTER);
  return 0;
}

void tell_compute_cores_to_exit() {
  worker_metadata.exit = true;
  // cores can't exit until they wake up
  wake_up_compute_cores();
}

void wake_up_compute_cores() {
  for (size_t i = 0; i < 8; i++) {
    sleep[i] = false;
  }
}

void wait_for_all_compute_cores() {
  while (!(sleep[0] && sleep[1] && sleep[2] && sleep[3] && sleep[4] &&
           sleep[5] && sleep[6] && sleep[7])) {
  }
}

// let's try using wfi
// -------------------------------------------------------------------

int computeCore_callWFI() {
  snrt_interrupt_enable(IRQ_M_CLUSTER);
  asm volatile("wfi");                                 // sleep
  snrt_int_cluster_clr(1 << snrt_cluster_core_idx());  // clear interrupt

  snrt_interrupt_disable(IRQ_M_CLUSTER);
  return 0;
}

void computeCore_incrementBins() {
  for (size_t i = 0; i < 3; i++) {
    // printf("core: %d i:%d\n",snrt_cluster_core_idx(),i);
    bins[snrt_cluster_core_idx()]++;
    // printBins();
  }
  printf("put core %d to sleep\n", snrt_cluster_core_idx());
  done = true;
  printf("compute core: done is %d\n", done);
  computeCore_callWFI();
  printf("after wfi: %d \n", snrt_cluster_core_idx());
}

void dmaCore_wakeUpCore3() {
  // uint32_t compute_cores = snrt_cluster_compute_core_num();
  // snrt_int_cluster_set((1 << compute_cores) - 1);
  // printf("I have core ID %d and I'm waking up
  // core 3...\n",snrt_cluster_core_idx());
  snrt_int_cluster_set((1 << 3) - 1);
  // printBins();
}
void waitForDone() {
  // printf("dma: done is %d\n",done);
  while (done == 1) {
    dmaCore_wakeUpCore3();
    // printf("not done yet\n");
  }
  // printf("dma: exiting: done is %d\n",done);
}

int compute_core_loop2() {
  snrt_interrupt_enable(IRQ_M_CLUSTER);  // extremely important! enables
                                         // interrupts on the cluster!!!
  bins[snrt_cluster_core_idx()] = snrt_cluster_core_idx();
  while (!worker_metadata.exit) {
    sleep[snrt_cluster_core_idx()] = true;
    asm volatile("wfi");                                 // sleep
    snrt_int_cluster_clr(1 << snrt_cluster_core_idx());  // clear interrupt
    sleep[snrt_cluster_core_idx()] = false;
    // If didn't get woken up to exit,
    if (!worker_metadata.exit) {
      // do something
      bins[snrt_cluster_core_idx()]++;
    } else {
      bins[snrt_cluster_core_idx()]--;
    }
  }
  snrt_interrupt_disable(IRQ_M_CLUSTER);
  return 0;
}

void tell_compute_cores_to_exit2() {
  worker_metadata.exit = true;
  // cores can't exit until they wake up
  wake_up_compute_cores2();
}

void wake_up_compute_cores2() {
  uint32_t compute_cores = snrt_cluster_compute_core_num();
  snrt_int_cluster_set((1 << compute_cores) - 1);
  // snrt_int_cluster_set(~0x1 &((1 << compute_cores) - 1));
  // snrt_int_cluster_set(0xFFFF);
}

void wait_for_all_compute_cores2() {
  while (!(sleep[0] && sleep[1] && sleep[2] && sleep[3] && sleep[4] &&
           sleep[5] && sleep[6] && sleep[7])) {
  }
}

void printBins() {
  printf("bins: %d %d %d %d %d %d %d %d %d\n", bins[0], bins[1], bins[2],
         bins[3], bins[4], bins[5], bins[6], bins[7], bins[8]);
}

// ---- third time is the charm
// ---------------------=======================================
int compute_core_loop3() {
  snrt_interrupt_enable(IRQ_M_CLUSTER);  // extremely important! enables
                                         // interrupts on the cluster!!!
  while (!worker_metadata.exit) {
    asm volatile("wfi");                                 // sleep
    snrt_int_cluster_clr(1 << snrt_cluster_core_idx());  // clear interrupt
    sleep[snrt_cluster_core_idx()] = false;
    sleeping = false;
    // If didn't get woken up to exit,
    if (!worker_metadata.exit) {
      // do something
      bins[snrt_cluster_core_idx()]++;
    }
  }
  snrt_interrupt_disable(IRQ_M_CLUSTER);
  return 0;
}
void wake_up_compute_cores3() {
  uint32_t compute_cores = snrt_cluster_compute_core_num();
  snrt_int_cluster_set((1 << compute_cores) - 1);
}
void tell_compute_cores_to_exit3() {
  worker_metadata.exit = true;
  // cores can't exit until they wake up
  wake_up_compute_cores3();
  wait_for_one_compute_core();
}

// wait for one compute core to wake up
void wait_for_one_compute_core() {
  while (sleeping) {
  }
}

//  operation dumb down the code ^^^^^^^^^^^^^^^^^^^^^^^^^^

// TODO: All of this synchronization in this file could use hardware barriers
// which might be more efficient.
static void park_worker() {
  worker_metadata
      .workers_waiting++;  // maintains information about the cluster; uses
                           // atomic vars because ANY core can access this
  asm volatile(
      "wfi");  // sleep until you get woken up by cluster local interrupt
  snrt_int_cluster_clr(
      1 << snrt_cluster_core_idx());  // immediately clear the interrupt because
                                      // we have woken up
  bins[snrt_cluster_core_idx()] = snrt_cluster_core_idx();
  worker_metadata.workers_waiting--;
}

void wake_all_workers() {
  assert(snrt_is_dm_core() && "DM core is currently our host");
  uint32_t compute_cores = snrt_cluster_compute_core_num();
  // Compute cores are indices 0 to compute_cores.
  snrt_int_cluster_set((1 << compute_cores) - 1);
  // use bitmask to wake up compute cores using a
  // local cluster interrupt!!!
  printf("wake all workers: (1 << compute_cores) - 1 is %d\n",
         (1 << compute_cores) - 1);
}

void quidditch_dispatch_wait_for_workers() {
  assert(snrt_is_dm_core() && "DM core is currently our host");
  // Spin until all compute corkers are parked.
  // printf("waiting for workers -- workers_waiting: %d exit: %d\n",
  //        worker_metadata.workers_waiting, worker_metadata.exit);
  printf(
      "inside wait for workers (before while loop): workers_waiting: %d exit: "
      "%d\n",
      worker_metadata.workers_waiting, worker_metadata.exit);
  printf("snrt_cluster_compute_core_num() is %d\n",
         snrt_cluster_compute_core_num());

  // while the number of workers waiting /= computee core num)
  while (worker_metadata.workers_waiting != snrt_cluster_compute_core_num())

    ;
  printf(
      "inside wait for workers (after while loop): workers_waiting: %d exit: "
      "%d\n",
      worker_metadata.workers_waiting, worker_metadata.exit);
  // printf("waited for workers -- workers_waiting: %d exit: %d\n",
  //        worker_metadata.workers_waiting, worker_metadata.exit);
}

// TODO: This only works for a single cluster by using globals. Should be
// cluster local.
static atomic_bool error = false;

bool quidditch_dispatch_errors_occurred() { return error; }

void quidditch_dispatch_set_kernel() {
  // set function pointer
  // printf("inside set kernel: workers_waiting: %d exit: %d\n",
  //        worker_metadata.workers_waiting, worker_metadata.exit);
}

int quidditch_dispatch_enter_worker_loop() {
  snrt_interrupt_enable(IRQ_M_CLUSTER);  // extremely important! enables
                                         // interrupts on the cluster!!!
  // printf("start of enter worker loop\n");
  // worker_metadata.exit = true;
  while (!worker_metadata.exit) {
    park_worker();
    if (worker_metadata.exit) break;

    // replace following with call to Kernel
    // if (configuredKernel(configuredEnvironment, configuredDispatchState,
    //                      &configuredWorkgroupState[snrt_cluster_core_idx()]))
    //  error = true;
    // printf("hola\n");
  }
  // printf("end\n");
  // snrt_interrupt_disable(IRQ_M_CLUSTER);
  return 0;
}

void quidditch_dispatch_quit() {
  // printf("inside dispatch quit (before waiting): workers_waiting: %d exit:
  // %d\n",
  //        worker_metadata.workers_waiting, worker_metadata.exit);
  // printf("quidditch_dispatch_quit- workers_waiting: %d exit: %d\n",
  //        worker_metadata.workers_waiting, worker_metadata.exit);
  quidditch_dispatch_wait_for_workers();
  // printf("quidditch_dispatch_quit- workers_waiting: %d exit: %d\n",
  //        worker_metadata.workers_waiting, worker_metadata.exit);
  worker_metadata.exit = true;
  // printf("inside dispatch quit (after waiting): workers_waiting: %d exit:
  // %d\n",
  //          worker_metadata.workers_waiting, worker_metadata.exit);
  wake_all_workers();
  // printf("quidditch_dispatch_quit- workers_waiting: %d exit: %d\n",
  //        worker_metadata.workers_waiting, worker_metadata.exit);
}

void quidditch_dispatch_submit_workgroup(uint32_t processor_id) {
  snrt_int_cluster_set(1 << processor_id);
  printf("1 << processor_id is %d\n", 1 << processor_id);
}

// #include "janky_dispatch.h"

// #include <assert.h>
// #include <cluster_interrupt_decls.h>
// #include <riscv.h>
// #include <snitch_cluster_defs.h>
// #include <stdatomic.h>
// #include <stdbool.h>
// #include <stdint.h>
// #include <team_decls.h>
// #include <stdio.h>

// //#include "iree/base/alignment.h"

// // absolutely horrible
// uint8_t coresDone [8] = {1,1,1,1,1,1,1,1}; // one flag for each compute core
// uint8_t exitNow [8] = {0,0,0,0,0,0,0,0};   // one flag for each compute core

// void announceImDone(){
//   uint32_t hoodle = snrt_cluster_core_idx();
//   coresDone[hoodle] = 1;
// }

// bool imDone(){
//   uint32_t hoodle = snrt_cluster_core_idx();
//   return coresDone[hoodle];
// }

// bool iShouldExit(){
//   uint32_t hoodle = snrt_cluster_core_idx();
//   return (exitNow[hoodle]==1);
// }

// void computeCoreGo(uint32_t id){
//   coresDone[id] = 0;
// }

// bool allDone(){
//   return ( coresDone[0] &&
//            coresDone[1] &&
//            coresDone[2] &&
//            coresDone[3] &&
//            coresDone[4] &&
//            coresDone[5] &&
//            coresDone[6] &&
//            coresDone[7] == 1);
// }

// void tellCoresToExit(){
//   for(size_t i = 0; i < 8; i++){
//     exitNow[i] = 1;
//   }
// }

// // TODO: This should be cluster local.
// static struct worker_metadata_t {
//   atomic_uint workers_waiting;
//   atomic_bool exit;
// } worker_metadata = {0, false};

// // TODO: All of this synchronization in this file could use hardware barriers
// // which might be more efficient.
// static void park_worker() {
//   // worker_metadata.workers_waiting++;
//   // asm volatile("wfi");
//   // snrt_int_cluster_clr(1 << snrt_cluster_core_idx());
//   // worker_metadata.workers_waiting--;
// }

// static void wake_all_workers() {
//   // assert(snrt_is_dm_core() && "DM core is currently our host");
//   // uint32_t compute_cores = snrt_cluster_compute_core_num();
//  // Compute cores are indices 0 to compute_cores.
//   // snrt_int_cluster_set((1 << compute_cores) - 1);
// }

// void quidditch_dispatch_wait_for_workers() {
//   //assert(snrt_is_dm_core() && "DM core is currently our host");
//   // Spin until all compute corkers are parked.
//   // while(!allDone()){
//   //   printf("cores done: %d, %d, %d, %d, %d, %d, %d, %d\n", coresDone[0],
//   coresDone[1], coresDone[2], coresDone[3], coresDone[4], coresDone[5],
//   coresDone[6], coresDone[7]);
//   // }
//   //while (worker_metadata.workers_waiting !=
//   snrt_cluster_compute_core_num()){
//    // printf("waiting for compute cores to park\n");
//   //}
// }

// // TODO: This only works for a single cluster by using globals. Should be
// // cluster local.
// // static iree_hal_executable_dispatch_v0_t configuredKernel;
// // static const iree_hal_executable_environment_v0_t* configuredEnvironment;
// // static const iree_hal_executable_dispatch_state_v0_t*
// configuredDispatchState;
// // static iree_alignas(64) iree_hal_executable_workgroup_state_v0_t
// //     configuredWorkgroupState[SNRT_CLUSTER_CORE_NUM - 1];
// static atomic_bool error = false;

// bool quidditch_dispatch_errors_occurred() { return error; }

// void quidditch_dispatch_set_kernel(uint32_t hoodle){
//     // iree_hal_executable_dispatch_v0_t kernel,
//     // const iree_hal_executable_environment_v0_t* environment,
//     // const iree_hal_executable_dispatch_state_v0_t* dispatch_state) {
//   // configuredKernel = kernel;
//   // configuredEnvironment = environment;
//   // configuredDispatchState = dispatch_state;
// }

// int quidditch_dispatch_enter_worker_loop() {
//   //   int thiscore = snrt_cluster_core_idx();
//   // if (thiscore != 0)
//   //   return 0;
//   // snrt_interrupt_enable(IRQ_M_CLUSTER);
//   //printf("addr of exits is %x\n",&exitNow);
//   while(!iShouldExit()){
//      //printf("inside iShouldExit: %d, %d, %d, %d, %d, %d, %d, %d\n",
//      exitNow[0], exitNow[1], exitNow[2], exitNow[3], exitNow[4], exitNow[5],
//      exitNow[6], exitNow[7]);
//     // printf("addr of exits is %x\n",&exitNow); //80004a58
//     //printf("waiting to exit %d\n",snrt_cluster_core_idx());
//     // if(!imDone()){
//     //   printf("going %d\n",snrt_cluster_core_idx());
//     //   //printf("I think im supposed to do stuff here\n");
//     //   announceImDone();
//     // }
//     //announceImDone();
//   }
//   // printf("exiting worker loop\n");
//   //printf("I'm compute core %d\n",snrt_cluster_core_idx());
//   //announceImDone();
//   // while (!worker_metadata.exit) {
//   //   park_worker();
//   //   if (worker_metadata.exit) {
//   //     printf("worker metadata says to exit, so I will break outta this
//   loop!\n");
//   //     break;
//   //   }

//   //   // if (configuredKernel(configuredEnvironment,
//   configuredDispatchState,
//   //   // &configuredWorkgroupState[snrt_cluster_core_idx()]))
//   //   //   error = true;
//   //   printf("I think im supposed to do stuff here\n");

//   // }
//   snrt_interrupt_disable(IRQ_M_CLUSTER);
//   //printf("did the work\n");
//   return 0;
// }

// void quidditch_dispatch_quit() {
//   printf("waiting for workers\n");
//   quidditch_dispatch_wait_for_workers();
//   printf("telling cores to exit\n");
//   tellCoresToExit();
//   printf("exit now %x: %d, %d, %d, %d, %d, %d, %d, %d\n", &exitNow,
//   exitNow[0], exitNow[1], exitNow[2], exitNow[3], exitNow[4], exitNow[5],
//   exitNow[6], exitNow[7]);
//   // DMA core says exits array is at: 80004a18
//   // compute core says exits array is at: 80004a58
//   //worker_metadata.exit = true;
//   //wake_all_workers();
// }

// void quidditch_dispatch_submit_workgroup(uint32_t processor_id){
//     // const iree_hal_executable_workgroup_state_v0_t* workgroup_state) {
//   // configuredWorkgroupState[workgroup_state->processor_id] =
//   *workgroup_state;
//   //snrt_int_cluster_set(1 << workgroup_state->processor_id);
//   snrt_int_cluster_set(1 << processor_id);
//   // computeCoreGo(processor_id);

// }