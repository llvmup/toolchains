include_guard(GLOBAL)

include("${CMAKE_SOURCE_DIR}/cmake/modules/Support/ArgumentParsing.cmake")

function(toolchains_detect_llvmup_dir)
  cmake_parse_and_validate_arguments(
    # prefix
    "ARG"
    # options
    ""
    # one_value_keywords
    "OUTPUT_DIR"
    # multi_value_keywords
    ""
    # pass through arguments
    "${ARGN}"
  )

  if(CMAKE_HOST_WIN32)
    execute_process(
      COMMAND cmd.exe /C "echo %homedrive%%homepath%"
      OUTPUT_VARIABLE home_dir
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    cmake_path(CONVERT "${home_dir}" TO_CMAKE_PATH_LIST home_dir NORMALIZE)
    elseif(CMAKE_HOST_UNIX)
    execute_process(
      COMMAND bash -c "echo $HOME"
      OUTPUT_VARIABLE home_dir
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    cmake_path(CONVERT "${home_dir}" TO_CMAKE_PATH_LIST home_dir NORMALIZE)
  endif()

  set(${ARG_OUTPUT_DIR} "${home_dir}/.llvmup" PARENT_SCOPE)
endfunction()

function(toolchains_detect_llvmup_dirs)
  cmake_parse_and_validate_arguments(
    # prefix
    "ARG"
    # options
    ""
    # one_value_keywords
    "OUTPUT_DOWNLOADS_DIR;OUTPUT_TREES_DIR"
    # multi_value_keywords
    ""
    # pass through arguments
    "${ARGN}"
  )

  message(NOTICE "toolchains: Configuring llvmup directories")

  toolchains_detect_llvmup_dir(OUTPUT_DIR llvmup_dir)
  set("${ARG_OUTPUT_DOWNLOADS_DIR}" "${llvmup_dir}/downloads" PARENT_SCOPE)
  set("${ARG_OUTPUT_TREES_DIR}" "${llvmup_dir}/trees" PARENT_SCOPE)
endfunction()
