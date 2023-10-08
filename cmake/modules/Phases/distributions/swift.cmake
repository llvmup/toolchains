include_guard(GLOBAL)

if(NOT TOOLCHAINS_ENABLE_SWIFT)
  return()
endif()

message(NOTICE "toolchains: Configuring distributions: `Swift`")

toolchains_add_distribution_requirements(
  INPUT_DISTRIBUTION "SWIFT"
  INPUT_DISTRIBUTION_REQUIREMENTS
    "CLANG"
    "LLVM"
  INPUT_LLVM_DISTRIBUTIONS llvm_project_cmake_args_LLVM_DISTRIBUTIONS
)

set(llvm_project_cmake_args_LLVM_SWIFT_DISTRIBUTION_COMPONENTS
  "swift-headers"
  "swift-libraries"
  "swift-cmake-exports"
  "swift-swift-cmake-exports"
  "swift-license"
)

list(JOIN llvm_project_cmake_args_LLVM_SWIFT_DISTRIBUTION_COMPONENTS "|" llvm_project_cmake_args_LLVM_SWIFT_DISTRIBUTION_COMPONENTS)

if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
endif()

list(APPEND llvm_project_cmake_args
  "-DLLVM_BUILD_STATIC_CAS_PLUGIN_TEST=ON"

  "-DCLANG_TOOL_CLANG_CAS_TEST_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_REFACTOR_TEST_BUILD=OFF"
  "-DCLANG_TOOL_INDEXSTORE_BUILD=OFF"

  "-DLLVM_SWIFT_DISTRIBUTION_COMPONENTS=${llvm_project_cmake_args_LLVM_SWIFT_DISTRIBUTION_COMPONENTS}"

  "-DLLVM_EXTERNAL_CMARK_SOURCE_DIR=${CMAKE_BINARY_DIR}/lp-p/src/lp/cmark"
  "-DCMARK_SHARED=OFF"
  "-DCMARK_STATIC=ON"
  "-DCMARK_EXPORT_LIBRARY_TARGETS_ONLY=ON"

  "-DLLVM_EXTERNAL_SWIFT_SOURCE_DIR=${CMAKE_BINARY_DIR}/lp-p/src/lp/swift"
  "-DSWIFT_USE_LINKER=${CMAKE_LINKER}"
  "-DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE=${CMAKE_BINARY_DIR}/lp-p/src/lp/ss"
  "-DSWIFT_INCLUDE_DOCS=OFF"
  "-DSWIFT_INCLUDE_TESTS=OFF"
  "-DSWIFT_INCLUDE_TEST_BINARIES=OFF"
  "-DSWIFT_BUILD_DYNAMIC_SDK_OVERLAY=OFF"
  "-DSWIFT_BUILD_DYNAMIC_STDLIB=OFF"
  "-DSWIFT_BUILD_HOST_DISPATCH=OFF"
  "-DSWIFT_BUILD_PERF_TESTSUITE=OFF"
  "-DSWIFT_BUILD_REMOTE_MIRROR=OFF"
  "-DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON"
  "-DSWIFT_BUILD_STATIC_STDLIB=OFF"
  "-DSWIFT_BUILD_STATIC_DEMANGLE=ON"
  "-DSWIFT_BUILD_STATIC_MOCK_PLUGIN=ON"
  "-DSWIFT_BUILD_STATIC_SCAN=ON"
  "-DSWIFT_BUILD_STATIC_STATIC_MIRROR=ON"
  "-DSWIFT_BUILD_STDLIB_CXX_MODULE=OFF"
  "-DSWIFT_BUILD_STDLIB_EXTRA_TOOLCHAIN_CONTENT=OFF"
  "-DSWIFT_ENABLE_DISPATCH=OFF"
  "-DSWIFT_INSTALL_COMPONENTS=swift-libraries|swift-license"
)

if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
  list(APPEND llvm_project_cmake_args
    "-DSWIFT_HOST_VARIANT_ARCH=${toolchains_target_arch}"
    # "-DSWIFT_HOST_TRIPLE=${toolchains_target_triple_normalized}"
  )
  if(CMAKE_HOST_APPLE)
    list(APPEND llvm_project_cmake_args
      "-DSWIFT_HOST_VARIANT=macosx"
      "-DSWIFT_HOST_VARIANT_SDK=OSX"
    )
  elseif(CMAKE_HOST_LINUX)
    list(APPEND llvm_project_cmake_args
      "-DSWIFT_HOST_VARIANT=linux"
      "-DSWIFT_HOST_VARIANT_SDK=LINUX"
    )
  elseif(CMAKE_HOST_WIN32)
    list(APPEND llvm_project_cmake_args
      "-DSWIFT_HOST_VARIANT=windows"
      "-DSWIFT_HOST_VARIANT_SDK=WINDOWS"
    )
  endif()
endif()

if(CMAKE_HOST_APPLE)
  list(APPEND llvm_project_cmake_args
    "-DSWIFT_LIPO=${CMAKE_LIPO}"
    "-DSWIFT_DARWIN_DEPLOYMENT_VERSION_OSX=${SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX}"
  )
endif()

list(APPEND llvm_project_cmake_args_LLVM_EXTERNAL_PROJECTS
  "cmark"
  "swift"
)

list(APPEND llvm_project_depends
  "sc"
  "s"
)

list(APPEND llvm_project_build_byproducts
  "${CMAKE_BINARY_DIR}/i-swift"
)

list(APPEND llvm_project_build_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target swift-distribution
)

list(APPEND llvm_project_install_commands
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
    --target install-swift-distribution-stripped
  COMMAND "${CMAKE_COMMAND}"
    --install "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b/tools/cmark/src"
    --component cmark-headers
  COMMAND "${CMAKE_COMMAND}"
    --install "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b/tools/cmark/src"
    --component cmark-static-libraries
  COMMAND "${CMAKE_COMMAND}"
    --install "${CMAKE_BINARY_DIR}/tlp-p/src/tlp-b/tools/cmark/src"
    --component cmark-cmake-exports
  COMMAND "${CMAKE_COMMAND}" -E rm -frR "${CMAKE_BINARY_DIR}/i-swift"
  COMMAND "${CMAKE_COMMAND}" -E rename
    "${CMAKE_BINARY_DIR}/i"
    "${CMAKE_BINARY_DIR}/i-swift"
)
