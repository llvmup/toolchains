include_guard(GLOBAL)

option(CMAKE_COLOR_DIAGNOSTICS "Whether to enable color diagnostics" ON)

set(CMAKE_BUILD_TYPE MinSizeRel CACHE STRING
  "CMake build type for the toolchain distributions."
)

set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING
  "Minimum macOS version to target."
)
set(SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX "${CMAKE_OSX_DEPLOYMENT_TARGET}" CACHE STRING
  "Swift macOS deployment version to target."
)

set(CPACK_GENERATOR TXZ CACHE STRING
  "Comma-separated list of package generators to use."
)

set(TOOLCHAINS_TARGET_ARCH "native" CACHE STRING
  "Architecture to target when building the distributions."
)

if("${CPACK_GENERATOR}" STREQUAL "TZST")
  set(TOOLCHAINS_COMPRESSION "Zstd" CACHE STRING INTERNAL)
  set(TOOLCHAINS_MANIFEST_ARCHIVE_EXTENSION ".zst" CACHE STRING INTERNAL)
  set(TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION ".tar.zst" CACHE STRING INTERNAL)
elseif("${CPACK_GENERATOR}" STREQUAL "TXZ")
  set(TOOLCHAINS_COMPRESSION "XZ" CACHE STRING INTERNAL)
  set(TOOLCHAINS_MANIFEST_ARCHIVE_EXTENSION ".xz" CACHE STRING INTERNAL)
  set(TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION ".tar.xz" CACHE STRING INTERNAL)
elseif("${CPACK_GENERATOR}" STREQUAL "TGZ")
  set(TOOLCHAINS_COMPRESSION "GZip" CACHE STRING INTERNAL)
  set(TOOLCHAINS_MANIFEST_ARCHIVE_EXTENSION ".gz" CACHE STRING INTERNAL)
  set(TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION ".tar.gz" CACHE STRING INTERNAL)
else()
  message(FATAL_ERROR "toolchains: unexpected CPack generator: ${CPACK_GENERATOR}")
endif()

block()
  set(description "Use the Homebrew LLVM toolchain if available on the system. Only meaningful for macOS and Linux.")
  if(CMAKE_HOST_WIN32)
    set(value OFF)
  else()
    set(value ON)
  endif()
  set(TOOLCHAINS_ENABLE_HOMEBREW_HOST_LLVM ${value} CACHE BOOL "${description}")
endblock()

block()
  set(description "Use the Scoop LLVM toolchain if available on the system. Only meaningful for Windows.")
  if(NOT CMAKE_HOST_WIN32)
    set(value OFF)
  else()
    set(value ON)
  endif()
  set(TOOLCHAINS_ENABLE_SCOOP_HOST_LLVM ${value} CACHE BOOL "${description}")
endblock()

set(TOOLCHAINS_ENABLE_LTO "Thin" CACHE STRING
  "Build distributions with link-time optimization. Possible values are: Off, Thin, Full."
)
set(LLVM_ENABLE_LTO "${TOOLCHAINS_ENABLE_LTO}")

option(TOOLCHAINS_ENABLE_CLANG
  "Build the Clang distribution."
  ON
)

option(TOOLCHAINS_ENABLE_LLVM
  "Build the LLVM distribution."
  ON
)

option(TOOLCHAINS_ENABLE_MLIR
  "Build the MLIR distribution."
  ON
)

option(TOOLCHAINS_ENABLE_SWIFT
  "Build the Swift distribution. Enabling this mandates building the other distributions from the Apple LLVM source tree."
  OFF
)

option(TOOLCHAINS_ENABLE_TOOL_CLANG
  "Build the `clang` tool distribution."
  ON
)
if(TOOLCHAINS_ENABLE_SWIFT)
  set(TOOLCHAINS_ENABLE_TOOL_CLANG OFF CACHE BOOL
    "Build the `clang` tool distribution."
    FORCE
  )
endif()

option(TOOLCHAINS_ENABLE_TOOL_LLD
  "Build the `lld` tool distribution."
  ON
)
if(TOOLCHAINS_ENABLE_SWIFT OR "${TOOLCHAINS_TARGET_ARCH}" STREQUAL "s390x")
  set(TOOLCHAINS_ENABLE_TOOL_LLD OFF CACHE BOOL
    "Build the `lld` tool distribution."
    FORCE
  )
endif()

option(TOOLCHAINS_EMIT_STANDALONE_MANIFESTS
  "Emit standalone manifests for the distributions in addition to the in-tree manifests."
  ON
)

