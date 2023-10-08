include_guard(GLOBAL)

if(NOT TOOLCHAINS_ENABLE_CROSS_COMPILE)
  return()
endif()

message(NOTICE "toolchains: Configuring phases: `build-native-llvm-tools`")

##################################################################
# Configure the `vcvarsall.bat` launcher for Windows MSVC builds #
##################################################################

list(APPEND toolchains_llvm_project_args_bootstrap
  ${toolchains_llvm_project_args}
)

if(CMAKE_HOST_WIN32)
  list(APPEND toolchains_llvm_project_args_bootstrap
    CMAKE_COMMAND "${toolchains_cmake_vcvars_native}"
  )
endif()

set(llvm_enable_projects "")

list(APPEND build_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-host-p/src/tlp-host-b"
    --target llvm-tblgen
)

if(TOOLCHAINS_ENABLE_CLANG)
  list(APPEND llvm_enable_projects
    clang
  )
  list(APPEND build_commands
    COMMAND "${CMAKE_COMMAND}"
      --build "${CMAKE_BINARY_DIR}/tlp-host-p/src/tlp-host-b"
      --target clang-tblgen
  )
endif()

if(TOOLCHAINS_ENABLE_MLIR)
  list(APPEND llvm_enable_projects
    mlir
  )
  list(APPEND build_commands
    COMMAND "${CMAKE_COMMAND}"
      --build "${CMAKE_BINARY_DIR}/tlp-host-p/src/tlp-host-b"
      --target mlir-tblgen
    COMMAND "${CMAKE_COMMAND}"
      --build "${CMAKE_BINARY_DIR}/tlp-host-p/src/tlp-host-b"
      --target mlir-linalg-ods-yaml-gen
  )
endif()

list(JOIN llvm_enable_projects "|" llvm_enable_projects)

ExternalProject_Add(tlp-host
  ${toolchains_llvm_project_args_bootstrap}
  PREFIX "tlp-host-p"

  BINARY_DIR "tlp-host-p/src/tlp-host-b"
  STAMP_DIR "tlp-host-p/src/tlp-host-s"

  DEPENDS "lp"

  ${TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS}

  CMAKE_ARGS
    --fresh
    -Wno-deprecated
    -Wno-dev
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/tools/host"
    "-DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}"
    ${llvm_project_cmake_args}
    "-DLLVM_TARGETS_TO_BUILD=host"
    "-DLLVM_ENABLE_PROJECTS=${llvm_enable_projects}"
    "-DLLVM_BUILD_UTILS=ON"

  BUILD_COMMAND ""
    ${build_commands}

  INSTALL_COMMAND ""
)
