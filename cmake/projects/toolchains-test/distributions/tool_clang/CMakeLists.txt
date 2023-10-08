cmake_minimum_required(VERSION 3.27.0 FATAL_ERROR)

list(APPEND toolchains_defined_variables
  CMAKE_CROSSCOMPILING_EMULATOR
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
  if("${archive}" MATCHES "^(llvm|tool_clang)-")
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
find_package(Clang ${TOOLCHAINS_FIND_PACKAGE_LLVM_VERSION_ARGS} REQUIRED CONFIG
  HINTS "${TOOLCHAINS_CMAKE_CONFIG_DIR}"
  NO_DEFAULT_PATH
)

get_target_property(TOOLCHAINS_TOOL_CLANG_LOCATION clang LOCATION)
cmake_path(GET TOOLCHAINS_TOOL_CLANG_LOCATION PARENT_PATH TOOLCHAINS_TOOL_CLANG_PARENT_LOCATION)

if(CMAKE_HOST_WIN32)
  set(CMAKE_C_COMPILER "${TOOLCHAINS_TOOL_CLANG_PARENT_LOCATION}/clang-cl.exe")
  set(CMAKE_CXX_COMPILER "${TOOLCHAINS_TOOL_CLANG_PARENT_LOCATION}/clang-cl.exe")
else()
  block()
    if(CMAKE_CROSSCOMPILING_EMULATOR)
      set(cmake_crosscompiling_emulator "\"${CMAKE_CROSSCOMPILING_EMULATOR}\"")
    else()
      set(cmake_crosscompiling_emulator "")
    endif()
    file(WRITE "${CMAKE_BINARY_DIR}/qemu_clang.sh"
      "#!/bin/sh\n"
      "${cmake_crosscompiling_emulator} \"${TOOLCHAINS_TOOL_CLANG_PARENT_LOCATION}/clang\" $@\n"
    )
    file(WRITE "${CMAKE_BINARY_DIR}/qemu_clang++.sh"
      "#!/bin/sh\n"
      "${cmake_crosscompiling_emulator} \"${TOOLCHAINS_TOOL_CLANG_PARENT_LOCATION}/clang++\" $@\n"
    )
    file(CHMOD
      "${CMAKE_BINARY_DIR}/qemu_clang.sh"
      "${CMAKE_BINARY_DIR}/qemu_clang++.sh"
      PERMISSIONS
        OWNER_READ OWNER_WRITE OWNER_EXECUTE
        GROUP_READ GROUP_EXECUTE
        WORLD_READ WORLD_EXECUTE
    )
  endblock()
  set(CMAKE_C_COMPILER "${CMAKE_BINARY_DIR}/qemu_clang.sh")
  set(CMAKE_CXX_COMPILER "${CMAKE_BINARY_DIR}/qemu_clang++.sh")
endif()

project(toolchains-test-tool_clang
  LANGUAGES C CXX
)

add_executable(exe-tool_clang
  "src/main.cxx"
)
set_target_properties(exe-tool_clang PROPERTIES
  CXX_STANDARD 17
  CXX_EXTENSIONS ON
)

# NOTE: On macOS, the test for IPO will fail because CMake will fail to set the following variables:
#
#   - CMAKE_CXX_COMPILER_AR
#   - CMAKE_CXX_COMPILER_RANLIB
#
# However, these are not actually needed to compile with LTO. So for macOS, we just bypass the
# normal CMake check and set the appropriate flag explicitly below.
if(NOT CMAKE_HOST_APPLE)
  include(CheckIPOSupported)
  check_ipo_supported(RESULT ipo_supported_result OUTPUT ipo_supported_output)
  if(ipo_supported_result)
    message(STATUS "IPO is enabled")
    set_property(TARGET exe-tool_clang PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
  else()
    message(WARNING "IPO is not supported: ${ipo_supported_output}")
  endif()
else()
  target_compile_options(exe-tool_clang PRIVATE
    -flto=thin
  )
  target_link_options(exe-tool_clang PRIVATE
    -flto=thin
    "LINKER:-platform_version,macos,${CMAKE_OSX_DEPLOYMENT_TARGET},0.0.0"
  )
endif()
