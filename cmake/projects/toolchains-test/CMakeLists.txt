cmake_minimum_required(VERSION 3.27.0 FATAL_ERROR)

set(CMAKE_SKIP_INSTALL_RULES ON)

list(APPEND toolchains_defined_variables
  CMAKE_CROSSCOMPILING_EMULATOR
  CMAKE_VERBOSE_MAKEFILE
  CMAKE_ASM_COMPILER
  CMAKE_C_COMPILER
  CMAKE_CXX_COMPILER
  CMAKE_LINKER
  TOOLCHAINS_CMAKE_SOURCE_DIR
  TOOLCHAINS_CMAKE_BINARY_DIR
  TOOLCHAINS_NATIVE_CAN_EXECUTE_TARGET
  TOOLCHAINS_TARGET_TRIPLE
  TOOLCHAINS_DISTRIBUTIONS_ARCHIVES
)
if(CMAKE_HOST_APPLE)
  list(APPEND toolchains_defined_variables
    CMAKE_OSX_DEPLOYMENT_TARGET
  )
endif()
foreach(variable IN ITEMS ${toolchains_defined_variables})
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
)
list(APPEND toolchains_cache_variables_internal
  TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION
  TOOLCHAINS_TREE_NAME
  TOOLCHAINS_RELEASE_REV_SUFFIX
)
load_cache("${TOOLCHAINS_CMAKE_BINARY_DIR}"
  ${toolchains_cache_variables}
  INCLUDE_INTERNALS
    ${toolchains_cache_variables_internal}
)
foreach(variable IN ITEMS
  ${toolchains_cache_variables}
  ${toolchains_cache_variables_internal}
)
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: Could not load cache variable `${variable}`")
  endif()
endforeach()

include("${TOOLCHAINS_CMAKE_SOURCE_DIR}/cmake/modules/Support/ConfigureVariables.cmake")
include("${TOOLCHAINS_CMAKE_SOURCE_DIR}/cmake/modules/Support/ConfigureFindPackages.cmake")
include(ExternalProject)

set(CMAKE_ASM_COMPILER_WORKS TRUE)
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)

project(toolchains-test
  LANGUAGES ASM C CXX
)

list(APPEND distributions
  llvm
  mlir
  clang
)

if(TOOLCHAINS_ENABLE_SWIFT)
  list(APPEND distributions
    swift
  )
else()
  list(APPEND distributions
    tool_clang
    tool_lld
  )
endif()

list(JOIN TOOLCHAINS_DISTRIBUTIONS_ARCHIVES "," TOOLCHAINS_DISTRIBUTIONS_ARCHIVES)

set(external_project_previous_name "")
foreach(distribution IN ITEMS ${distributions})
  string(TOUPPER "${distribution}" distribution_upper)
  if(TOOLCHAINS_ENABLE_${distribution_upper})
    if("${distribution}" MATCHES "^tool_")
      if(NOT CMAKE_CROSSCOMPILING_EMULATOR AND NOT TOOLCHAINS_NATIVE_CAN_EXECUTE_TARGET)
        continue()
      endif()
    endif()

    set(cross_compilation_flags "")

    foreach(variable in ITEMS
      CMAKE_SYSTEM_NAME
      CMAKE_SYSTEM_PROCESSOR
      CMAKE_CROSSCOMPILING_EMULATOR
      CMAKE_APPLE_SILICON_PROCESSOR
      CMAKE_OSX_ARCHITECTURES
      CMAKE_C_COMPILER_TARGET
      CMAKE_CXX_COMPILER_TARGET
    )
      if(DEFINED ${variable})
        list(APPEND cross_compilation_flags
          "-D${variable}=${${variable}}"
        )
      endif()
    endforeach()

    list(APPEND cmake_args
      "-DCMAKE_C_COMPILER_WORKS=TRUE"
      "-DCMAKE_C_FLAGS=-fuse-ld='${CMAKE_LINKER}' -Wno-unused-command-line-argument"
      "-DCMAKE_CXX_COMPILER_WORKS=TRUE"
      "-DCMAKE_CXX_FLAGS=-fuse-ld='${CMAKE_LINKER}' -Wno-unused-command-line-argument"
      "-DCMAKE_LINKER=${CMAKE_LINKER}"
    )

    if(CMAKE_HOST_APPLE)
      list(APPEND cmake_args
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
      )
    endif()

    if(NOT "${distribution}" STREQUAL "tool_clang")
      list(APPEND cmake_args
        "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
        "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
      )
    endif()

    ExternalProject_Add("tt-${distribution}"
      SOURCE_DIR "${CMAKE_SOURCE_DIR}/distributions/${distribution}"
      BINARY_DIR "tt-${distribution}-p/src/tt-${distribution}-b"
      STAMP_DIR "tt-${distribution}-p/src/tt-${distribution}-s"

      PREFIX "tt-${distribution}-p"

      LIST_SEPARATOR ","

      DEPENDS ${external_project_previous_name}

      ${TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS}

      CMAKE_ARGS
        --fresh
        -Werror=deprecated
        -Werror=dev
        --warn-uninitialized
        "-DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}"
        ${cross_compilation_flags}
        ${cmake_args}
        "-DTOOLCHAINS_CMAKE_SOURCE_DIR=${TOOLCHAINS_CMAKE_SOURCE_DIR}"
        "-DTOOLCHAINS_DISTRIBUTIONS_ARCHIVES=${TOOLCHAINS_DISTRIBUTIONS_ARCHIVES}"
        "-DTOOLCHAINS_ENABLE_SWIFT=${TOOLCHAINS_ENABLE_SWIFT}"
        "-DTOOLCHAINS_TARGET_TRIPLE=${TOOLCHAINS_TARGET_TRIPLE}"
        "-DTOOLCHAINS_TREE_NAME=${TOOLCHAINS_TREE_NAME}"
        "-DTOOLCHAINS_RELEASE_REV_SUFFIX=${TOOLCHAINS_RELEASE_REV_SUFFIX}"

      INSTALL_COMMAND ""
    )

    set(external_project_previous_name "tt-${distribution}")
  endif()
endforeach()
