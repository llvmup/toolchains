include_guard(GLOBAL)

if(NOT TOOLCHAINS_ENABLE_MLIR)
  return()
endif()

message(NOTICE "toolchains: Configuring distributions: `MLIR`")

toolchains_add_distribution_requirements(
  INPUT_DISTRIBUTION "MLIR"
  INPUT_DISTRIBUTION_REQUIREMENTS
    "LLVM"
  INPUT_LLVM_DISTRIBUTIONS llvm_project_cmake_args_LLVM_DISTRIBUTIONS
)

list(APPEND llvm_project_cmake_args_LLVM_ENABLE_PROJECTS
  "mlir"
)

set(llvm_project_cmake_args_LLVM_MLIR_DISTRIBUTION_COMPONENTS
  "mlir-headers"
  "mlir-libraries"
  "mlir-cmake-exports"
  "mlir-mlir-cmake-exports"
  "mlir-license"
)

list(JOIN llvm_project_cmake_args_LLVM_MLIR_DISTRIBUTION_COMPONENTS "|" llvm_project_cmake_args_LLVM_MLIR_DISTRIBUTION_COMPONENTS)

if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
  list(APPEND llvm_project_cross_compilation_flags
    "-DMLIR_TABLEGEN=${CMAKE_BINARY_DIR}/tlp-host-p/src/tlp-host-b/bin/mlir-tblgen${CMAKE_EXECUTABLE_SUFFIX}"
    "-DMLIR_LINALG_ODS_YAML_GEN=${CMAKE_BINARY_DIR}/tlp-host-p/src/tlp-host-b/bin/mlir-linalg-ods-yaml-gen${CMAKE_EXECUTABLE_SUFFIX}"
  )
endif()

list(APPEND llvm_project_cmake_args
  "-DLLVM_MLIR_DISTRIBUTION_COMPONENTS=${llvm_project_cmake_args_LLVM_MLIR_DISTRIBUTION_COMPONENTS}"
  "-DMLIR_DETECT_PYTHON_ENV_PRIME_SEARCH=OFF"
  "-DMLIR_INSTALL_AGGREGATE_OBJECTS=OFF"
  "-DMLIR_INCLUDE_DOCS=OFF"
)

list(APPEND llvm_project_build_byproducts
  "${CMAKE_BINARY_DIR}/i-mlir"
)

list(APPEND llvm_project_build_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target mlir-distribution
)

list(APPEND llvm_project_install_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target install-mlir-distribution-stripped
  COMMAND "${CMAKE_COMMAND}" -E rm -frR "${CMAKE_BINARY_DIR}/i-mlir"
  COMMAND "${CMAKE_COMMAND}" -E rename
    "${CMAKE_BINARY_DIR}/i"
    "${CMAKE_BINARY_DIR}/i-mlir"
)
