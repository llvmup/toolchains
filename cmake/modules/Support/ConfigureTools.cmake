include_guard(GLOBAL)

include("${CMAKE_SOURCE_DIR}/cmake/modules/Support/ArgumentParsing.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Support/ConfigureVariables.cmake")

function(toolchains_configure_vcvars_launchers)
  set(args_one_value_keywords
    "INPUT_NATIVE_ARCH"
    "INPUT_TARGET_ARCH"
    "OUTPUT_CMAKE_VCVARS_NATIVE"
    # "OUTPUT_CTEST_VCVARS_NATIVE"
    "OUTPUT_CMAKE_VCVARS_TARGET"
    "OUTPUT_CTEST_VCVARS_TARGET"
  )
  cmake_parse_and_validate_arguments(
    # prefix
    "ARG"
    # options
    ""
    # one_value_keywords
    "${args_one_value_keywords}"
    # multi_value_keywords
    ""
    # pass through arguments
    "${ARGN}"
  )
  if(NOT CMAKE_HOST_WIN32)
    message(WARNING "toolchains: `toolchains_configure_vcvars_launchers` is only supported on Windows")
    return()
  endif()

  cmake_host_system_information(
    RESULT visual_studio_dir
    QUERY "VS_${TOOLCHAINS_VISUAL_STUDIO_VERSION}_DIR"
  )

  set(vcvarsall_bat "${visual_studio_dir}/VC/Auxiliary/Build/vcvarsall.bat")

  if(NOT EXISTS "${vcvarsall_bat}")
    message(FATAL_ERROR
      "toolchains: Failed to locate the Visual Studio `vcvarsall.bat`\n"
      "  Expected location: \"${vcvarsall_bat}\""
    )
  endif()

  set(vcvars_native_arch "${ARG_INPUT_NATIVE_ARCH}")
  string(REPLACE "aarch64" "arm64" vcvars_native_arch "${vcvars_native_arch}")
  string(REPLACE "x86_64" "amd64" vcvars_native_arch "${vcvars_native_arch}")
  file(WRITE "${CMAKE_BINARY_DIR}/cmake-vcvars-native.cmd" "@echo off\ncall \"${vcvarsall_bat}\" ${vcvars_native_arch}\n\"${CMAKE_COMMAND}\" %*")
  file(WRITE "${CMAKE_BINARY_DIR}/ctest-vcvars-native.cmd" "@echo off\ncall \"${vcvarsall_bat}\" ${vcvars_native_arch}\n\"${CMAKE_CTEST_COMMAND}\" %*")
  set(${ARG_OUTPUT_CMAKE_VCVARS_NATIVE} "${CMAKE_BINARY_DIR}/cmake-vcvars-native.cmd" PARENT_SCOPE)
  # set(${ARG_OUTPUT_CTEST_VCVARS_NATIVE} "${CMAKE_BINARY_DIR}/ctest-vcvars-native.cmd" PARENT_SCOPE)

  set(vcvars_target_arch "${ARG_INPUT_TARGET_ARCH}")
  string(REPLACE "aarch64" "arm64" vcvars_target_arch "${vcvars_target_arch}")
  string(REPLACE "x86_64" "amd64" vcvars_target_arch "${vcvars_target_arch}")
  if(NOT "${ARG_INPUT_TARGET_ARCH}" STREQUAL "${ARG_INPUT_NATIVE_ARCH}")
    string(PREPEND vcvars_target_arch "${vcvars_native_arch}_")
  endif()
  file(WRITE "${CMAKE_BINARY_DIR}/cmake-vcvars-target.cmd" "@echo off\ncall \"${vcvarsall_bat}\" ${vcvars_target_arch}\n\"${CMAKE_COMMAND}\" %*")
  file(WRITE "${CMAKE_BINARY_DIR}/ctest-vcvars-target.cmd" "@echo off\ncall \"${vcvarsall_bat}\" ${vcvars_target_arch}\n\"${CMAKE_CTEST_COMMAND}\" %*")
  set(${ARG_OUTPUT_CMAKE_VCVARS_TARGET} "${CMAKE_BINARY_DIR}/cmake-vcvars-target.cmd" PARENT_SCOPE)
  set(${ARG_OUTPUT_CTEST_VCVARS_TARGET} "${CMAKE_BINARY_DIR}/ctest-vcvars-target.cmd" PARENT_SCOPE)

  message(NOTICE
    "toolchains: Configuring toolchains: detecting MSVC\n"
    "  + vcvars: \"${vcvarsall_bat}\"\n"
    "  + native: ${vcvars_native_arch}\n"
    "  + target: ${vcvars_target_arch}"
  )
