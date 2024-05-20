include(CTest)

# Sanity check that our toolchain, emulator etc. work
add_executable(HelloWorld main.c)
target_link_libraries(HelloWorld snRuntime)

# Testing calling C from MLIR and vice versa 
add_executable(HolaWorld holaWorld/main.c 
                         lib-zigzag/data.c 
                         lib-zigzag/data.h 
                         holaWorld/out/holaWorld.o)
target_link_libraries(HolaWorld snRuntime)

# Testing matrix multiplication on the DMA core
add_executable(Matmul matmul/main.c
                           lib-zigzag/data.c
                           lib-zigzag/data.h
                           lib-zigzag/memref.h 
                           matmul/out/matmul.o)
target_link_libraries(Matmul snRuntime)

# Testing tiled matrix multiplication on the DMA core
# TODO

add_test(NAME HelloWorld COMMAND HelloWorld)

add_test(NAME HolaWorld COMMAND HolaWorld)
set_property(TEST HolaWorld PROPERTY
  PASS_REGULAR_EXPRESSION "hola world!\n"
)

add_test(NAME Matmul COMMAND Matmul)
set_property(TEST Matmul PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)


