include_guard(GLOBAL)

# NOTE: Keep this synchronized with `${CMAKE_SOURCE_DIR}/Toolchains/Support/ArgumentParsing.cmake`
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

list(APPEND TOOLCHAINS_DISTRIBUTION_LIST
  LLVM
  CLANG
  MLIR
  SWIFT
  TOOL_CLANG
  TOOL_LLD
)

foreach(distribution IN ITEMS ${TOOLCHAINS_DISTRIBUTION_LIST})
  string(TOLOWER "${distribution}" distribution_name_lower)
  string(TOUPPER "${distribution}" distribution_name_upper)
  set(TOOLCHAINS_${distribution_name_upper}_DISTRIBUTION_PATH "${TOOLCHAINS_CMAKE_BINARY_DIR}/i-${distribution_name_lower}/")
  set(TOOLCHAINS_${distribution_name_upper}_DISTRIBUTION_TARGETS "")
endforeach()

function(toolchains_get_cmake_property_list)
  cmake_parse_and_validate_arguments(
    # prefix
    "ARG"
    # options
    ""
    # one_value_keywords
    "OUTPUT_CMAKE_COMPLETE_PROPERTIES;OUTPUT_CMAKE_EXCLUDED_PROPERTIES;OUTPUT_CMAKE_LISTLIKE_PROPERTIES"
    # multi_value_keywords
    ""
    # pass through arguments
    "${ARGN}"
  )
  execute_process(COMMAND ${CMAKE_COMMAND} --help-property-list
    RESULT_VARIABLE toolchains_cmake_property_list_result
    OUTPUT_VARIABLE toolchains_cmake_property_list
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(NOT "${toolchains_cmake_property_list_result}" EQUAL 0)
    message(FATAL_ERROR "\"${CMAKE_COMMAND}\": returned non-zero exit")
  endif()
  string(REGEX REPLACE "\n" ";" toolchains_cmake_property_list "${toolchains_cmake_property_list}")
  list(REMOVE_DUPLICATES toolchains_cmake_property_list)
  set(${ARG_OUTPUT_CMAKE_COMPLETE_PROPERTIES} "${toolchains_cmake_property_list}" PARENT_SCOPE)
  set(${ARG_OUTPUT_CMAKE_EXCLUDED_PROPERTIES}
    "BINARY_DIR"
    "SOURCE_DIR"
    PARENT_SCOPE
  )
  set(${ARG_OUTPUT_CMAKE_LISTLIKE_PROPERTIES}
    "IMPORTED_CONFIGURATIONS"
    "INTERFACE_INCLUDE_DIRECTORIES"
    "INTERFACE_LINK_DIRECTORIES"
    "INTERFACE_LINK_LIBRARIES"
    PARENT_SCOPE
  )
endfunction()

# NOTE: this should be defined *before* `toolchains_emit_distribution_llvmup_json`
toolchains_get_cmake_property_list(
  OUTPUT_CMAKE_COMPLETE_PROPERTIES toolchains_cmake_complete_properties
  OUTPUT_CMAKE_EXCLUDED_PROPERTIES toolchains_cmake_excluded_properties
  OUTPUT_CMAKE_LISTLIKE_PROPERTIES toolchains_cmake_listlike_properties
)

# NOTE: this should be defined *after* `toolchains_emit_distribution_llvmup_json`
function(toolchains_emit_distribution_llvmup_json)
  cmake_parse_and_validate_arguments(
    # prefix
    "ARG"
    # options
    ""
    # one_value_keywords
    "INPUT_DISTRIBUTION_NAME;INPUT_DISTRIBUTION_PATH"
    # multi_value_keywords
    ""
    # pass through arguments
    "${ARGN}"
  )

  string(TOLOWER "${ARG_INPUT_DISTRIBUTION_NAME}" distribution_name_lower)
  string(TOUPPER "${ARG_INPUT_DISTRIBUTION_NAME}" distribution_name_upper)

  set(llvmup "{}")
  string(JSON llvmup SET "${llvmup}" "cmakeProperties" "{}")
  string(JSON llvmup SET "${llvmup}" "cmakeProperties" "IMPORTED_TARGETS" "{}")

  # Get the IMPORTED targets for current CMake source directory.
  get_property(imported_inherent_targets DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY IMPORTED_TARGETS)

  # Iterate through the distributions ...
  foreach(name_outer IN ITEMS ${TOOLCHAINS_DISTRIBUTION_LIST})
    # Remove already processed targets from each other distribution for deduplication purposes.
    list(REMOVE_ITEM imported_inherent_targets
      ${TOOLCHAINS_${name_outer}_DISTRIBUTION_TARGETS}
    )

    # Prepare a new variable for imported `adjacent` targets from currently processing distribution.
    string(TOLOWER "${name_outer}" name_outer_lower)
    get_property(imported_${name_outer_lower}_targets DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY IMPORTED_TARGETS)

    # For every other distribution but the current, remove their targets, for deduplication purposes.
    foreach(name_inner IN ITEMS ${TOOLCHAINS_DISTRIBUTION_LIST})
      if("${name_inner}" STREQUAL "${name_outer}")
        continue()
      endif()
      string(TOLOWER "${name_inner}" name_inner_lower)
      list(REMOVE_ITEM imported_${name_outer_lower}_targets
        ${TOOLCHAINS_${name_inner}_DISTRIBUTION_TARGETS}
      )
    endforeach()
  endforeach()

  # Remember the `inherent` targets from this distribution in cache.
  set(TOOLCHAINS_${distribution_name_upper}_DISTRIBUTION_TARGETS
    ${imported_inherent_targets}
    PARENT_SCOPE
  )

  # Process the list of distribution-specific adjacent targets we set in the prior for loop.
  foreach(name IN ITEMS ${TOOLCHAINS_DISTRIBUTION_LIST})
    string(TOLOWER "${name}" name_lower)
    # Remove the imported `inherent` targets, leaving only the imported `adjacent` targets.
    list(REMOVE_ITEM imported_${name_lower}_targets ${imported_inherent_targets})
    foreach(target IN ITEMS ${imported_${name_lower}_targets})
      string(JSON llvmup SET "${llvmup}" "cmakeProperties" "IMPORTED_TARGETS" "${target}" "{ \"llvmupTargetKind\": \"adjacent\", \"llvmupDistribution\": \"${name_lower}\" }")
    endforeach()
  endforeach()

  # Process the known CMake properties for each imported target.
  foreach(target IN ITEMS ${imported_inherent_targets})
    set(target_properties "{}")

    # Process each known CMake property for the current imported target.
    foreach(property IN ITEMS ${toolchains_cmake_complete_properties})
      list(FIND toolchains_cmake_excluded_properties "${property}" found_excluded_property)
      if(${found_excluded_property} GREATER_EQUAL 0)
        continue()
      endif()

      get_target_property(target_property_value "${target}" "${property}")

      if(target_property_value)
        # Check the property value actually contains a `;` which indicates it is an aggregate value.
        string(FIND "${target_property_value}" ";" found_list_like_property)
        # Check whether we expect the property to have an aggregate value (specified manually ahead-of-time).
        list(FIND toolchains_cmake_listlike_properties "${property}" expecting_list_like_property)

        # NOTE: Rewrite paths within distribution directories so they are relative. For users that
        # load the CMake config files at compile time (from another CMake script), this is not an
        # issue since the imported properties will be set with respect to the current install
        # location. But here we are producing the `llvmup.json` ahead-of-time and cannot anticipate
        # the final install location, so we must avoid absolute paths.
        string(REPLACE "${TOOLCHAINS_CLANG_DISTRIBUTION_PATH}" "" target_property_value "${target_property_value}")
        string(REPLACE "${TOOLCHAINS_LLVM_DISTRIBUTION_PATH}" "" target_property_value "${target_property_value}")
        string(REPLACE "${TOOLCHAINS_MLIR_DISTRIBUTION_PATH}" "" target_property_value "${target_property_value}")
        string(REPLACE "${TOOLCHAINS_SWIFT_DISTRIBUTION_PATH}" "" target_property_value "${target_property_value}")
        string(REPLACE "${TOOLCHAINS_TOOL_CLANG_DISTRIBUTION_PATH}" "" target_property_value "${target_property_value}")
        string(REPLACE "${TOOLCHAINS_TOOL_LLD_DISTRIBUTION_PATH}" "" target_property_value "${target_property_value}")

        # NOTE: This is a one-off hack to work around `libuuid` being linked with the full system
        # path specified. We may need to implement a more robust solution if this becomes an issue
        # with other libraries we may need to include (e.g., ZLIB, Zstd, etc).
        string(REGEX REPLACE "/usr/lib/.+-linux-gnu(eabihf)?/libuuid\\.so" "libuuid.so" target_property_value "${target_property_value}")

        # Attempt to detect any remaining unprocessing absolute paths and fail if found.
        if("${target_property_value}" MATCHES "(^|;)/")
          message(FATAL_ERROR
            "  Encountered property with absolute paths:\n"
            "  + property: ${property}\n"
            "  +    value: ${target_property_value}\n"
          )
        endif()

        # Process aggregate values by splitting at `;` and collecting the components in a JSON array.
        if(${expecting_list_like_property} GREATER_EQUAL 0)
          set(target_property_values "")
          set(valueIsFirst TRUE)

          foreach(value IN ITEMS ${target_property_value})
            if(NOT valueIsFirst)
              string(APPEND target_property_values ", ")
            endif()
            string(APPEND target_property_values "\"${value}\"")
            unset(valueIsFirst)
          endforeach()

          string(JSON target_properties SET "${target_properties}" "${property}" "[${target_property_values}]")
        # Process singular values as strings.
        else()
          # But first check whether we found an aggregate value but were not expecting one. Error
          # here so we can catch these and update the aggregate list as needed.
          if(${found_list_like_property} GREATER_EQUAL 0)
            message(FATAL_ERROR "Encountered unexpected list-like property: `${property}`")
          endif()
          string(JSON target_properties SET "${target_properties}" "${property}" "\"${target_property_value}\"")
        endif()

      endif()

    endforeach()

    string(JSON target_properties SET "${target_properties}" "llvmupTargetKind" "\"inherent\"")
    string(JSON llvmup SET "${llvmup}" "cmakeProperties" "IMPORTED_TARGETS" "${target}" "${target_properties}")
  endforeach()

  file(WRITE
    "${ARG_INPUT_DISTRIBUTION_PATH}/share/${distribution_name_lower}/llvmup.json"
    "${llvmup}"
  )
endfunction()
