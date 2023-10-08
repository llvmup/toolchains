include_guard(GLOBAL)

message(NOTICE "toolchains: Configuring phases")

include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/ToolchainsPrepareDependencies.cmake")

function(toolchains_add_distribution_requirements)
  cmake_parse_and_validate_arguments(
    # prefix
    "ARG"
    # options
    ""
    # one_value_keywords
    "INPUT_DISTRIBUTION;INPUT_LLVM_DISTRIBUTIONS"
    # multi_value_keywords
    "INPUT_DISTRIBUTION_REQUIREMENTS"
    # # non-empty multi_value_keywords
    # ""
    # pass through arguments
    "${ARGN}"
  )
  foreach(requirement IN ITEMS ${ARG_INPUT_DISTRIBUTION_REQUIREMENTS})
    if(NOT TOOLCHAINS_ENABLE_${requirement})
      message(FATAL_ERROR "toolchains: ${ARG_INPUT_DISTRIBUTION} requires the ${requirement} to be enabled")
    endif()
    list(PREPEND ${ARG_INPUT_LLVM_DISTRIBUTIONS} ${ARG_INPUT_DISTRIBUTION} ${ARG_INPUT_DISTRIBUTION_REQUIREMENTS})
    list(REMOVE_DUPLICATES ${ARG_INPUT_LLVM_DISTRIBUTIONS})
    list(SORT ${ARG_INPUT_LLVM_DISTRIBUTIONS})
    set(${ARG_INPUT_LLVM_DISTRIBUTIONS} "${${ARG_INPUT_LLVM_DISTRIBUTIONS}}" PARENT_SCOPE)
  endforeach()
endfunction()

###########################################################
# Configure external project arguments for `llvm-project` #
###########################################################

list(APPEND toolchains_llvm_project_args
  SOURCE_DIR "${CMAKE_BINARY_DIR}/lp-p/src/lp"
  SOURCE_SUBDIR "llvm"
  LIST_SEPARATOR "|"
)

############################################################
# Configure external project CMAKE_ARGS for `llvm-project` #
############################################################

list(APPEND llvm_project_cmake_args
  ${toolchains_cmake_args}
)

if(CMAKE_HOST_APPLE)
endif()

if(CMAKE_HOST_WIN32)
  list(APPEND llvm_project_cmake_args
    "-DLLVM_USE_CRT_RELEASE=MT"
    "-DLLVM_USE_CRT_DEBUG=MTd"
  )
endif()

list(APPEND llvm_project_cmake_args
  "-DBUILD_SHARED_LIBS=OFF"

  "-DLLVM_ENABLE_WARNINGS=OFF"
  "-DLLVM_INCLUDE_BENCHMARKS=OFF"
  "-DLLVM_INCLUDE_DOCS=OFF"
  "-DLLVM_INCLUDE_EXAMPLES=OFF"
  "-DLLVM_INCLUDE_TESTS=OFF"
  "-DLLVM_BUILD_TOOLS=OFF"
  "-DLLVM_BUILD_UTILS=OFF"
  "-DLLVM_BUILD_LLVM_C_DYLIB=OFF"

  "-DCLANG_INCLUDE_DOCS=OFF"
  "-DCLANG_INCLUDE_TESTS=OFF"

  "-DCLANG_TOOL_AMDGPU_ARCH_BUILD=OFF"
  "-DCLANG_TOOL_APINOTES_TEST_BUILD=OFF"
  "-DCLANG_TOOL_ARCMT_TEST_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_CHECK_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_DIFF_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_EXTDEF_MAPPING_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_FORMAT_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_FORMAT_VS_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_FUZZER_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_IMPORT_TEST_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_LINKER_WRAPPER_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_OFFLOAD_BUNDLER_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_OFFLOAD_PACKAGER_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_REFACTOR_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_RENAME_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_REPL_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_SCAN_DEPS_BUILD=OFF"
  "-DCLANG_TOOL_CLANG_SHLIB_BUILD=OFF"
  "-DCLANG_TOOL_C_ARCMT_TEST_BUILD=OFF"
  "-DCLANG_TOOL_C_INDEX_TEST_BUILD=OFF"
  "-DCLANG_TOOL_DIAGTOOL_BUILD=OFF"
  "-DCLANG_TOOL_DRIVER_BUILD=ON"
  "-DCLANG_TOOL_LIBCLANG_BUILD=OFF"
  "-DCLANG_TOOL_SCAN_BUILD_BUILD=OFF"
  "-DCLANG_TOOL_SCAN_BUILD_PY_BUILD=OFF"
  "-DCLANG_TOOL_SCAN_VIEW_BUILD=OFF"
)

include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/ToolchainsBuildNativeTools.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/ToolchainsBuildTargetDistributions.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/ToolchainsEmitProperties.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/ToolchainsPack.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/ToolchainsInstall.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/ToolchainsTest.cmake")
