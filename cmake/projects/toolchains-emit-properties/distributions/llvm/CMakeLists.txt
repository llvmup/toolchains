cmake_minimum_required(VERSION 3.27.0 FATAL_ERROR)

set(CMAKE_SKIP_INSTALL_RULES ON)

if(NOT TOOLCHAINS_ENABLE_LLVM)
  return()
endif()

project(toolchains-emit-properties-llvm
  LANGUAGES NONE
)

toolchains_unset_distribution_find_package_cache_variables()

find_package(LLVM ${TOOLCHAINS_FIND_PACKAGE_LLVM_VERSION_ARGS} REQUIRED CONFIG
  HINTS "${TOOLCHAINS_LLVM_DISTRIBUTION_PATH}/lib/cmake"
  NO_DEFAULT_PATH
)

toolchains_emit_distribution_llvmup_json(
  INPUT_DISTRIBUTION_NAME "llvm"
  INPUT_DISTRIBUTION_PATH "${TOOLCHAINS_LLVM_DISTRIBUTION_PATH}"
)

set(TOOLCHAINS_LLVM_DISTRIBUTION_TARGETS ${TOOLCHAINS_LLVM_DISTRIBUTION_TARGETS} PARENT_SCOPE)
