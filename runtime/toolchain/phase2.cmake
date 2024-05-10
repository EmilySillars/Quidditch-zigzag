include(${CMAKE_CURRENT_LIST_DIR}/phase1.cmake)

set(BUILTINS_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_C_FLAGS "--config=${CMAKE_INSTALL_PREFIX}/bin/riscv32-unknown-unknown-elf.cfg" CACHE STRING "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_C_FLAGS ${BUILTINS_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_C_FLAGS} CACHE STRING "")
set(BUILTINS_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_CXX_FLAGS "--config=${CMAKE_INSTALL_PREFIX}/bin/riscv32-unknown-unknown-elf.cfg --config=${CMAKE_INSTALL_PREFIX}/bin/clang++.cfg" CACHE STRING "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_CXX_FLAGS ${BUILTINS_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_CXX_FLAGS} CACHE STRING "")
set(BUILTINS_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_ASM_FLAGS "--config=${CMAKE_INSTALL_PREFIX}/bin/riscv32-unknown-unknown-elf.cfg" CACHE STRING "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_ASM_FLAGS ${BUILTINS_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_CXX_FLAGS} CACHE STRING "")

set(LLVM_BUILTIN_TARGETS "${LLVM_DEFAULT_TARGET_TRIPLE}" CACHE STRING "")
set(LLVM_RUNTIME_TARGETS "${LLVM_BUILTIN_TARGETS}" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi" CACHE STRING "")
set(BUILTINS_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_SYSTEM_NAME Generic CACHE STRING "")
set(BUILTINS_${LLVM_DEFAULT_TARGET_TRIPLE}_COMPILER_RT_BAREMETAL_BUILD ON CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_CMAKE_SYSTEM_NAME Generic CACHE STRING "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_COMPILER_RT_BAREMETAL_BUILD ON CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_BAREMETAL ON CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_ENABLE_ASSERTIONS OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_ENABLE_STATIC ON CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_USE_LLVM_UNWINDER OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_ENABLE_THREADS OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXXABI_SILENT_TERMINATE ON CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ABI_UNSTABLE ON CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_FILESYSTEM OFF CACHE STRING "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_MONOTONIC_CLOCK OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_RANDOM_DEVICE OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_RTTI OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_STATIC ON CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_THREADS OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_WIDE_CHARACTERS OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_LOCALIZATION OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_ENABLE_UNICODE OFF CACHE BOOL "")
set(RUNTIMES_${LLVM_DEFAULT_TARGET_TRIPLE}_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
