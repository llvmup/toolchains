include_guard(GLOBAL)

message(NOTICE "toolchains: Configuring phases: `prepare-distributions-configurations`")

ExternalProject_Add(tep
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/cmake/projects/toolchains-emit-properties"
  PREFIX "tep-p"

  BINARY_DIR "tep-p/src/tep-b"
  STAMP_DIR "tep-p/src/tep-s"

  DEPENDS "tlp"

  ${TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS}

  CMAKE_ARGS
    --fresh
    -Werror=deprecated
    -Werror=dev
    --warn-uninitialized
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}"
    ${toolchains_cross_compilation_system_flags}
    "-DTOOLCHAINS_CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}"
    "-DTOOLCHAINS_CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR}"

  BUILD_COMMAND ""
  INSTALL_COMMAND ""
)
