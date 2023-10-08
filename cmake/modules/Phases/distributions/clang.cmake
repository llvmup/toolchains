include_guard(GLOBAL)

if(NOT TOOLCHAINS_ENABLE_CLANG)
  return()
endif()

message(NOTICE "toolchains: Configuring distributions: `Clang`")

toolchains_add_distribution_requirements(
  INPUT_DISTRIBUTION "CLANG"
  INPUT_DISTRIBUTION_REQUIREMENTS
    "LLVM"
  INPUT_LLVM_DISTRIBUTIONS llvm_project_cmake_args_LLVM_DISTRIBUTIONS
)

list(APPEND llvm_project_cmake_args_LLVM_ENABLE_PROJECTS
  "clang"
)

set(llvm_project_cmake_args_LLVM_CLANG_DISTRIBUTION_COMPONENTS
  "clang-resource-headers"
  "clang-headers"
  "clang-libraries"
  "clang-cmake-exports"
  "clang-clang-cmake-exports"
  "clang-license"
)

list(JOIN llvm_project_cmake_args_LLVM_CLANG_DISTRIBUTION_COMPONENTS "|" llvm_project_cmake_args_LLVM_CLANG_DISTRIBUTION_COMPONENTS)

if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
  list(APPEND llvm_project_cross_compilation_flags
    "-DCLANG_TABLEGEN=${CMAKE_BINARY_DIR}/tlp-host-p/src/tlp-host-b/bin/clang-tblgen${CMAKE_EXECUTABLE_SUFFIX}"
  )
endif()

list(APPEND llvm_project_cmake_args
  "-DLLVM_CLANG_DISTRIBUTION_COMPONENTS=${llvm_project_cmake_args_LLVM_CLANG_DISTRIBUTION_COMPONENTS}"
)

list(APPEND llvm_project_build_byproducts
  "${CMAKE_BINARY_DIR}/i-clang"
)

list(APPEND llvm_project_build_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target clang-distribution
)

list(APPEND llvm_project_install_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target install-clang-distribution-stripped
  COMMAND "${CMAKE_COMMAND}" -E rm -frR "${CMAKE_BINARY_DIR}/i-clang"
  COMMAND "${CMAKE_COMMAND}" -E rename
    "${CMAKE_BINARY_DIR}/i"
    "${CMAKE_BINARY_DIR}/i-clang"
)
