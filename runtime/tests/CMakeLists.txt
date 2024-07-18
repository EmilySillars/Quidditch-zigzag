include(CTest)

# Sanity check that our toolchain, emulator etc. work
add_executable(HelloWorld main.c)
target_link_libraries(HelloWorld snRuntime)

# Testing calling C from MLIR and vice versa 
add_executable(HolaWorld holaWorld/main.c 
                         lib-zigzag/data.c 
                         lib-zigzag/data.h 
                         holaWorld/out/holaWorld.o)
target_link_libraries(HolaWorld snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing matrix multiplication on the DMA core
add_executable(Matmul matmul/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           matmul/out/matmul.o)
target_link_libraries(Matmul snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing tiled matrix multiplication on the DMA core
add_executable(TiledMatmul tiledMatmul/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           tiledMatmul/out/tiledMatmul.o)
target_link_libraries(TiledMatmul snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing another tiled matrix multiplication on the DMA core
add_executable(TiledMatmul2 tiledMatmul2/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           tiledMatmul2/out/tiledMatmul2.o)
target_link_libraries(TiledMatmul2 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing another tiled matrix multiplication on the DMA core
add_executable(TiledMatmul3 tiledMatmul3/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           tiledMatmul3/out/tiledMatmul3.o)
target_link_libraries(TiledMatmul3 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing another tiled matrix multiplication on the DMA core
add_executable(TiledMatmul4 tiledMatmul4/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           tiledMatmul4/out/tiledMatmul4.o)
target_link_libraries(TiledMatmul4 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing another tiled matrix multiplication on the DMA core
add_executable(TiledMatmul5 tiledMatmul5/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           lib-zigzag/zigzag_utils.h
                           lib-zigzag/zigzag_utils.c
                           tiledMatmul5/out/tiledMatmul5.o)
target_link_libraries(TiledMatmul5 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing another tiled matrix multiplication on the DMA core
add_executable(TiledMatmul6 tiledMatmul6/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           lib-zigzag/zigzag_utils.h
                           lib-zigzag/zigzag_utils.c
                           tiledMatmul6/out/tiledMatmul6.o)
target_link_libraries(TiledMatmul6 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing tiled matrix multiplication on the DMA core
add_executable(TiledMatmul7 tiledMatmul7/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           tiledMatmul7/out/tiledMatmul7.o)
target_link_libraries(TiledMatmul7 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

#Quidditch::device::device
#../runtime/src/Quidditch/zigzag_dispatch/dispatch.h
#../runtime/src/Quidditch/zigzag_dispatch/dispatch.c

# Testing tiled matrix multiplication on the DMA core
add_executable(TiledMatmul8 tiledMatmul8/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           lib-zigzag/zigzag_utils.h
                           lib-zigzag/zigzag_utils.c
                           tiledMatmul8/out/tiledMatmul8.o)
target_link_libraries(TiledMatmul8 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing tiled matrix multiplication on the DMA core
add_executable(TiledMatmul9 tiledMatmul9/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           lib-zigzag/zigzag_utils.h
                           lib-zigzag/zigzag_utils.c
                           tiledMatmul9/out/tiledMatmul9.o)
target_link_libraries(TiledMatmul9 snRuntime)

# Testing another tiled matrix multiplication on a single compute core
add_executable(TiledMatmul10 tiledMatmul10/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           lib-zigzag/zigzag_utils.h
                           lib-zigzag/zigzag_utils.c
                           tiledMatmul10/out/tiledMatmul10.o)
target_link_libraries(TiledMatmul10 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing another tiled matrix multiplication on a single compute core
add_executable(TiledMatmul11 tiledMatmul11/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           lib-zigzag/zigzag_utils.h
                           lib-zigzag/zigzag_utils.c
                           tiledMatmul11/out/tiledMatmul11.o)
target_link_libraries(TiledMatmul11 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# Testing another tiled matrix multiplication on a single compute core
add_executable(TiledMatmul12 tiledMatmul12/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           lib-zigzag/zigzag_utils.h
                           lib-zigzag/zigzag_utils.c
                           tiledMatmul12/out/tiledMatmul12.o)
target_link_libraries(TiledMatmul12 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)

# add description!
add_executable(TiledMatmul13 tiledMatmul13/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           lib-zigzag/zigzag_utils.h
                           lib-zigzag/zigzag_utils.c
                           tiledMatmul13/out/tiledMatmul13.o)
target_link_libraries(TiledMatmul13 snRuntime Quidditch::zigzag_dispatch::zigzag_dispatch)


add_test(NAME HolaWorld COMMAND HolaWorld)
set_property(TEST HolaWorld PROPERTY
  PASS_REGULAR_EXPRESSION "hola world!\n"
)

add_test(NAME Matmul COMMAND Matmul)
set_property(TEST Matmul PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul COMMAND TiledMatmul)
set_property(TEST TiledMatmul PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul2 COMMAND TiledMatmul2)
set_property(TEST TiledMatmul2 PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul3 COMMAND TiledMatmul3)
set_property(TEST TiledMatmul3 PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul4 COMMAND TiledMatmul4)
set_property(TEST TiledMatmul4 PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul5 COMMAND TiledMatmul5)
set_property(TEST TiledMatmul5 PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul6 COMMAND TiledMatmul6)
set_property(TEST TiledMatmul6 PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul7 COMMAND TiledMatmul7)
set_property(TEST TiledMatmul7 PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul8 COMMAND TiledMatmul8)
set_property(TEST TiledMatmul8 PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME TiledMatmul9 COMMAND TiledMatmul9)
set_property(TEST TiledMatmul9 PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

macro(test_executable target_name)
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.test)
  add_test(NAME ${target_name} COMMAND ${target_name} WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.test)
endmacro()

test_executable(HelloWorld)
test_executable(IREE_HelloWorld)