set(TOOLCHAINS_LLVM_TARGETS_TO_BUILD "all" CACHE STRING
  "Semicolon-separated list of targets to build, or \"all\"."
)

set(TOOLCHAINS_VISUAL_STUDIO_VERSION "17" CACHE STRING
  "Version of Visual Studio to use for Windows MSVC builds."
)

set(TOOLCHAINS_LLVM_PROJECT_VERSION "17.0.6")
set(TOOLCHAINS_LLVM_PROJECT_VERSION_MAJOR "17")
set(TOOLCHAINS_LLVM_PROJECT_VERSION_MINOR "0")
set(TOOLCHAINS_LLVM_PROJECT_VERSION_PATCH "6")
set(TOOLCHAINS_LLVM_PROJECT_VERSION_TAG "llvmorg-${TOOLCHAINS_LLVM_PROJECT_VERSION}")

set(TOOLCHAINS_APPLE_LLVM_PROJECT_VERSION "16.0.0")
set(TOOLCHAINS_APPLE_LLVM_PROJECT_VERSION_MAJOR "16")
set(TOOLCHAINS_APPLE_LLVM_PROJECT_VERSION_MINOR "0")
set(TOOLCHAINS_APPLE_LLVM_PROJECT_VERSION_PATCH "0")

set(TOOLCHAINS_SWIFT_VERSION "5.9.1")
set(TOOLCHAINS_SWIFT_VERSION_MAJOR "5")
set(TOOLCHAINS_SWIFT_VERSION_MINOR "9")
set(TOOLCHAINS_SWIFT_VERSION_PATCH "1")
set(TOOLCHAINS_SWIFT_VERSION_TAG "swift-${TOOLCHAINS_SWIFT_VERSION}-RELEASE")

if(DEFINED TOOLCHAINS_RELEASE_REV)
  set(TOOLCHAINS_RELEASE_REV_SUFFIX "+rev${TOOLCHAINS_RELEASE_REV}" CACHE STRING INTERNAL)
else()
  set(TOOLCHAINS_RELEASE_REV_SUFFIX "" CACHE STRING INTERNAL)
endif()

if(TOOLCHAINS_ENABLE_SWIFT)
  set(TOOLCHAINS_TREE_NAME "swift-${TOOLCHAINS_SWIFT_VERSION}" CACHE STRING INTERNAL)
else()
  set(TOOLCHAINS_TREE_NAME "llvmorg-${TOOLCHAINS_LLVM_PROJECT_VERSION}" CACHE STRING INTERNAL)
endif()

if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  string(APPEND TOOLCHAINS_TREE_NAME "-debug")
endif()

set(TOOLCHAINS_EXTERNAL_LLVM_PROJECT_URL "https://github.com/llvm/llvm-project/releases/download/${TOOLCHAINS_LLVM_PROJECT_VERSION_TAG}/llvm-project-${TOOLCHAINS_LLVM_PROJECT_VERSION}.src.tar.xz")
set(TOOLCHAINS_EXTERNAL_LLVM_PROJECT_URL_HASH "6d85bf749e0d77553cc215cbfa61cec4ac4f4f652847f56f946b6a892a99a5ea40b6ab8b39a9708a035001f007986941ccf17e4635260a8b0c1fa59e78d41e30")
set(TOOLCHAINS_EXTERNAL_LLVM_PROJECT_DOWNLOAD_NAME "llvm-project-${TOOLCHAINS_LLVM_PROJECT_VERSION_TAG}.src.tar.xz")

set(TOOLCHAINS_EXTERNAL_APPLE_LLVM_PROJECT_URL "https://github.com/apple/llvm-project/archive/refs/tags/${TOOLCHAINS_SWIFT_VERSION_TAG}.tar.gz")
set(TOOLCHAINS_EXTERNAL_APPLE_LLVM_PROJECT_URL_HASH "54d49117595ad082dce4ef21d3ef466645cbf3521e82f55ec10c9b899f4d84b78a920429f48cef6ee5b3c1d101bbd041823c1eddcbc673b17d5cf9584e400c8a")
set(TOOLCHAINS_EXTERNAL_APPLE_LLVM_PROJECT_DOWNLOAD_NAME "llvm-project-${TOOLCHAINS_SWIFT_VERSION_TAG}.tar.gz")

