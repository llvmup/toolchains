cmake_minimum_required(VERSION 3.27.0 FATAL_ERROR)

foreach(variable IN ITEMS
  TOOLCHAINS_CMAKE_SOURCE_DIR
  TOOLCHAINS_CMAKE_BINARY_DIR
  TOOLCHAINS_TARGET_TRIPLE
)
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: `${variable}` must be defined")
  endif()
endforeach()

list(APPEND toolchains_cache_variables
  TOOLCHAINS_ENABLE_CLANG
  TOOLCHAINS_ENABLE_LLVM
  TOOLCHAINS_ENABLE_MLIR
  TOOLCHAINS_ENABLE_SWIFT
  TOOLCHAINS_ENABLE_TOOL_CLANG
  TOOLCHAINS_ENABLE_TOOL_LLD
  TOOLCHAINS_EMIT_STANDALONE_MANIFESTS
)
load_cache("${TOOLCHAINS_CMAKE_BINARY_DIR}"
  READ_WITH_PREFIX ""
  ${toolchains_cache_variables}
  INCLUDE_INTERNALS
    TOOLCHAINS_COMPRESSION
    TOOLCHAINS_MANIFEST_ARCHIVE_EXTENSION
    TOOLCHAINS_TREE_NAME
    TOOLCHAINS_RELEASE_REV_SUFFIX
)
foreach(variable IN ITEMS
  ${toolchains_cache_variables}
  TOOLCHAINS_COMPRESSION
  TOOLCHAINS_MANIFEST_ARCHIVE_EXTENSION
  TOOLCHAINS_TREE_NAME
  # NOTE: `TOOLCHAINS_RELEASE_REV_SUFFIX` is not included because it may not be set.
  # TOOLCHAINS_RELEASE_REV_SUFFIX
)
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: Could not load cache variable `${variable}`")
  endif()
endforeach()

if(NOT TOOLCHAINS_EMIT_STANDALONE_MANIFESTS)
  return()
endif()

foreach(distribution IN ITEMS
  CLANG
  LLVM
  MLIR
  SWIFT
  TOOL_CLANG
  TOOL_LLD
)
  if(TOOLCHAINS_ENABLE_${distribution})
    string(TOUPPER "${distribution}" distribution_upper)
    string(TOLOWER "${distribution}" distribution_lower)
    set(manifest_archive_name "${distribution_lower}-${TOOLCHAINS_TREE_NAME}-${TOOLCHAINS_TARGET_TRIPLE}${TOOLCHAINS_RELEASE_REV_SUFFIX}-llvmup.json${TOOLCHAINS_MANIFEST_ARCHIVE_EXTENSION}")
    file(ARCHIVE_CREATE
      OUTPUT "${TOOLCHAINS_CMAKE_SOURCE_DIR}/dist/${manifest_archive_name}"
      PATHS "${TOOLCHAINS_CMAKE_BINARY_DIR}/i-${distribution_lower}/share/${distribution_lower}/llvmup.json"
      FORMAT "raw"
      COMPRESSION "${TOOLCHAINS_COMPRESSION}"
      VERBOSE
    )
  endif()
endforeach()
