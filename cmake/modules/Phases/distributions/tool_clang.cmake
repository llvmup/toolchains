include_guard(GLOBAL)

if(NOT TOOLCHAINS_ENABLE_TOOL_CLANG)
  return()
endif()

message(NOTICE "toolchains: Configuring distributions: `Tool-Clang`")

toolchains_add_distribution_requirements(
  INPUT_DISTRIBUTION "TOOL_CLANG"
  INPUT_DISTRIBUTION_REQUIREMENTS
    "CLANG"
    "LLVM"
  INPUT_LLVM_DISTRIBUTIONS llvm_project_cmake_args_LLVM_DISTRIBUTIONS
)

list(APPEND llvm_project_cmake_args_LLVM_ENABLE_PROJECTS
  "clang"
)

set(llvm_project_cmake_args_LLVM_TOOL_CLANG_DISTRIBUTION_COMPONENTS
  "clang"
  "clang-resource-headers"
  "clang-cmake-exports"
  "clang-tool_clang-cmake-exports"
)

list(JOIN llvm_project_cmake_args_LLVM_TOOL_CLANG_DISTRIBUTION_COMPONENTS "|" llvm_project_cmake_args_LLVM_TOOL_CLANG_DISTRIBUTION_COMPONENTS)

if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
endif()

list(APPEND llvm_project_cmake_args
  "-DLLVM_TOOL_CLANG_DISTRIBUTION_COMPONENTS=${llvm_project_cmake_args_LLVM_TOOL_CLANG_DISTRIBUTION_COMPONENTS}"
)

list(APPEND llvm_project_build_byproducts
  "${CMAKE_BINARY_DIR}/i-tool_clang"
)

list(APPEND llvm_project_build_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target tool_clang-distribution
)

list(APPEND llvm_project_install_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target install-tool_clang-distribution-stripped
  COMMAND "${CMAKE_COMMAND}" -E rm -frR "${CMAKE_BINARY_DIR}/i-tool_clang"
  COMMAND "${CMAKE_COMMAND}" -E rename
    "${CMAKE_BINARY_DIR}/i"
    "${CMAKE_BINARY_DIR}/i-tool_clang"
)
