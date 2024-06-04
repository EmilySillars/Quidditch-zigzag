
#include "janky_dispatch.h"

#include <assert.h>
#include <cluster_interrupt_decls.h>
#include <riscv.h>
#include <snitch_cluster_defs.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <team_decls.h>
#include <stdio.h>

//#include "iree/base/alignment.h"

// absolutely horrible
uint8_t coresDone [8] = {1,1,1,1,1,1,1,1}; // one flag for each compute core
uint8_t exitNow [8] = {0,0,0,0,0,0,0,0};   // one flag for each compute core

void announceImDone(){
  uint32_t hoodle = snrt_cluster_core_idx();
  coresDone[hoodle] = 1;
}

bool imDone(){
  uint32_t hoodle = snrt_cluster_core_idx();
  return coresDone[hoodle];
}

bool iShouldExit(){
  uint32_t hoodle = snrt_cluster_core_idx();
  return (exitNow[hoodle]==1);
}

void computeCoreGo(uint32_t id){
  coresDone[id] = 0;
}

bool allDone(){
  return ( coresDone[0] &&
           coresDone[1] &&
           coresDone[2] &&
           coresDone[3] &&
           coresDone[4] &&
           coresDone[5] &&
           coresDone[6] &&
           coresDone[7] == 1);
}

void tellCoresToExit(){
  for(size_t i = 0; i < 8; i++){
    exitNow[i] = 1;
  }
}

// TODO: This should be cluster local.
static struct worker_metadata_t {
  atomic_uint workers_waiting;
  atomic_bool exit;
} worker_metadata = {0, false};

// TODO: All of this synchronization in this file could use hardware barriers
// which might be more efficient.
static void park_worker() {
  // worker_metadata.workers_waiting++;
  // asm volatile("wfi");
  // snrt_int_cluster_clr(1 << snrt_cluster_core_idx());
  // worker_metadata.workers_waiting--;
}

static void wake_all_workers() {
  // assert(snrt_is_dm_core() && "DM core is currently our host");
  // uint32_t compute_cores = snrt_cluster_compute_core_num();
 // Compute cores are indices 0 to compute_cores.
  // snrt_int_cluster_set((1 << compute_cores) - 1); 
}

void quidditch_dispatch_wait_for_workers() {
  //assert(snrt_is_dm_core() && "DM core is currently our host");
  // Spin until all compute corkers are parked.
  // while(!allDone()){
  //   printf("cores done: %d, %d, %d, %d, %d, %d, %d, %d\n", coresDone[0], coresDone[1], coresDone[2], coresDone[3], coresDone[4], coresDone[5], coresDone[6], coresDone[7]);
  // }
  //while (worker_metadata.workers_waiting != snrt_cluster_compute_core_num()){
   // printf("waiting for compute cores to park\n");
  //}
}

// TODO: This only works for a single cluster by using globals. Should be
// cluster local.
// static iree_hal_executable_dispatch_v0_t configuredKernel;
// static const iree_hal_executable_environment_v0_t* configuredEnvironment;
// static const iree_hal_executable_dispatch_state_v0_t* configuredDispatchState;
// static iree_alignas(64) iree_hal_executable_workgroup_state_v0_t
//     configuredWorkgroupState[SNRT_CLUSTER_CORE_NUM - 1];
static atomic_bool error = false;

bool quidditch_dispatch_errors_occurred() { return error; }

void quidditch_dispatch_set_kernel(uint32_t hoodle){
    // iree_hal_executable_dispatch_v0_t kernel,
    // const iree_hal_executable_environment_v0_t* environment,
    // const iree_hal_executable_dispatch_state_v0_t* dispatch_state) {
  // configuredKernel = kernel;
  // configuredEnvironment = environment;
  // configuredDispatchState = dispatch_state;
}

int quidditch_dispatch_enter_worker_loop() {
  //   int thiscore = snrt_cluster_core_idx();
  // if (thiscore != 0)
  //   return 0;
  // snrt_interrupt_enable(IRQ_M_CLUSTER);
  //printf("addr of exits is %x\n",&exitNow);
  while(!iShouldExit()){
     //printf("inside iShouldExit: %d, %d, %d, %d, %d, %d, %d, %d\n", exitNow[0], exitNow[1], exitNow[2], exitNow[3], exitNow[4], exitNow[5], exitNow[6], exitNow[7]);
    // printf("addr of exits is %x\n",&exitNow); //80004a58  
    //printf("waiting to exit %d\n",snrt_cluster_core_idx());
    // if(!imDone()){
    //   printf("going %d\n",snrt_cluster_core_idx());
    //   //printf("I think im supposed to do stuff here\n");
    //   announceImDone();
    // }
    //announceImDone();
  }
  // printf("exiting worker loop\n");
  //printf("I'm compute core %d\n",snrt_cluster_core_idx());
  //announceImDone();
  // while (!worker_metadata.exit) {
  //   park_worker();
  //   if (worker_metadata.exit) {
  //     printf("worker metadata says to exit, so I will break outta this loop!\n");
  //     break;
  //   }

  //   // if (configuredKernel(configuredEnvironment, configuredDispatchState,
  //   //                      &configuredWorkgroupState[snrt_cluster_core_idx()]))
  //   //   error = true;
  //   printf("I think im supposed to do stuff here\n");
    
  // }
  snrt_interrupt_disable(IRQ_M_CLUSTER);
  //printf("did the work\n");
  return 0;
}

void quidditch_dispatch_quit() {
  printf("waiting for workers\n");
  quidditch_dispatch_wait_for_workers();
  printf("telling cores to exit\n");
  tellCoresToExit();
  printf("exit now %x: %d, %d, %d, %d, %d, %d, %d, %d\n", &exitNow, exitNow[0], exitNow[1], exitNow[2], exitNow[3], exitNow[4], exitNow[5], exitNow[6], exitNow[7]);
  // DMA core says exits array is at: 80004a18
  // compute core says exits array is at: 80004a58
  //worker_metadata.exit = true;
  //wake_all_workers();
}

void quidditch_dispatch_submit_workgroup(uint32_t processor_id){
    // const iree_hal_executable_workgroup_state_v0_t* workgroup_state) {
  // configuredWorkgroupState[workgroup_state->processor_id] = *workgroup_state;
  //snrt_int_cluster_set(1 << workgroup_state->processor_id);
  snrt_int_cluster_set(1 << processor_id);
  // computeCoreGo(processor_id);
  
}
