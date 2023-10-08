include_guard(GLOBAL)

include("${CMAKE_SOURCE_DIR}/cmake/modules/Support/ArgumentParsing.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Support/ConfigureVariables.cmake")

function(toolchains_ensure_arch_consistency)
  set(message_details
    "  + `TOOLCHAINS_TARGET_ARCH` should be defined instead\n"
    "  + NOTE: cross-OS cross-compilation is not supported"
  )
  if(DEFINED CMAKE_C_COMPILER_TARGET OR DEFINED CMAKE_CXX_COMPILER_TARGET)
    message(FATAL_ERROR
      "  toolchains: `CMAKE_{C,CXX}_COMPILER_TARGET` is not supported\n"
      ${message_details}
    )
  endif()
  if(DEFINED CMAKE_SYSTEM_NAME)
    message(FATAL_ERROR
      "  toolchains: `CMAKE_SYSTEM_NAME` is not supported\n"
      ${message_details}
    )
  endif()
endfunction()

function(toolchains_normalize_triple)
  set(args_one_value_keywords
    "INPUT_ARCH"
    "INPUT_VENDOR"
    "INPUT_SYS"
    "INPUT_SYS_VERSION"
    "INPUT_ENV"
    "INPUT_ENV_VERSION"
    "OUTPUT_ARCH"
    "OUTPUT_VENDOR"
    "OUTPUT_SYS"
    "OUTPUT_SYS_VERSION"
    "OUTPUT_ENV"
    "OUTPUT_ENV_VERSION"
    "OUTPUT_NORMALIZED_TRIPLE"
    "OUTPUT_SIMPLIFIED_TRIPLE"
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

  set(normalized_arch "${ARG_INPUT_ARCH}")
  set(normalized_vendor "${ARG_INPUT_VENDOR}")
  set(normalized_sys "${ARG_INPUT_SYS}")
  set(normalized_sys_version "${ARG_INPUT_SYS_VERSION}")
  set(normalized_env "${ARG_INPUT_ENV}")
  set(normalized_env_version "${ARG_INPUT_ENV_VERSION}")

  if(normalized_sys MATCHES "^(darwin|macosx)$")
    string(REPLACE "aarch64" "arm64" normalized_arch "${normalized_arch}")
    set(normalized_sys "macos")
    set(normalized_sys_version "${CMAKE_OSX_DEPLOYMENT_TARGET}")
  endif()

  set(normalized_triple "")
  set(simplified_triple "")

  string(APPEND normalized_triple "${normalized_arch}")
  string(APPEND simplified_triple "${normalized_arch}")

  if(normalized_vendor)
    string(APPEND normalized_triple "-${normalized_vendor}")
  endif()

  string(APPEND normalized_triple "-${normalized_sys}")
  string(APPEND simplified_triple "-${normalized_sys}")

  if(normalized_sys_version)
    string(APPEND normalized_triple "${normalized_sys_version}")
  endif()

  if(normalized_env)
    string(APPEND normalized_triple "-${normalized_env}")
    if(NOT CMAKE_HOST_APPLE)
      string(APPEND simplified_triple "-${normalized_env}")
    endif()
  endif()

  if(normalized_env_version)
    string(APPEND normalized_triple "${normalized_env_version}")
  endif()

  set(${ARG_OUTPUT_ARCH} "${normalized_arch}" PARENT_SCOPE)
  set(${ARG_OUTPUT_VENDOR} "${normalized_vendor}" PARENT_SCOPE)
  set(${ARG_OUTPUT_SYS} "${normalized_sys}" PARENT_SCOPE)
  set(${ARG_OUTPUT_SYS_VERSION} "${normalized_sys_version}" PARENT_SCOPE)
  set(${ARG_OUTPUT_ENV} "${normalized_env}" PARENT_SCOPE)
  set(${ARG_OUTPUT_ENV_VERSION} "${normalized_env_version}" PARENT_SCOPE)
  set(${ARG_OUTPUT_NORMALIZED_TRIPLE} "${normalized_triple}" PARENT_SCOPE)
  set(${ARG_OUTPUT_SIMPLIFIED_TRIPLE} "${simplified_triple}" PARENT_SCOPE)
endfunction()

function(toolchains_parse_triple)
  set(args_one_value_keywords
    "INPUT_TRIPLE"
    "OUTPUT_ARCH"
    "OUTPUT_VENDOR"
    "OUTPUT_SYS"
    "OUTPUT_SYS_VERSION"
    "OUTPUT_ENV"
    "OUTPUT_ENV_VERSION"
    "OUTPUT_NORMALIZED_TRIPLE"
    "OUTPUT_SIMPLIFIED_TRIPLE"
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

  string(REPLACE "-" ";" triple_components "${ARG_INPUT_TRIPLE}")
  if(NOT DEFINED triple_components OR "${triple_components}" STREQUAL "")
    message(FATAL_ERROR "toolchains: Failed to parse triple: ${triple_components}")
  endif()

  list(LENGTH triple_components triple_components_length)

  if(${triple_components_length} LESS 2)
    message(FATAL_ERROR "toolchains: Failed to parse triple: ${triple_components}")
  endif()

  list(GET triple_components 0 triple_arch)

  list(GET triple_components 1 triple_2nd_component)

  if("${triple_2nd_component}" MATCHES "apple|pc|unknown")
    set(triple_vendor "${triple_2nd_component}")
  else()
    set(triple_vendor "NOTFOUND")
    set(triple_sys "${triple_2nd_component}")
  endif()

  if(${triple_components_length} GREATER_EQUAL 3)
    # NOTE: we don't use `if(DEFINED triple_vendor)` because it would return true for `NOTFOUND`
    if(triple_vendor)
      list(GET triple_components 2 triple_sys)
    else()
      list(GET triple_components 2 triple_env)
    endif()
  endif()

  if(${triple_components_length} GREATER_EQUAL 4)
    list(GET triple_components 3 triple_env)
  endif()

  set(triple_sys_version "NOTFOUND")
  if(DEFINED triple_sys)
    if("${triple_sys}" MATCHES "^([a-zA-Z]+)([0-9]+(.[0-9]+)*)?$")
      set(triple_sys "${CMAKE_MATCH_1}")
      if(DEFINED CMAKE_MATCH_2)
        set(triple_sys_version "${CMAKE_MATCH_2}")
      endif()
    endif()
  else()
    set(triple_sys "NOTFOUND")
  endif()

  set(triple_env_version "NOTFOUND")
  if(DEFINED triple_env)
    if("${triple_env}" MATCHES "^([a-zA-Z]+)\.?([0-9]+(.[0-9]+)*)?$")
      set(triple_env "${CMAKE_MATCH_1}")
      if(DEFINED CMAKE_MATCH_2)
        set(triple_env_version "${CMAKE_MATCH_2}")
      endif()
    endif()
  else()
    set(triple_env "NOTFOUND")
  endif()

  toolchains_normalize_triple(
    INPUT_ARCH "${triple_arch}"
    INPUT_VENDOR "${triple_vendor}"
    INPUT_SYS "${triple_sys}"
    INPUT_SYS_VERSION "${triple_sys_version}"
    INPUT_ENV "${triple_env}"
    INPUT_ENV_VERSION "${triple_env_version}"
    OUTPUT_ARCH triple_arch
    OUTPUT_VENDOR triple_vendor
    OUTPUT_SYS triple_sys
    OUTPUT_SYS_VERSION triple_sys_version
    OUTPUT_ENV triple_env
    OUTPUT_ENV_VERSION triple_env_version
    OUTPUT_NORMALIZED_TRIPLE normalized_triple
    OUTPUT_SIMPLIFIED_TRIPLE simplified_triple
  )

  set("${ARG_OUTPUT_ARCH}" "${triple_arch}" PARENT_SCOPE)
  set("${ARG_OUTPUT_VENDOR}" "${triple_vendor}" PARENT_SCOPE)
  set("${ARG_OUTPUT_SYS}" "${triple_sys}" PARENT_SCOPE)
  set("${ARG_OUTPUT_SYS_VERSION}" "${triple_sys_version}" PARENT_SCOPE)
  set("${ARG_OUTPUT_ENV}" "${triple_env}" PARENT_SCOPE)
  set("${ARG_OUTPUT_ENV_VERSION}" "${triple_env_version}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NORMALIZED_TRIPLE}" "${normalized_triple}" PARENT_SCOPE)
  set("${ARG_OUTPUT_SIMPLIFIED_TRIPLE}" "${simplified_triple}" PARENT_SCOPE)
endfunction()

function(toolchains_detect_triples)
  set(args_one_value_keywords
    "OUTPUT_NATIVE_ARCH"
    "OUTPUT_NATIVE_VENDOR"
    "OUTPUT_NATIVE_SYS"
    "OUTPUT_NATIVE_SYS_VERSION"
    "OUTPUT_NATIVE_ENV"
    "OUTPUT_NATIVE_ENV_VERSION"
    "OUTPUT_NATIVE_TRIPLE"
    "OUTPUT_NATIVE_TRIPLE_NORMALIZED"
    "OUTPUT_NATIVE_TRIPLE_SIMPLIFIED"
    "OUTPUT_TARGET_ARCH"
    "OUTPUT_TARGET_VENDOR"
    "OUTPUT_TARGET_SYS"
    "OUTPUT_TARGET_SYS_VERSION"
    "OUTPUT_TARGET_ENV"
    "OUTPUT_TARGET_ENV_VERSION"
    "OUTPUT_TARGET_TRIPLE"
    "OUTPUT_TARGET_TRIPLE_NORMALIZED"
    "OUTPUT_TARGET_TRIPLE_SIMPLIFIED"
    "OUTPUT_CMAKE_SYSTEM_NAME"
    "OUTPUT_CMAKE_SYSTEM_PROCESSOR"
    "OUTPUT_CMAKE_ASM_COMPILER_TARGET"
    "OUTPUT_CMAKE_C_COMPILER_TARGET"
    "OUTPUT_CMAKE_CXX_COMPILER_TARGET"
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

  message(NOTICE "toolchains: Configuring toolchains: detecting triples")

  if(CMAKE_HOST_UNIX)
    find_program(uname REQUIRED
      NAMES uname
    )
    execute_process(COMMAND "${uname}" -s
      RESULT_VARIABLE uname_sys_result
      ERROR_VARIABLE uname_sys_error
      OUTPUT_VARIABLE uname_sys_output
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT ${uname_sys_result} EQUAL 0)
      message(FATAL_ERROR "toolchains: Failed to read `${uname} -s` output: ${uname_sys_error}")
    endif()
    string(TOLOWER "${uname_sys_output}" native_triple_sys)
  endif()

  set(cxx_compiler_names clang++-18 clang++-17 clang++-16 clang++ g++)
  set(cxx_compiler_hints "")

  if(TOOLCHAINS_HOMEBREW_HOST_LLVM_PREFIX)
    list(PREPEND cxx_compiler_names clang++)
    list(PREPEND cxx_compiler_hints "${TOOLCHAINS_HOMEBREW_HOST_LLVM_PREFIX}/bin")
  endif()

  find_program(cxx_compiler REQUIRED
    NAMES ${cxx_compiler_names}
    HINTS ${cxx_compiler_hints}
  )

  execute_process(COMMAND "${cxx_compiler}" -dumpmachine
    RESULT_VARIABLE native_triple_result
    ERROR_VARIABLE native_triple_error
    OUTPUT_VARIABLE native_triple
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(NOT ${native_triple_result} EQUAL 0)
    message(FATAL_ERROR "toolchains: Failed to detect native triple: ${native_triple_error}")
  endif()

  string(REPLACE "-" ";" native_triple_components "${native_triple}")
  if(NOT DEFINED native_triple_components OR "${native_triple_components}" STREQUAL "")
    message(FATAL_ERROR "toolchains: Failed to parse native triple: ${native_triple_components}")
  endif()

  list(GET native_triple_components 0 native_triple_arch)

  if("${native_triple_arch}" MATCHES "^(amd64|x86_64)$")
    set(native_triple_arch "x86_64")
  elseif("${native_triple_arch}" STREQUAL "arm64" AND NOT CMAKE_HOST_APPLE)
    set(native_triple_arch "aarch64")
  endif()

  toolchains_parse_triple(
    INPUT_TRIPLE "${native_triple}"
    OUTPUT_ARCH native_triple_arch
    OUTPUT_VENDOR native_triple_vendor
    OUTPUT_SYS native_triple_sys
    OUTPUT_SYS_VERSION native_triple_sys_version
    OUTPUT_ENV native_triple_env
    OUTPUT_ENV_VERSION native_triple_env_version
    OUTPUT_NORMALIZED_TRIPLE native_triple_normalized
    OUTPUT_SIMPLIFIED_TRIPLE native_triple_simplified
  )

  set("${ARG_OUTPUT_NATIVE_ARCH}" "${native_triple_arch}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NATIVE_VENDOR}" "${native_triple_vendor}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NATIVE_SYS}" "${native_triple_sys}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NATIVE_SYS_VERSION}" "${native_triple_sys_version}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NATIVE_ENV}" "${native_triple_env}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NATIVE_ENV_VERSION}" "${native_triple_env_version}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NATIVE_TRIPLE}" "${native_triple}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NATIVE_TRIPLE_NORMALIZED}" "${native_triple_normalized}" PARENT_SCOPE)
  set("${ARG_OUTPUT_NATIVE_TRIPLE_SIMPLIFIED}" "${native_triple_simplified}" PARENT_SCOPE)

  toolchains_ensure_arch_consistency()

  set(TOOLCHAINS_ENABLE_CROSS_COMPILE OFF CACHE STRING INTERNAL)

  if(NOT "${TOOLCHAINS_TARGET_ARCH}" STREQUAL "native")
    set(toolchains_target_arch "${TOOLCHAINS_TARGET_ARCH}")
    if(CMAKE_HOST_APPLE)
      string(REPLACE "aarch64" "arm64" toolchains_target_arch "${toolchains_target_arch}")
    endif()
    if("${TOOLCHAINS_TARGET_ARCH}" STREQUAL "armv7")
      set(target_triple "armv7-linux-gnueabihf")
    else()
      string(REGEX REPLACE "^[^-]+(.+)$" "${toolchains_target_arch}\\1" target_triple "${native_triple}")
    endif()
    if(NOT "${target_triple}" STREQUAL "${native_triple}")
      set(TOOLCHAINS_ENABLE_CROSS_COMPILE ON CACHE STRING INTERNAL FORCE)
      if(CMAKE_HOST_WIN32)
        set("${ARG_OUTPUT_CMAKE_SYSTEM_NAME}" "Windows" PARENT_SCOPE)
      elseif(CMAKE_HOST_UNIX)
        set("${ARG_OUTPUT_CMAKE_SYSTEM_NAME}" "${uname_sys_output}" PARENT_SCOPE)
      else()
        message(FATAL_ERROR "toolchains: Cannot determine appropriate value for CMAKE_SYSTEM_NAME")
      endif()
      set("${ARG_OUTPUT_CMAKE_ASM_COMPILER_TARGET}" "${target_triple}" PARENT_SCOPE)
      set("${ARG_OUTPUT_CMAKE_C_COMPILER_TARGET}" "${target_triple}" PARENT_SCOPE)
      set("${ARG_OUTPUT_CMAKE_CXX_COMPILER_TARGET}" "${target_triple}" PARENT_SCOPE)
    endif()
  endif()

  if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
    toolchains_parse_triple(
      INPUT_TRIPLE "${target_triple}"
      OUTPUT_ARCH target_triple_arch
      OUTPUT_VENDOR target_triple_vendor
      OUTPUT_SYS target_triple_sys
      OUTPUT_SYS_VERSION target_triple_sys_version
      OUTPUT_ENV target_triple_env
      OUTPUT_ENV_VERSION target_triple_env_version
      OUTPUT_NORMALIZED_TRIPLE target_triple_normalized
      OUTPUT_SIMPLIFIED_TRIPLE target_triple_simplified
    )
    set("${ARG_OUTPUT_CMAKE_SYSTEM_PROCESSOR}" "${target_triple_arch}" PARENT_SCOPE)
  else()
    set(target_triple "${native_triple}")
    set(target_triple_arch "${native_triple_arch}")
    set(target_triple_vendor "${native_triple_vendor}")
    set(target_triple_sys "${native_triple_sys}")
    set(target_triple_sys_version "${native_triple_sys_version}")
    set(target_triple_env "${native_triple_env}")
    set(target_triple_env_version "${native_triple_env_version}")
    set(target_triple_normalized "${native_triple_normalized}")
    set(target_triple_simplified "${native_triple_simplified}")
  endif()

  set("${ARG_OUTPUT_TARGET_ARCH}" "${target_triple_arch}" PARENT_SCOPE)
  set("${ARG_OUTPUT_TARGET_VENDOR}" "${target_triple_vendor}" PARENT_SCOPE)
  set("${ARG_OUTPUT_TARGET_SYS}" "${target_triple_sys}" PARENT_SCOPE)
  set("${ARG_OUTPUT_TARGET_SYS_VERSION}" "${target_triple_sys_version}" PARENT_SCOPE)
  set("${ARG_OUTPUT_TARGET_ENV}" "${target_triple_env}" PARENT_SCOPE)
  set("${ARG_OUTPUT_TARGET_ENV_VERSION}" "${target_triple_env_version}" PARENT_SCOPE)
  set("${ARG_OUTPUT_TARGET_TRIPLE}" "${target_triple}" PARENT_SCOPE)
  set("${ARG_OUTPUT_TARGET_TRIPLE_NORMALIZED}" "${target_triple_normalized}" PARENT_SCOPE)
  set("${ARG_OUTPUT_TARGET_TRIPLE_SIMPLIFIED}" "${target_triple_simplified}" PARENT_SCOPE)

  message(NOTICE
    "  + native triple: ${native_triple}\n"
    "  + target triple: ${target_triple_normalized}\n"
    "  + cross compile: ${TOOLCHAINS_ENABLE_CROSS_COMPILE}"
  )
endfunction()