endfunction()

function(toolchains_configure_host_tools)
  set(args_one_value_keywords
    "INPUT_NATIVE_ARCH"
    "INPUT_NATIVE_VENDOR"
    "INPUT_NATIVE_SYS"
    "INPUT_NATIVE_ENV"
    "INPUT_TARGET_ARCH"
    "INPUT_TARGET_VENDOR"
    "INPUT_TARGET_SYS"
    "INPUT_TARGET_ENV"
    "OUTPUT_LIBTOOL"
    "OUTPUT_LINKER"
    "OUTPUT_LIPO"
    "OUTPUT_ASM_COMPILER"
    "OUTPUT_ASM_FLAGS"
    "OUTPUT_C_COMPILER"
    "OUTPUT_C_COMPILER_LAUNCHER"
    "OUTPUT_C_FLAGS"
    "OUTPUT_CXX_COMPILER"
    "OUTPUT_CXX_COMPILER_LAUNCHER"
    "OUTPUT_CXX_FLAGS"
    "OUTPUT_CMAKE_VCVARS_NATIVE"
    "OUTPUT_CMAKE_VCVARS_TARGET"
    "OUTPUT_CTEST_VCVARS_TARGET"
    "OUTPUT_NATIVE_CAN_EXECUTE_TARGET"
    "OUTPUT_CMAKE_CROSSCOMPILING_EMULATOR"
    "OUTPUT_CROSS_COMPILATION_SYSTEM_FLAGS"
    "OUTPUT_CROSS_COMPILATION_COMPILER_TARGET_FLAGS"
    "OUTPUT_EXTERNAL_PROJECTS_CMAKE_ARGS"
  )
  cmake_parse_and_validate_arguments(
    # prefix
    "ARG"
    # options
    ""
    # one_value_keywords
    "${args_one_value_keywords}"
    # multi_value_keywords
    ""
    # pass through arguments
    "${ARGN}"
  )

  message(NOTICE "toolchains: Configuring toolchains: detecting clang")

  set(clang_names clang-17 clang-16 clang)
  set(clang_hints "")
  set(clang++_names clang++-17 clang++-16 clang++)
  set(clang++_hints "")
  set(ld_names ld.lld-17 ld.lld-16 ld.lld)
  set(ld_hints "")

  if(CMAKE_HOST_APPLE)
    # NOTE: We don't currently allow macOS `ld` since it is not compatible with the latest LLVM IR bitcode.
    list(PREPEND ld_names ld64.lld)
  endif()

  if(CMAKE_HOST_LINUX)
    list(PREPEND ld_names mold)
  endif()

  if(CMAKE_HOST_WIN32)
    set(clang_names clang-cl-17 clang-cl)
    set(clang++_names clang-cl-17 clang-cl)
    set(ld_names lld-link-17 lld-link)
  endif()

  if(TOOLCHAINS_HOMEBREW_HOST_LLVM_PREFIX)
    list(PREPEND clang_hints "${TOOLCHAINS_HOMEBREW_HOST_LLVM_PREFIX}/bin")
    list(PREPEND clang++_hints "${TOOLCHAINS_HOMEBREW_HOST_LLVM_PREFIX}/bin")
    list(PREPEND ld_hints "${TOOLCHAINS_HOMEBREW_HOST_LLVM_PREFIX}/bin")
    # NOTE: Homebrew does not consistently suffix the binaries with the version numbers so we need
    # to search for the non-suffixed names first.
    list(PREPEND clang_names clang)
    list(PREPEND clang++_names clang++)
    if(NOT CMAKE_HOST_APPLE)
      list(PREPEND ld_names mold ld.lld)
    endif()
  endif()

  if(TOOLCHAINS_SCOOP_HOST_LLVM_PREFIX)
    list(PREPEND clang_hints "${TOOLCHAINS_SCOOP_HOST_LLVM_PREFIX}/bin")
    list(PREPEND clang++_hints "${TOOLCHAINS_SCOOP_HOST_LLVM_PREFIX}/bin")
    list(PREPEND ld_hints "${TOOLCHAINS_SCOOP_HOST_LLVM_PREFIX}/bin")
  endif()

  find_program(clang_program REQUIRED
    NAMES ${clang_names}
    HINTS ${clang_hints}
  )
  find_program(clang++_program REQUIRED
    NAMES ${clang++_names}
    HINTS ${clang++_hints}
  )
  find_program(ld_program REQUIRED
    NAMES ${ld_names}
    HINTS ${ld_hints}
  )

  set(toolchains_linker "${ld_program}")
  set(toolchains_c_compiler "${clang_program}")
  set(toolchains_c_flags "-fuse-ld='${ld_program}'")
  set(toolchains_cxx_compiler "${clang++_program}")
  set(toolchains_cxx_flags "-fuse-ld='${ld_program}'")

  if(CMAKE_HOST_APPLE)
    cmake_path(GET toolchains_cxx_compiler PARENT_PATH llvm_native_tool_dir)
    set(${ARG_OUTPUT_LIBTOOL} "${llvm_native_tool_dir}/llvm-libtool-darwin" PARENT_SCOPE)
    set(${ARG_OUTPUT_LIPO} "${llvm_native_tool_dir}/llvm-lipo" PARENT_SCOPE)
  endif()

  set(${ARG_OUTPUT_ASM_COMPILER} "${toolchains_c_compiler}" PARENT_SCOPE)
  set(${ARG_OUTPUT_ASM_FLAGS} "${toolchains_c_flags}" PARENT_SCOPE)
  set(${ARG_OUTPUT_C_COMPILER} "${toolchains_c_compiler}" PARENT_SCOPE)
  set(${ARG_OUTPUT_C_FLAGS} "${toolchains_c_flags}" PARENT_SCOPE)
  set(${ARG_OUTPUT_CXX_COMPILER} "${toolchains_cxx_compiler}" PARENT_SCOPE)
  set(${ARG_OUTPUT_CXX_FLAGS} "${toolchains_cxx_flags}" PARENT_SCOPE)
  set(${ARG_OUTPUT_LINKER} "${toolchains_linker}" PARENT_SCOPE)

  find_program(ccache_program
    NAMES ccache
  )

  if(ccache_program)
    set(${ARG_OUTPUT_C_COMPILER_LAUNCHER} "${ccache_program}" PARENT_SCOPE)
    set(${ARG_OUTPUT_CXX_COMPILER_LAUNCHER} "${ccache_program}" PARENT_SCOPE)
    list(APPEND ${ARG_OUTPUT_EXTERNAL_PROJECTS_CMAKE_ARGS}
      "-DCMAKE_C_COMPILER_LAUNCHER=${ccache_program}"
      "-DCMAKE_CXX_COMPILER_LAUNCHER=${ccache_program}"
    )
  endif()

  list(APPEND ${ARG_OUTPUT_EXTERNAL_PROJECTS_CMAKE_ARGS}
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_ASM_COMPILER=${toolchains_c_compiler}"
    "-DCMAKE_ASM_FLAGS=${toolchains_c_flags}"
    "-DCMAKE_C_COMPILER=${toolchains_c_compiler}"
    "-DCMAKE_C_FLAGS=${toolchains_c_flags}"
    "-DCMAKE_CXX_COMPILER=${toolchains_cxx_compiler}"
    "-DCMAKE_CXX_FLAGS=${toolchains_cxx_flags}"
    "-DCMAKE_LINKER=${toolchains_linker}"
  )
  if(CMAKE_HOST_APPLE)
    list(APPEND ${ARG_OUTPUT_EXTERNAL_PROJECTS_CMAKE_ARGS}
      "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
    )
  endif()
  set(${ARG_OUTPUT_EXTERNAL_PROJECTS_CMAKE_ARGS} "${${ARG_OUTPUT_EXTERNAL_PROJECTS_CMAKE_ARGS}}" PARENT_SCOPE)

  set(cmake_crosscompiling_emulator "")
  if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
    set(native_can_execute_target NO)
    if("${ARG_INPUT_NATIVE_ARCH}" STREQUAL "x86_64")
      if("${ARG_INPUT_TARGET_ARCH}" STREQUAL "i686")
        set(native_can_execute_target YES)
      endif()
    endif()
    if(NOT native_can_execute_target AND CMAKE_HOST_LINUX)
      set(qemu_target_arch "${ARG_INPUT_TARGET_ARCH}")
      string(REPLACE "armv7" "arm" qemu_target_arch "${qemu_target_arch}")
      string(REPLACE "powerpc64le" "ppc64le" qemu_target_arch "${qemu_target_arch}")
      find_program(qemu
        NAMES "qemu-${qemu_target_arch}-static" "qemu-${qemu_target_arch}"
      )
      # NOTE: disable for s390x for now; see: https://gitlab.com/qemu-project/qemu/-/issues/1668
      if(qemu AND NOT "${ARG_INPUT_TARGET_ARCH}" STREQUAL "s390x")
        set(cmake_crosscompiling_emulator "${qemu}")
      endif()
    endif()
    if(CMAKE_HOST_APPLE)
      if("${ARG_INPUT_NATIVE_ARCH}" STREQUAL "arm64")
        if("${ARG_INPUT_TARGET_ARCH}" STREQUAL "x86_64")
          set(native_can_execute_target YES)
        endif()
      endif()
    endif()
    if(CMAKE_HOST_WIN32)
      if("${ARG_INPUT_NATIVE_ARCH}" STREQUAL "aarch64")
        if("${ARG_INPUT_TARGET_ARCH}" STREQUAL "x86_64")
          set(native_can_execute_target YES)
        endif()
      endif()
    endif()
    list(APPEND cross_compilation_system_flags
      "-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}"
      "-DCMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}"
    )
    if(CMAKE_HOST_APPLE)
      string(REPLACE "aarch64" "arm64" toolchains_target_arch_apple "${ARG_INPUT_TARGET_ARCH}")
      list(APPEND cross_compilation_system_flags
        "-DCMAKE_APPLE_SILICON_PROCESSOR=${toolchains_target_arch_apple}"
        "-DCMAKE_OSX_ARCHITECTURES=${toolchains_target_arch_apple}"
      )
    endif()
    list(APPEND cross_compilation_compiler_target_flags
      "-DCMAKE_ASM_COMPILER_TARGET=${CMAKE_ASM_COMPILER_TARGET}"
      "-DCMAKE_C_COMPILER_TARGET=${CMAKE_C_COMPILER_TARGET}"
      "-DCMAKE_CXX_COMPILER_TARGET=${CMAKE_CXX_COMPILER_TARGET}"
    )
    set(${ARG_OUTPUT_CMAKE_CROSSCOMPILING_EMULATOR} "${cmake_crosscompiling_emulator}" PARENT_SCOPE)
    set(${ARG_OUTPUT_CROSS_COMPILATION_SYSTEM_FLAGS} "${cross_compilation_system_flags}" PARENT_SCOPE)
    set(${ARG_OUTPUT_CROSS_COMPILATION_COMPILER_TARGET_FLAGS} "${cross_compilation_compiler_target_flags}" PARENT_SCOPE)
  else()
    set(native_can_execute_target YES)
    set(${ARG_OUTPUT_CROSS_COMPILATION_SYSTEM_FLAGS} "" PARENT_SCOPE)
    set(${ARG_OUTPUT_CROSS_COMPILATION_COMPILER_TARGET_FLAGS} "" PARENT_SCOPE)
  endif()

  set(${ARG_OUTPUT_NATIVE_CAN_EXECUTE_TARGET} "${native_can_execute_target}" PARENT_SCOPE)

  if(CMAKE_HOST_WIN32)
    toolchains_configure_vcvars_launchers(
      INPUT_NATIVE_ARCH "${ARG_INPUT_NATIVE_ARCH}"
      INPUT_TARGET_ARCH "${ARG_INPUT_TARGET_ARCH}"
      OUTPUT_CMAKE_VCVARS_NATIVE cmake_vcvars_native
      OUTPUT_CMAKE_VCVARS_TARGET cmake_vcvars_target
      OUTPUT_CTEST_VCVARS_TARGET ctest_vcvars_target
    )
    set(${ARG_OUTPUT_CMAKE_VCVARS_NATIVE} "${cmake_vcvars_native}" PARENT_SCOPE)
    set(${ARG_OUTPUT_CMAKE_VCVARS_TARGET} "${cmake_vcvars_target}" PARENT_SCOPE)
    set(${ARG_OUTPUT_CTEST_VCVARS_TARGET} "${ctest_vcvars_target}" PARENT_SCOPE)
  endif()

  if(cmake_crosscompiling_emulator)
    set(cmake_crosscompiling_emulator_or_none "${cmake_crosscompiling_emulator}")
  else()
    set(cmake_crosscompiling_emulator_or_none "<none>")
  endif()

  message(NOTICE
    "  + clang   : ${toolchains_c_compiler}\n"
    "  + clang++ : ${toolchains_cxx_compiler}\n"
    "  + linker  : ${toolchains_linker}\n"
    "  + emulator: ${cmake_crosscompiling_emulator_or_none}"
  )
