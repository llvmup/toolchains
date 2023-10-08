include_guard(GLOBAL)

macro(cmake_parse_and_validate_arguments prefix options one_value_keywords multi_value_keywords args)
  cmake_parse_arguments("${prefix}" "${options}" "${one_value_keywords}" "${multi_value_keywords}" ${args})
  if(DEFINED ${prefix}_UNPARSED_ARGUMENTS)
    message(WARNING "Unexpected arguments: ${${prefix}_UNPARSED_ARGUMENTS}")
  endif()
  if(DEFINED ${prefix}_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR "toolchains: Missing values for keywords: ${${prefix}_KEYWORDS_MISSING_VALUES}")
  endif()
  foreach(one_value_keyword IN ITEMS ${one_value_keywords})
    if(NOT DEFINED ${prefix}_${one_value_keyword})
      message(FATAL_ERROR "toolchains: Argument `${one_value_keyword}` must be defined when calling `toolchains_configure_host_tools`")
    endif()
  endforeach()
endmacro()
