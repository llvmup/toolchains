include_guard(GLOBAL)

message(NOTICE "toolchains: Configuring phases: `prepare-distributions-archives`")

set(toolchains_package_build_byproducts "")

if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  set(toolchains_archive_release_type "-debug")
else()
  set(toolchains_archive_release_type "")
endif()

set(toolchains_archive_suffix "${toolchains_archive_release_type}-${TOOLCHAINS_TREE_NAME}-${toolchains_target_triple_simplified}${TOOLCHAINS_RELEASE_REV_SUFFIX}")

foreach(distribution IN ITEMS
  CLANG
  LLVM
  MLIR
  SWIFT
  TOOL_CLANG
  TOOL_LLD
)
  if(TOOLCHAINS_ENABLE_${distribution})
    string(TOLOWER "${distribution}" distribution)
    list(APPEND toolchains_package_build_byproducts
      "${distribution}${toolchains_archive_suffix}${TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION}"
    )
    list(APPEND toolchains_manifest_byproducts
      "${CMAKE_SOURCE_DIR}/dist/${distribution}${toolchains_archive_suffix}-llvmup.json${TOOLCHAINS_MANIFEST_ARCHIVE_EXTENSION}"
    )
  endif()
endforeach()

list(TRANSFORM toolchains_package_build_byproducts
  PREPEND "${CMAKE_SOURCE_DIR}/dist/"
  OUTPUT_VARIABLE toolchains_package_build_byproducts_full_paths
)

ExternalProject_Add(tp
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/cmake/projects/toolchains-pack"
  PREFIX "tp-p"

  BINARY_DIR "tp-p/src/tp-b"
  STAMP_DIR "tp-p/src/tp-s"

  DEPENDS "tep"

  BUILD_BYPRODUCTS ${toolchains_package_build_byproducts_full_paths}

  ${TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS}

  CMAKE_ARGS
    --fresh
    -Werror=deprecated
    -Werror=dev
    --warn-uninitialized
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/i"
    "-DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}"
    ${toolchains_cross_compilation_system_flags}
    "-DTOOLCHAINS_CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}"
    "-DTOOLCHAINS_CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR}"
    "-DTOOLCHAINS_TARGET_TRIPLE=${toolchains_target_triple_simplified}"
  BUILD_COMMAND ""
    COMMAND
      "${CMAKE_COMMAND}" -E chdir "${CMAKE_BINARY_DIR}/tp-p/src/tp-b"
      "${CMAKE_CPACK_COMMAND}" -G "${CPACK_GENERATOR}"

  INSTALL_COMMAND ""
    COMMAND "${CMAKE_COMMAND}"
      --build "${CMAKE_BINARY_DIR}/tp-p/src/tp-b"
      --target install-packages
    # ${install_manifests_targets}
)

add_custom_target(generate-standalone-manifests ALL
  DEPENDS tp
  VERBATIM
  BYPRODUCTS ${toolchains_manifest_byproducts}
  COMMAND "${CMAKE_COMMAND}"
    "-DTOOLCHAINS_CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}"
    "-DTOOLCHAINS_CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR}"
    "-DTOOLCHAINS_TARGET_TRIPLE=${toolchains_target_triple_simplified}"
    -P "${CMAKE_SOURCE_DIR}/cmake/modules/Script/CompressManifests.cmake"
)

add_custom_target(generate-sha512sums ALL
  DEPENDS generate-standalone-manifests
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/dist"
  VERBATIM
  BYPRODUCTS "${CMAKE_SOURCE_DIR}/dist/${TOOLCHAINS_TREE_NAME}-${toolchains_target_triple_simplified}.sha512"
  COMMAND "${CMAKE_COMMAND}" -E sha512sum ${toolchains_package_build_byproducts} > "${CMAKE_SOURCE_DIR}/dist/${TOOLCHAINS_TREE_NAME}-${toolchains_target_triple_simplified}${TOOLCHAINS_RELEASE_REV_SUFFIX}.sha512"
)
