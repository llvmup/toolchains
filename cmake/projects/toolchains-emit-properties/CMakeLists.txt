cmake_minimum_required(VERSION 3.27.0 FATAL_ERROR)

set(CMAKE_SKIP_INSTALL_RULES ON)

foreach(variable IN ITEMS
  CMAKE_INSTALL_PREFIX
  TOOLCHAINS_CMAKE_SOURCE_DIR
  TOOLCHAINS_CMAKE_BINARY_DIR
)
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: `${variable}` must be defined")
  endif()
endforeach()

load_cache("${TOOLCHAINS_CMAKE_BINARY_DIR}"
  READ_WITH_PREFIX ""
  TOOLCHAINS_ENABLE_CLANG
  TOOLCHAINS_ENABLE_LLVM
  TOOLCHAINS_ENABLE_MLIR
  TOOLCHAINS_ENABLE_SWIFT
  TOOLCHAINS_ENABLE_TOOL_CLANG
  TOOLCHAINS_ENABLE_TOOL_LLD
)
foreach(variable IN ITEMS
  TOOLCHAINS_ENABLE_CLANG
  TOOLCHAINS_ENABLE_LLVM
  TOOLCHAINS_ENABLE_MLIR
  TOOLCHAINS_ENABLE_SWIFT
  TOOLCHAINS_ENABLE_TOOL_CLANG
  TOOLCHAINS_ENABLE_TOOL_LLD
)
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: Could not load cache variable `${variable}`")
  endif()
endforeach()

include("${TOOLCHAINS_CMAKE_SOURCE_DIR}/cmake/modules/Support/ConfigureVariables.cmake")
include("${TOOLCHAINS_CMAKE_SOURCE_DIR}/cmake/modules/Support/ConfigureFindPackages.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/Support.cmake")

project(toolchains-emit-properties
  LANGUAGES NONE
)

add_subdirectory("${CMAKE_SOURCE_DIR}/distributions/llvm")
add_subdirectory("${CMAKE_SOURCE_DIR}/distributions/mlir")
add_subdirectory("${CMAKE_SOURCE_DIR}/distributions/clang")
add_subdirectory("${CMAKE_SOURCE_DIR}/distributions/swift")
add_subdirectory("${CMAKE_SOURCE_DIR}/distributions/tool_clang")
add_subdirectory("${CMAKE_SOURCE_DIR}/distributions/tool_lld")
