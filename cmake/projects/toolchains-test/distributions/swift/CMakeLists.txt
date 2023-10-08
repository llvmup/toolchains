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
  if("${archive}" MATCHES "^(clang|llvm|swift)-")
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
find_package(Swift ${TOOLCHAINS_FIND_PACKAGE_LLVM_VERSION_ARGS} REQUIRED CONFIG
  HINTS "${TOOLCHAINS_CMAKE_CONFIG_DIR}"
  NO_DEFAULT_PATH
)

project(toolchains-test-swift
  LANGUAGES C CXX
)

add_executable(exe-swift
  "src/main.cxx"
)
set_target_properties(exe-swift PROPERTIES
  CXX_STANDARD 17
  CXX_EXTENSIONS ON
)
target_link_libraries(exe-swift PRIVATE
  swiftFrontend
)
if(NOT CMAKE_HOST_WIN32)
  target_compile_options(exe-swift PRIVATE
    -fno-rtti
  )
endif()

include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported_result OUTPUT ipo_supported_output)
if(ipo_supported_result)
  message(STATUS "IPO is enabled")
  set_property(TARGET exe-swift PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
else()
  message(WARNING "IPO is not supported: ${ipo_supported_output}")
endif()
