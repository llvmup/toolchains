include_guard(GLOBAL)

message(NOTICE "toolchains: Configuring phases: `install-distributions-archives`")

install(DIRECTORY "${CMAKE_SOURCE_DIR}/dist/"
  DESTINATION "${llvmup_toolchains_downloads_dir}"
  PATTERN "*${TOOLCHAINS_DISTRIBUTION_ARCHIVE_EXTENSION}"
)

foreach(archive IN ITEMS ${toolchains_package_build_byproducts})
  install(CODE "file(ARCHIVE_EXTRACT INPUT \"${CMAKE_SOURCE_DIR}/dist/${archive}\" DESTINATION \"${CMAKE_BINARY_DIR}/dist/install\")")
endforeach()

install(DIRECTORY "${CMAKE_BINARY_DIR}/dist/install/trees/"
  DESTINATION "${llvmup_toolchains_trees_dir}"
)
