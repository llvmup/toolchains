include_guard(GLOBAL)

if(NOT TOOLCHAINS_ENABLE_TOOL_LLD)
  return()
endif()

message(NOTICE "toolchains: Configuring distributions: `Tool-LLD`")

toolchains_add_distribution_requirements(
  INPUT_DISTRIBUTION "TOOL_LLD"
  INPUT_DISTRIBUTION_REQUIREMENTS
    "LLVM"
  INPUT_LLVM_DISTRIBUTIONS llvm_project_cmake_args_LLVM_DISTRIBUTIONS
)

list(APPEND llvm_project_cmake_args_LLVM_ENABLE_PROJECTS
  "lld"
)

set(llvm_project_cmake_args_LLVM_TOOL_LLD_DISTRIBUTION_COMPONENTS
  "lld"
  "lld-cmake-exports"
  "lld-tool_lld-cmake-exports"
)

list(JOIN llvm_project_cmake_args_LLVM_TOOL_LLD_DISTRIBUTION_COMPONENTS "|" llvm_project_cmake_args_LLVM_TOOL_LLD_DISTRIBUTION_COMPONENTS)

if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
endif()

list(APPEND llvm_project_cmake_args
  "-DLLVM_TOOL_LLD_DISTRIBUTION_COMPONENTS=${llvm_project_cmake_args_LLVM_TOOL_LLD_DISTRIBUTION_COMPONENTS}"
)

list(APPEND llvm_project_build_byproducts
  "${CMAKE_BINARY_DIR}/i-tool_lld"
)

list(APPEND llvm_project_build_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target tool_lld-distribution
)

list(APPEND llvm_project_install_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target install-tool_lld-distribution-stripped
  COMMAND "${CMAKE_COMMAND}" -E rm -frR "${CMAKE_BINARY_DIR}/i-tool_lld"
  COMMAND "${CMAKE_COMMAND}" -E rename
    "${CMAKE_BINARY_DIR}/i"
    "${CMAKE_BINARY_DIR}/i-tool_lld"
)
