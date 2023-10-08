include_guard(GLOBAL)

if(NOT TOOLCHAINS_ENABLE_LLVM)
  return()
endif()

message(NOTICE "toolchains: Configuring distributions: `LLVM`")

toolchains_add_distribution_requirements(
  INPUT_DISTRIBUTION "LLVM"
  # INPUT_DISTRIBUTION_REQUIREMENTS
  INPUT_LLVM_DISTRIBUTIONS llvm_project_cmake_args_LLVM_DISTRIBUTIONS
)

set(llvm_project_cmake_args_LLVM_LLVM_DISTRIBUTION_COMPONENTS
  "llvm-headers"
  "llvm-libraries"
  "llvm-cmake-exports"
  "llvm-llvm-cmake-exports"
  "llvm-license"
)

list(JOIN llvm_project_cmake_args_LLVM_LLVM_DISTRIBUTION_COMPONENTS "|" llvm_project_cmake_args_LLVM_LLVM_DISTRIBUTION_COMPONENTS)

if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
  list(APPEND llvm_project_cross_compilation_flags
    "-DLLVM_USE_HOST_TOOLS=ON"
    "-DLLVM_TABLEGEN=${CMAKE_BINARY_DIR}/tlp-host-p/src/tlp-host-b/bin/llvm-tblgen${CMAKE_EXECUTABLE_SUFFIX}"
  )
endif()

list(APPEND llvm_project_cmake_args
  "-DLLVM_LLVM_DISTRIBUTION_COMPONENTS=${llvm_project_cmake_args_LLVM_LLVM_DISTRIBUTION_COMPONENTS}"
  "-DLLVM_INSTALL_MODULEMAPS=ON"
)

list(APPEND llvm_project_build_byproducts
  "${CMAKE_BINARY_DIR}/i-llvm"
)

list(APPEND llvm_project_build_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target llvm-distribution
)

list(APPEND llvm_project_install_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target install-llvm-distribution-stripped
  COMMAND "${CMAKE_COMMAND}" -E rm -frR "${CMAKE_BINARY_DIR}/i-llvm"
  COMMAND "${CMAKE_COMMAND}" -E rename
    "${CMAKE_BINARY_DIR}/i"
    "${CMAKE_BINARY_DIR}/i-llvm"
)
