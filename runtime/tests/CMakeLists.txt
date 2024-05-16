include(CTest)

# Sanity check that our toolchain, emulator etc. work
add_executable(HelloWorld main.c)
target_link_libraries(HelloWorld snRuntime)

# Testing tiled matrix multiplication on the DMA core
add_executable(TiledMatmul tiled-matmul.c)
target_link_libraries(TiledMatmul snRuntime)

# Testing calling C from MLIR and vice versa 
add_executable(HolaWorld hola-world/main.c 
                         hola-world/data.c 
                         hola-world/data.h 
                         hola-world/out/matmul-tiled.o)
target_link_libraries(HolaWorld snRuntime)

add_test(NAME HelloWorld COMMAND HelloWorld)

add_test(NAME TiledMatmul COMMAND TiledMatmul)
set_property(TEST TiledMatmul PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)

add_test(NAME HolaWorld COMMAND HolaWorld)
set_property(TEST HolaWorld PROPERTY
  PASS_REGULAR_EXPRESSION "hola world!\n"
)
