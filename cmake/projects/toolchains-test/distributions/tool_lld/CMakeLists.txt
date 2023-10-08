cmake_minimum_required(VERSION 3.27.0 FATAL_ERROR)

list(APPEND toolchains_defined_variables
  CMAKE_C_COMPILER
  CMAKE_CROSSCOMPILING_EMULATOR
  CMAKE_CXX_COMPILER
  CMAKE_LINKER
  TOOLCHAINS_CMAKE_SOURCE_DIR
  TOOLCHAINS_DISTRIBUTIONS_ARCHIVES
  TOOLCHAINS_ENABLE_SWIFT
  TOOLCHAINS_TARGET_TRIPLE
  TOOLCHAINS_TREE_NAME
  TOOLCHAINS_RELEASE_REV_SUFFIX
)
foreach(variable IN ITEMS ${toolchains_defined_variables})
  if(NOT DEFINED ${variable})
    message(FATAL_ERROR "toolchains: `${variable}` must be defined")
  endif()
endforeach()

set(CMAKE_SKIP_INSTALL_RULES ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include("${TOOLCHAINS_CMAKE_SOURCE_DIR}/cmake/modules/Support/ConfigureVariables.cmake")

set(TOOLCHAINS_DIST_DIR "${CMAKE_BINARY_DIR}/dist")
set(TOOLCHAINS_CMAKE_CONFIG_DIR "${TOOLCHAINS_DIST_DIR}/trees/${TOOLCHAINS_TREE_NAME}${TOOLCHAINS_RELEASE_REV_SUFFIX}/${TOOLCHAINS_TARGET_TRIPLE}/lib/cmake")

foreach(archive IN ITEMS ${TOOLCHAINS_DISTRIBUTIONS_ARCHIVES})
  if("${archive}" MATCHES "^(llvm|tool_lld)-")
    file(ARCHIVE_EXTRACT
      INPUT "${TOOLCHAINS_CMAKE_SOURCE_DIR}/dist/${archive}"
      DESTINATION "${TOOLCHAINS_DIST_DIR}"
    )
  endif()
endforeach()

find_package(LLVM ${TOOLCHAINS_FIND_PACKAGE_LLVM_VERSION_ARGS} REQUIRED CONFIG
  HINTS "${TOOLCHAINS_CMAKE_CONFIG_DIR}"
  NO_DEFAULT_PATH
)
find_package(LLD ${TOOLCHAINS_FIND_PACKAGE_LLVM_VERSION_ARGS} REQUIRED CONFIG
  PATHS "${TOOLCHAINS_CMAKE_CONFIG_DIR}"
  NO_DEFAULT_PATH
)

get_target_property(TOOLCHAINS_TOOL_LLD_LOCATION lld LOCATION)
cmake_path(GET TOOLCHAINS_TOOL_LLD_LOCATION PARENT_PATH TOOLCHAINS_TOOL_LLD_PARENT_LOCATION)

if(CMAKE_HOST_WIN32)
  set(TOOLCHAINS_TOOL_LLD_LOCATION "${TOOLCHAINS_TOOL_LLD_PARENT_LOCATION}/lld-link.exe")
else()
  block()
    if(CMAKE_HOST_APPLE)
      set(tool_lld_program "ld64.lld")
    elseif(CMAKE_HOST_UNIX)
      set(tool_lld_program "ld.lld")
    else()
      set(tool_lld_program "lld")
    endif()
    if(CMAKE_CROSSCOMPILING_EMULATOR)
      set(cmake_crosscompiling_emulator "\"${CMAKE_CROSSCOMPILING_EMULATOR}\"")
    else()
      set(cmake_crosscompiling_emulator "")
    endif()
    file(WRITE "${CMAKE_BINARY_DIR}/qemu_lld.sh"
      "#!/bin/sh\n"
      "${CMAKE_CROSSCOMPILING_EMULATOR} \"${TOOLCHAINS_TOOL_LLD_PARENT_LOCATION}/${tool_lld_program}\" $@\n"
    )
    file(CHMOD
      "${CMAKE_BINARY_DIR}/qemu_lld.sh"
      PERMISSIONS
        OWNER_READ OWNER_WRITE OWNER_EXECUTE
        GROUP_READ GROUP_EXECUTE
        WORLD_READ WORLD_EXECUTE
    )
  endblock()
  set(TOOLCHAINS_TOOL_LLD_LOCATION "${CMAKE_BINARY_DIR}/qemu_lld.sh")
endif()

set(TOOLCHAINS_TOOL_LLD_COMPILE_FLAGS "-Wno-unused-command-line-argument --ld-path=\"${TOOLCHAINS_TOOL_LLD_LOCATION}\"")
set(CMAKE_C_FLAGS ${TOOLCHAINS_TOOL_LLD_COMPILE_FLAGS})
set(CMAKE_CXX_FLAGS ${TOOLCHAINS_TOOL_LLD_COMPILE_FLAGS})

project(toolchains-test-tool_lld
  LANGUAGES C CXX
)

add_executable(exe-tool_lld
  "src/main.cxx"
)
set_target_properties(exe-tool_lld PROPERTIES
  CXX_STANDARD 17
  CXX_EXTENSIONS ON
)

include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported_result OUTPUT ipo_supported_output)
if(ipo_supported_result)
  message(STATUS "IPO is enabled")
  set_property(TARGET exe-tool_lld PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
else()
  message(WARNING "IPO is not supported: ${ipo_supported_output}")
endif()
