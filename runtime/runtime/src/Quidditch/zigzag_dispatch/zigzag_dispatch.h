
#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdatomic.h>


// operation dumb down the code vvvvvvvvvvvvvvvvvvvvvvvvvv
int compute_core_loop(void);
void tell_compute_cores_to_exit(void);
void printBins(void);
void setup_outputs(void);
void close_outputs(void);
void wake_up_compute_cores(void);
void wait_for_all_compute_cores(void);
void print_csr(void);
// operation dumb down the code ^^^^^^^^^^^^^^^^^^^^^^^^^^

/// Entry point for compute cores to be parked and called upon for kernel
/// execution. Cores are halted within the function until
/// 'quidditch_dispatch_quit' is called.
int quidditch_dispatch_enter_worker_loop(void);

/// Called by the host core before exiting to release all computes cores from
/// the work loop.
void quidditch_dispatch_quit(void);

/// Causes the host core to wait for all workers to enter a parked state again.
void quidditch_dispatch_wait_for_workers(void);

/// Returns true if any kernel execution of any compute core ever caused an
/// error.
bool quidditch_dispatch_errors_occurred();

/// Configures the kernel, environment and dispatch state to use for subsequent
/// 'quidditch_dispatch_submit_workgroup' calls. It is impossible for a cluster
/// to execute more than one kernel at a time.
void quidditch_dispatch_set_kernel();

/// Dispatches the compute core with the id 'workgroup_state->processorId' to
/// execute the last configured kernel with the given workgroup state.
void quidditch_dispatch_submit_workgroup(uint32_t processor_id);



//zigzag_dispatch
// #pragma once

// #include <stdbool.h>
// #include <stdint.h>


// //#include "iree/hal/local/executable_library.h"

// /// Entry point for compute cores to be parked and called upon for kernel
// /// execution. Cores are halted within the function until
// /// 'quidditch_dispatch_quit' is called.
// int quidditch_dispatch_enter_worker_loop(void);

// /// Called by the host core before exiting to release all computes cores from
// /// the work loop.
// void quidditch_dispatch_quit(void);

// /// Causes the host core to wait for all workers to enter a parked state again.
// void quidditch_dispatch_wait_for_workers(void);

// /// Returns true if any kernel execution of any compute core ever caused an
// /// error.
// bool quidditch_dispatch_errors_occurred();

// /// Configures the kernel, environment and dispatch state to use for subsequent
// /// 'quidditch_dispatch_submit_workgroup' calls. It is impossible for a cluster
// /// to execute more than one kernel at a time.
// void quidditch_dispatch_set_kernel(uint32_t hoodle);
//     // iree_hal_executable_dispatch_v0_t kernel,
//     // const iree_hal_executable_environment_v0_t* environment,
//     // const iree_hal_executable_dispatch_state_v0_t* dispatch_state);

// /// Dispatches the compute core with the id 'workgroup_state->processorId' to
// /// execute the last configured kernel with the given workgroup state.
// void quidditch_dispatch_submit_workgroup(uint32_t processor_id);
//    // const iree_hal_executable_workgroup_state_v0_t* workgroup_state);
