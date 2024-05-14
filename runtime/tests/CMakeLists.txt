include(CTest)

# Sanity check that our toolchain, emulator etc. work
add_executable(HelloWorld main.c)
target_link_libraries(HelloWorld snRuntime)

# Testing tiled matrix multiplication on the DMA core
add_executable(TiledMatmul tiled-matmul.c)
target_link_libraries(TiledMatmul snRuntime)


add_test(NAME HelloWorld COMMAND HelloWorld)

add_test(NAME TiledMatmul COMMAND TiledMatmul)
set_property(TEST TiledMatmul PROPERTY
  PASS_REGULAR_EXPRESSION "Output Correct\n"
)