endfunction()

function(toolchains_configure_host_tools_flags)
  message(NOTICE "toolchains: Configuring host tool flags")

  if(NOT DEFINED CMAKE_C_RELEASE_FLAGS)
    message(FATAL_ERROR "toolchains: `CMAKE_C_RELEASE_FLAGS` must be defined before calling `toolchains_configure_host_tools_flags`")
  endif()
  if(NOT DEFINED CMAKE_C_DEBUG_FLAGS)
    message(FATAL_ERROR "toolchains: `CMAKE_C_DEBUG_FLAGS` must be defined before calling `toolchains_configure_host_tools_flags`")
  endif()
  if(NOT DEFINED CMAKE_CXX_RELEASE_FLAGS)
    message(FATAL_ERROR "toolchains: `CMAKE_CXX_RELEASE_FLAGS` must be defined before calling `toolchains_configure_host_tools_flags`")
  endif()
  if(NOT DEFINED CMAKE_CXX_DEBUG_FLAGS)
    message(FATAL_ERROR "toolchains: `CMAKE_CXX_DEBUG_FLAGS` must be defined before calling `toolchains_configure_host_tools_flags`")
  endif()

  if(CMAKE_HOST_APPLE)
    if(TOOLCHAINS_ENABLE_SWIFT)
      if(NOT DEFINED SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX)
        message(FATAL_ERROR "toolchains: SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX must be defined")
      endif()
    endif()

    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_RELEASE_FLAGS} -mmacos-version-min=${SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX}"
      CACHE INTERNAL
    )
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_DEBUG_FLAGS} -mmacos-version-min=${SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX}"
      CACHE INTERNAL
    )
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_RELEASE_FLAGS} -mmacos-version-min=${SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX}"
      CACHE INTERNAL
    )
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_DEBUG_FLAGS} -mmacos-version-min=${SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX}"
      CACHE INTERNAL
    )
  endif()
endfunction()