set(TOOLCHAINS_EXTERNAL_APPLE_SWIFT_CMARK_URL "https://github.com/apple/swift-cmark/archive/refs/tags/${TOOLCHAINS_SWIFT_VERSION_TAG}.tar.gz")
set(TOOLCHAINS_EXTERNAL_APPLE_SWIFT_CMARK_URL_HASH "f2f0a44fbdbff3f89b2928543e6759696de58911a56957e9c87faf0ba3d98a93470ef18d88e7261a93e7b6b531c37175264e64630bdf0f3f4f480fd1c03a541b")
set(TOOLCHAINS_EXTERNAL_APPLE_SWIFT_CMARK_DOWNLOAD_NAME "swift-cmark-${TOOLCHAINS_SWIFT_VERSION_TAG}.tar.gz")

set(TOOLCHAINS_EXTERNAL_APPLE_SWIFT_URL "https://github.com/apple/swift/archive/refs/tags/${TOOLCHAINS_SWIFT_VERSION_TAG}.tar.gz")
set(TOOLCHAINS_EXTERNAL_APPLE_SWIFT_URL_HASH "ca896487dad18fc8d38d286152a29f9538405e8c245e1954edc6e98c3a1a224ab8a321e33db973a56c37dacb51e1834937840e508bb5192c4ba5b50638ef6594")
set(TOOLCHAINS_EXTERNAL_APPLE_SWIFT_DOWNLOAD_NAME "${TOOLCHAINS_SWIFT_VERSION_TAG}.tar.gz")

list(APPEND TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS
  LOG_DOWNLOAD TRUE
  LOG_UPDATE TRUE
  LOG_PATCH TRUE
  LOG_CONFIGURE TRUE
  LOG_BUILD TRUE
  LOG_INSTALL TRUE
  LOG_TEST TRUE
  LOG_MERGED_STDOUTERR TRUE
  LOG_OUTPUT_ON_FAILURE TRUE
)

set(TOOLCHAINS_FIND_PACKAGE_LLVM_VERSION_ARGS "")
if(NOT TOOLCHAINS_ENABLE_SWIFT)
  list(APPEND TOOLCHAINS_FIND_PACKAGE_LLVM_VERSION_ARGS
    "${TOOLCHAINS_LLVM_PROJECT_VERSION}" EXACT
  )
endif()

set(TOOLCHAINS_HOMEBREW_HOST_LLVM_VERSION "17" CACHE STRING
  "Version of the Homebrew LLVM package to use."
)
block()
  if(NOT CMAKE_HOST_WIN32 AND TOOLCHAINS_ENABLE_HOMEBREW_HOST_LLVM)
    message(NOTICE "toolchains: Detecting Homebrew LLVM toolchain")
    execute_process(
      COMMAND brew --prefix "llvm@${TOOLCHAINS_HOMEBREW_HOST_LLVM_VERSION}"
      RESULT_VARIABLE brew_llvm_prefix_result
      OUTPUT_VARIABLE brew_llvm_prefix
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(brew_llvm_prefix_result EQUAL 0 AND EXISTS "${brew_llvm_prefix}/bin")
      set(TOOLCHAINS_HOMEBREW_HOST_LLVM_PREFIX "${brew_llvm_prefix}" CACHE STRING INTERNAL)
      message("  + toolchain prefix: ${TOOLCHAINS_HOMEBREW_HOST_LLVM_PREFIX}")
    else()
      message("  + toolchain prefix: not found")
    endif()
  endif()
endblock()

set(TOOLCHAINS_SCOOP_HOST_LLVM_VERSION "17" CACHE STRING
  "Version of the Scoop LLVM package to use."
)
block()
  if(CMAKE_HOST_WIN32 AND TOOLCHAINS_ENABLE_SCOOP_HOST_LLVM)
    message(NOTICE "toolchains: Detecting Scoop LLVM toolchain")
    execute_process(
      COMMAND scoop.cmd prefix llvm
      RESULT_VARIABLE scoop_llvm_prefix_result
      OUTPUT_VARIABLE scoop_llvm_prefix
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(scoop_llvm_prefix_result EQUAL 0 AND EXISTS "${scoop_llvm_prefix}/bin")
      cmake_path(CONVERT "${scoop_llvm_prefix}" TO_CMAKE_PATH_LIST scoop_llvm_prefix NORMALIZE)
      set(TOOLCHAINS_SCOOP_HOST_LLVM_PREFIX "${scoop_llvm_prefix}" CACHE STRING INTERNAL)
      message("  + toolchain prefix: ${TOOLCHAINS_SCOOP_HOST_LLVM_PREFIX}")
    else()
      message("  + toolchain prefix: not found")
    endif()
  endif()
endblock()

