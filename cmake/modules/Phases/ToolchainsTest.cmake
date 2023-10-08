include_guard(GLOBAL)

message(NOTICE "toolchains: Configuring phases: `test-distributions-archives`")

include(CTest)

if(CMAKE_HOST_WIN32)
  set(cmake_ctest_command "${toolchains_ctest_vcvars_target}")
else()
  set(cmake_ctest_command "${CMAKE_CTEST_COMMAND}")
endif()

set(toolchains_test_cmake_source_dir "${CMAKE_SOURCE_DIR}/cmake/projects/toolchains-test")
set(toolchains_test_cmake_binary_dir "${CMAKE_BINARY_DIR}/tt-p")

set(toolchains_cmake_crosscompiling_emulator "")
if(DEFINED CMAKE_CROSSCOMPILING_EMULATOR)
  set(toolchains_cmake_crosscompiling_emulator "${CMAKE_CROSSCOMPILING_EMULATOR}")
endif()

# NOTE: This is necessary in order to avoid
# `"-DTOOLCHAINS_DISTRIBUTIONS_ARCHIVES=${toolchains_package_build_byproducts}"` (below) expanding
# with spaces. Alternatively, we could move this define directly into the `add_test` call further
# below, which seemingly works as expected, but it's better to be explicit about it here to draw
# attention, for the sake of future refactorings.
string(JOIN "\\;" toolchains_package_build_byproducts ${toolchains_package_build_byproducts})

list(APPEND toolchains_test_build_cmake_args
  "-DTOOLCHAINS_CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}"
  "-DTOOLCHAINS_CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR}"
  "-DTOOLCHAINS_TARGET_TRIPLE=${toolchains_target_triple_simplified}"
  "-DTOOLCHAINS_DISTRIBUTIONS_ARCHIVES=${toolchains_package_build_byproducts}"
  "-DCMAKE_ASM_COMPILER=${CMAKE_ASM_COMPILER}"
  "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
  "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
  "-DCMAKE_LINKER=${CMAKE_LINKER}"
)
if(CMAKE_HOST_APPLE)
  list(APPEND toolchains_test_build_cmake_args
    "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
  )
endif()

add_test(NAME toolchains-test-build
  COMMAND "${cmake_ctest_command}"
    --build-and-test "${toolchains_test_cmake_source_dir}"
                     "${toolchains_test_cmake_binary_dir}"
    --build-generator ${CMAKE_GENERATOR}
    --build-makeprogram ${CMAKE_MAKE_PROGRAM}
    --build-project toolchains-test
    --parallel 1
    --stop-on-failure
    --output-on-failure
    --extra-verbose
    --output-log ${CMAKE_BINARY_DIR}/tt-p/output.log
    --build-options
      --fresh
      -Werror=deprecated
      -Werror=dev
      --warn-uninitialized
      "-DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}"
      "-DCMAKE_CROSSCOMPILING_EMULATOR=${toolchains_cmake_crosscompiling_emulator}"
      "-DTOOLCHAINS_NATIVE_CAN_EXECUTE_TARGET=${toolchains_native_can_execute_target}"
      ${toolchains_cross_compilation_system_flags}
      ${toolchains_cross_compilation_compiler_target_flags}
      ${toolchains_test_build_cmake_args}
)

if(NOT CMAKE_CROSSCOMPILING_EMULATOR AND NOT toolchains_native_can_execute_target)
  return()
endif()

list(APPEND toolchains-test-accumulated-depends
  toolchains-test-build
)

if(TOOLCHAINS_ENABLE_LLVM)
  add_test(NAME toolchains-test-exe-llvm
    COMMAND ${toolchains_cmake_crosscompiling_emulator}
      "${toolchains_test_cmake_binary_dir}/tt-llvm-p/src/tt-llvm-b/exe-llvm"
      --help
  )
  set_tests_properties(toolchains-test-exe-llvm
    PROPERTIES
      DEPENDS "${toolchains-test-accumulated-depends}"
  )
  list(APPEND toolchains-test-accumulated-depends
    toolchains-test-exe-llvm
  )
endif()

if(TOOLCHAINS_ENABLE_MLIR)
  add_test(NAME toolchains-test-exe-mlir
    COMMAND ${toolchains_cmake_crosscompiling_emulator}
      "${toolchains_test_cmake_binary_dir}/tt-mlir-p/src/tt-mlir-b/exe-mlir"
      --help
  )
  set_tests_properties(toolchains-test-exe-mlir
    PROPERTIES
      DEPENDS "${toolchains-test-accumulated-depends}"
  )
  list(APPEND toolchains-test-accumulated-depends
    toolchains-test-exe-mlir
  )
endif()

if(TOOLCHAINS_ENABLE_CLANG)
  add_test(NAME toolchains-test-exe-clang
    COMMAND ${toolchains_cmake_crosscompiling_emulator}
      "${toolchains_test_cmake_binary_dir}/tt-clang-p/src/tt-clang-b/exe-clang"
      --help
  )
  set_tests_properties(toolchains-test-exe-clang
    PROPERTIES
      DEPENDS "${toolchains-test-accumulated-depends}"
  )
  list(APPEND toolchains-test-accumulated-depends
    toolchains-test-exe-mlir
  )
endif()

if(TOOLCHAINS_ENABLE_SWIFT)
  add_test(NAME toolchains-test-exe-swift
    COMMAND ${toolchains_cmake_crosscompiling_emulator}
      "${toolchains_test_cmake_binary_dir}/tt-swift-p/src/tt-swift-b/exe-swift")
  set_tests_properties(toolchains-test-exe-swift
    PROPERTIES
      DEPENDS "${toolchains-test-accumulated-depends}"
  )
  list(APPEND toolchains-test-accumulated-depends
    toolchains-test-exe-swift
  )
else()
  if(TOOLCHAINS_ENABLE_TOOL_CLANG)
    add_test(NAME toolchains-test-exe-tool_clang
      COMMAND ${toolchains_cmake_crosscompiling_emulator}
        "${toolchains_test_cmake_binary_dir}/tt-tool_clang-p/src/tt-tool_clang-b/exe-tool_clang")
    set_tests_properties(toolchains-test-exe-tool_clang
      PROPERTIES
        DEPENDS "${toolchains-test-accumulated-depends}"
    )
    list(APPEND toolchains-test-accumulated-depends
      toolchains-test-exe-tool_clang
    )
  endif()
  if(TOOLCHAINS_ENABLE_TOOL_LLD)
    add_test(NAME toolchains-test-exe-tool_lld
      COMMAND ${toolchains_cmake_crosscompiling_emulator}
        "${toolchains_test_cmake_binary_dir}/tt-tool_lld-p/src/tt-tool_lld-b/exe-tool_lld")
    set_tests_properties(toolchains-test-exe-tool_lld
      PROPERTIES
        DEPENDS "${toolchains-test-accumulated-depends}"
    )
    list(APPEND toolchains-test-accumulated-depends
      toolchains-test-exe-tool_lld
    )
  endif()
endif()
