cmake_minimum_required(VERSION 3.27.0 FATAL_ERROR)

project(toolchains-pack
  LANGUAGES NONE
)

foreach(variable IN ITEMS
  CMAKE_INSTALL_PREFIX
  TOOLCHAINS_CMAKE_SOURCE_DIR
  TOOLCHAINS_CMAKE_BINARY_DIR
  TOOLCHAINS_TARGET_TRIPLE
)
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: `${variable}` must be defined")
  endif()
endforeach()

list(APPEND toolchains_cache_variables
  CPACK_GENERATOR
  TOOLCHAINS_ENABLE_CLANG
  TOOLCHAINS_ENABLE_LLVM
  TOOLCHAINS_ENABLE_MLIR
  TOOLCHAINS_ENABLE_SWIFT
  TOOLCHAINS_ENABLE_TOOL_CLANG
  TOOLCHAINS_ENABLE_TOOL_LLD
)
load_cache("${TOOLCHAINS_CMAKE_BINARY_DIR}"
  ${toolchains_cache_variables}
  INCLUDE_INTERNALS
    TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION
    TOOLCHAINS_TREE_NAME
    TOOLCHAINS_RELEASE_REV_SUFFIX
)
foreach(variable IN ITEMS
  ${toolchains_cache_variables}
  TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION
  TOOLCHAINS_TREE_NAME
)
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: Could not load cache variable `${variable}`")
  endif()
endforeach()

list(APPEND llvm_project_cache_variables
  CMAKE_PROJECT_VERSION
  CMAKE_PROJECT_VERSION_MAJOR
  CMAKE_PROJECT_VERSION_MINOR
  CMAKE_PROJECT_VERSION_PATCH
)
if(TOOLCHAINS_ENABLE_SWIFT)
  list(APPEND llvm_project_cache_variables
    SWIFT_VERSION
    SWIFT_VERSION_MAJOR
    SWIFT_VERSION_MINOR
    SWIFT_VERSION_PATCH
  )
endif()
load_cache("${TOOLCHAINS_CMAKE_BINARY_DIR}/tlp-p/src/tlp-b"
  READ_WITH_PREFIX "LLVM_PROJECT_"
  ${llvm_project_cache_variables}
)
list(TRANSFORM llvm_project_cache_variables PREPEND "LLVM_PROJECT_")
foreach(variable IN ITEMS ${llvm_project_cache_variables})
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: Could not load `llvm-project` cache variable `${variable}`")
  endif()
endforeach()

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

    install(DIRECTORY "${TOOLCHAINS_CMAKE_BINARY_DIR}/i-${distribution_lower}/"
      DESTINATION "trees/${TOOLCHAINS_TREE_NAME}${TOOLCHAINS_RELEASE_REV_SUFFIX}/${TOOLCHAINS_TARGET_TRIPLE}"
      USE_SOURCE_PERMISSIONS
      COMPONENT ${distribution_lower}-distribution
    )

    set(distribution_archive_name "${distribution_lower}-${TOOLCHAINS_TREE_NAME}-${TOOLCHAINS_TARGET_TRIPLE}${TOOLCHAINS_RELEASE_REV_SUFFIX}")
    list(APPEND install_packages_commands
      COMMAND "${CMAKE_COMMAND}" -E rename
        "${CMAKE_BINARY_DIR}/${distribution_archive_name}${TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION}"
        "${TOOLCHAINS_CMAKE_SOURCE_DIR}/dist/${distribution_archive_name}${TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION}"
    )

    set(CPACK_ARCHIVE_${distribution_upper}-DISTRIBUTION_FILE_NAME "${distribution_archive_name}")
  endif()
endforeach()

add_custom_target(install-packages-mkdir-dist
  COMMAND "${CMAKE_COMMAND}" -E make_directory "${TOOLCHAINS_CMAKE_SOURCE_DIR}/dist"
  VERBATIM
)
add_custom_target(install-packages
  ${install_packages_commands}
  VERBATIM
)

set(CPACK_PACKAGE_NAME "toolchains")
set(CPACK_PACKAGE_VENDOR "io.github.llvmup")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Prebuilt LLVM toolchain distributions")
if(TOOLCHAINS_ENABLE_SWIFT)
  set(CPACK_PACKAGE_VERSION "${LLVM_PROJECT_SWIFT_VERSION}")
  set(CPACK_PACKAGE_VERSION_MAJOR ${LLVM_PROJECT_SWIFT_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${LLVM_PROJECT_SWIFT_VERSION_MINOR})
  if(DEFINED LLVM_PROJECT_SWIFT_VERSION_PATCH)
    set(CPACK_PACKAGE_VERSION_MINOR ${LLVM_PROJECT_SWIFT_VERSION_PATCH})
  endif()
else()
  set(CPACK_PACKAGE_VERSION "${LLVM_PROJECT_CMAKE_PROJECT_VERSION}")
  set(CPACK_PACKAGE_VERSION_MAJOR ${LLVM_PROJECT_CMAKE_PROJECT_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${LLVM_PROJECT_CMAKE_PROJECT_VERSION_MINOR})
  set(CPACK_PACKAGE_VERSION_PATCH ${LLVM_PROJECT_CMAKE_PROJECT_VERSION_PATCH})
  if(DEFINED LLVM_PROJECT_CMAKE_PROJECT_VERSION_TWEAK)
    set(CPACK_PACKAGE_VERSION_TWEAK ${LLVM_PROJECT_CMAKE_PROJECT_VERSION_TWEAK})
  endif()
endif()

set(CPACK_SOURCE_GENERATOR "${CPACK_GENERATOR}")
set(CPACK_COMPONENTS_GROUPING IGNORE)
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)

set(CPACK_THREADS 0)
set(CPACK_ARCHIVE_THREADS 0)

include(CPack)

if(TOOLCHAINS_ENABLE_CLANG)
  cpack_add_component(clang-distribution
    DISPLAY_NAME "Clang C++ headers and libraries"
    DEPENDS
      llvm-distribution
  )
endif()
if(TOOLCHAINS_ENABLE_LLVM)
  cpack_add_component(llvm-distribution
    DISPLAY_NAME "LLVM C++ headers and libraries"
  )
endif()
if(TOOLCHAINS_ENABLE_MLIR)
  cpack_add_component(mlir-distribution
    DISPLAY_NAME "MLIR C++ headers and libraries"
    DEPENDS
      llvm-distribution
  )
endif()
if(TOOLCHAINS_ENABLE_SWIFT)
  cpack_add_component(swift-distribution
    DISPLAY_NAME "Swift C++ headers and libraries"
    DEPENDS
      clang-distribution
  )
endif()
if(TOOLCHAINS_ENABLE_TOOL_CLANG)
  cpack_add_component(tool_clang-distribution
    DISPLAY_NAME "The `clang` tool and related components"
  )
endif()
if(TOOLCHAINS_ENABLE_TOOL_LLD)
  cpack_add_component(tool_lld-distribution
    DISPLAY_NAME "The `lld` tool and related components"
  )
endif()
