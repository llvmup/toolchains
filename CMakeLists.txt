cmake_minimum_required(VERSION 3.27.0 FATAL_ERROR)

if(DEFINED TOOLCHAINS_RELEASE_REV)
  if(NOT "${TOOLCHAINS_RELEASE_REV}" MATCHES "[0-9]+")
    message(FATAL_ERROR
      "  toolchains: expected TOOLCHAINS_RELEASE_REV to be a number:\n"
      "  + TOOLCHAINS_RELEASE_REV: ${TOOLCHAINS_RELEASE_REV}"
    )
  endif()
endif()

include("${CMAKE_SOURCE_DIR}/cmake/modules/Support.cmake")
include(ExternalProject)

# Detect the native and target triples.
toolchains_detect_triples(
  OUTPUT_NATIVE_ARCH toolchains_native_arch
  OUTPUT_NATIVE_VENDOR toolchains_native_vendor
  OUTPUT_NATIVE_SYS toolchains_native_sys
  OUTPUT_NATIVE_SYS_VERSION toolchains_native_sys_version
  OUTPUT_NATIVE_ENV toolchains_native_env
  OUTPUT_NATIVE_ENV_VERSION toolchains_native_env_version
  OUTPUT_NATIVE_TRIPLE toolchains_native_triple
  OUTPUT_NATIVE_TRIPLE_NORMALIZED toolchains_native_triple_normalized
  OUTPUT_NATIVE_TRIPLE_SIMPLIFIED toolchains_native_triple_simplified
  OUTPUT_TARGET_ARCH toolchains_target_arch
  OUTPUT_TARGET_VENDOR toolchains_target_vendor
  OUTPUT_TARGET_SYS toolchains_target_sys
  OUTPUT_TARGET_SYS_VERSION toolchains_target_sys_version
  OUTPUT_TARGET_ENV toolchains_target_env
  OUTPUT_TARGET_ENV_VERSION toolchains_target_env_version
  OUTPUT_TARGET_TRIPLE toolchains_target_triple
  OUTPUT_TARGET_TRIPLE_NORMALIZED toolchains_target_triple_normalized
  OUTPUT_TARGET_TRIPLE_SIMPLIFIED toolchains_target_triple_simplified
  OUTPUT_CMAKE_SYSTEM_NAME CMAKE_SYSTEM_NAME
  OUTPUT_CMAKE_SYSTEM_PROCESSOR CMAKE_SYSTEM_PROCESSOR
  OUTPUT_CMAKE_ASM_COMPILER_TARGET CMAKE_ASM_COMPILER_TARGET
  OUTPUT_CMAKE_C_COMPILER_TARGET CMAKE_C_COMPILER_TARGET
  OUTPUT_CMAKE_CXX_COMPILER_TARGET CMAKE_CXX_COMPILER_TARGET
)

# Configure variables for various parts of the host toolchain.
toolchains_configure_host_tools(
  INPUT_NATIVE_ARCH "${toolchains_native_arch}"
  INPUT_NATIVE_VENDOR "${toolchains_native_vendor}"
  INPUT_NATIVE_SYS "${toolchains_native_sys}"
  INPUT_NATIVE_ENV "${toolchains_native_env}"
  INPUT_TARGET_ARCH "${toolchains_target_arch}"
  INPUT_TARGET_VENDOR "${toolchains_target_vendor}"
  INPUT_TARGET_SYS "${toolchains_target_sys}"
  INPUT_TARGET_ENV "${toolchains_target_env}"
  OUTPUT_ASM_COMPILER CMAKE_ASM_COMPILER
  OUTPUT_ASM_FLAGS CMAKE_ASM_FLAGS
  OUTPUT_C_COMPILER CMAKE_C_COMPILER
  OUTPUT_C_COMPILER_LAUNCHER CMAKE_C_COMPILER_LAUNCHER
  OUTPUT_C_FLAGS CMAKE_C_FLAGS
  OUTPUT_CXX_COMPILER CMAKE_CXX_COMPILER
  OUTPUT_CXX_COMPILER_LAUNCHER CMAKE_CXX_COMPILER_LAUNCHER
  OUTPUT_CXX_FLAGS CMAKE_CXX_FLAGS
  OUTPUT_LIBTOOL CMAKE_LIBTOOL
  OUTPUT_LINKER CMAKE_LINKER
  OUTPUT_LIPO CMAKE_LIPO
  OUTPUT_CMAKE_VCVARS_NATIVE toolchains_cmake_vcvars_native
  OUTPUT_CMAKE_VCVARS_TARGET toolchains_cmake_vcvars_target
  OUTPUT_CTEST_VCVARS_TARGET toolchains_ctest_vcvars_target
  OUTPUT_NATIVE_CAN_EXECUTE_TARGET toolchains_native_can_execute_target
  OUTPUT_CMAKE_CROSSCOMPILING_EMULATOR CMAKE_CROSSCOMPILING_EMULATOR
  OUTPUT_CROSS_COMPILATION_SYSTEM_FLAGS toolchains_cross_compilation_system_flags
  OUTPUT_CROSS_COMPILATION_COMPILER_TARGET_FLAGS toolchains_cross_compilation_compiler_target_flags
  OUTPUT_EXTERNAL_PROJECTS_CMAKE_ARGS toolchains_cmake_args
)

# Detect the individual toolchain state directories.
toolchains_detect_llvmup_dirs(
  OUTPUT_DOWNLOADS_DIR llvmup_toolchains_downloads_dir
  OUTPUT_TREES_DIR llvmup_toolchains_trees_dir
)

project(toolchains
  LANGUAGES NONE
)

# NOTE: This must be placed after `project` in order for host system name to be defined.
if(DEFINED CMAKE_SYSTEM_NAME)
  if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "${CMAKE_HOST_SYSTEM_NAME}")
    message(FATAL_ERROR
      "  toolchains: expected CMAKE_SYSTEM_NAME and CMAKE_HOST_SYSTEM_NAME to be equal:\n"
      "  + CMAKE_SYSTEM_NAME     : ${CMAKE_SYSTEM_NAME}\n"
      "  + CMAKE_HOST_SYSTEM_NAME: ${CMAKE_HOST_SYSTEM_NAME}"
    )
  endif()
endif()

include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases.cmake")
