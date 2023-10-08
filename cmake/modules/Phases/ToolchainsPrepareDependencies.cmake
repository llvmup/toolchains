include_guard(GLOBAL)

message(NOTICE "toolchains: Configuring phases: `prepare-dependencies`")

list(APPEND toolchains_git_apply_options
  --ignore-space-change
  --ignore-whitespace
  --whitespace=nowarn
)

if(TOOLCHAINS_ENABLE_SWIFT)
  ExternalProject_Add(sc
    URL "${TOOLCHAINS_EXTERNAL_APPLE_SWIFT_CMARK_URL}"
    URL_HASH "SHA512=${TOOLCHAINS_EXTERNAL_APPLE_SWIFT_CMARK_URL_HASH}"
    DOWNLOAD_NAME "${TOOLCHAINS_EXTERNAL_APPLE_SWIFT_CMARK_DOWNLOAD_NAME}"
    DOWNLOAD_DIR "${llvmup_toolchains_downloads_dir}"
    PREFIX "sc-p"

    BINARY_DIR "sc-p/src/sc-b"
    STAMP_DIR "sc-p/src/sc-s"

    ${TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS}

    PATCH_COMMAND ""
      COMMAND git init
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/cmark/01-cmark-install-static-libraries.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/cmark/02-cmark-install-headers.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/cmark/03-cmark-install-cmake-exports.patch"
      COMMAND "${CMAKE_COMMAND}" -E rm -rR .git

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
  )

  ExternalProject_Add(s
    URL "${TOOLCHAINS_EXTERNAL_APPLE_SWIFT_URL}"
    URL_HASH "SHA512=${TOOLCHAINS_EXTERNAL_APPLE_SWIFT_URL_HASH}"
    DOWNLOAD_NAME "${TOOLCHAINS_EXTERNAL_APPLE_SWIFT_DOWNLOAD_NAME}"
    DOWNLOAD_DIR "${llvmup_toolchains_downloads_dir}"
    PREFIX "s-p"

    BINARY_DIR "s-p/src/s-b"
    STAMP_DIR "s-p/src/s-s"

    ${TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS}

    PATCH_COMMAND ""
      COMMAND git init
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/01-swift-rename-doxygen-target.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/02-swift-install-headers.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/03-swift-install-features-file.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/04-swift-install-license.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/05-swift-rename-dev-target-into-swift-libraries.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/06-swift-install-cmake-exports.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/07-swift-export-library-properties.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/08-swift-modify-config-modules-for-relocatability.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/09-swift-expose-version-numbers-as-cache-variables.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/10-swift-add-options-for-static-libraries.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/11-swift-modify-deps-to-avoid-building-clang-tools.patch"
      COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/swift/12-swift-fix-dllimport.patch"
      COMMAND "${CMAKE_COMMAND}" -E rm -rR .git

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
  )
endif()

if(TOOLCHAINS_ENABLE_SWIFT)
  list(APPEND llvm_project_args
    URL "${TOOLCHAINS_EXTERNAL_APPLE_LLVM_PROJECT_URL}"
    URL_HASH "SHA512=${TOOLCHAINS_EXTERNAL_APPLE_LLVM_PROJECT_URL_HASH}"
    DOWNLOAD_NAME "${TOOLCHAINS_EXTERNAL_APPLE_LLVM_PROJECT_DOWNLOAD_NAME}"
  )
  list(APPEND llvm_project_patch_commands
    COMMAND git init
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/01-llvm-rename-cmake-exports-with-llvm-prefix.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/02-llvm-export-library-properties.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/03-llvm-install-license.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/04-mlir-export-library-properties.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/05-mlir-install-license.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/06-clang-export-library-properties.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/07-clang-install-license.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/08-clang-install-modulemaps-with-headers.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/09-lld-install-license.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/10-llvm-add-options-for-static-libraries.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/11-mlir-disable-shared-runtimes-unless-pic-enabled.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/12-clang-remove-indexstore-exports-needing-blocks-runtime.patch"
    COMMAND "${CMAKE_COMMAND}" -E rm -rR .git
    # NOTE: `swift` fails to configure without a `swift-syntax` directory, even though it isn't
    # actually needed to build just the C++ libs. As a workaround, and to save some efficiency by
    # avoiding downloading an unnecessary additional project repo, we just create a dummy directory
    # here and point the `SWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE` CMake variable to it. A simple
    # existence check satisfies the `swift` CMake configure script and configuration can continue.
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_BINARY_DIR}/lp-p/src/lp/ss"
    # Symlink the `cmark` project into the `llvm-project` source tree.
    COMMAND "${CMAKE_COMMAND}" -E create_symlink
      "${CMAKE_BINARY_DIR}/sc-p/src/sc"
      "${CMAKE_BINARY_DIR}/lp-p/src/lp/cmark"
    # Symlink the `swift` project into the `llvm-project` source tree.
    COMMAND "${CMAKE_COMMAND}" -E create_symlink
      "${CMAKE_BINARY_DIR}/s-p/src/s"
      "${CMAKE_BINARY_DIR}/lp-p/src/lp/swift"
  )
else()
  list(APPEND llvm_project_args
    URL "${TOOLCHAINS_EXTERNAL_LLVM_PROJECT_URL}"
    URL_HASH "SHA512=${TOOLCHAINS_EXTERNAL_LLVM_PROJECT_URL_HASH}"
    DOWNLOAD_NAME "${TOOLCHAINS_EXTERNAL_LLVM_PROJECT_DOWNLOAD_NAME}"
  )
  list(APPEND llvm_project_patch_commands
    COMMAND git init
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/01-llvm-rename-cmake-exports-with-llvm-prefix.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/02-llvm-export-library-properties.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/03-llvm-install-license.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/04-mlir-export-library-properties.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/05-mlir-install-license.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/06-clang-export-library-properties.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/07-clang-install-license.patch"
    COMMAND git apply ${toolchains_git_apply_options} "${CMAKE_SOURCE_DIR}/patches/trees/${TOOLCHAINS_TREE_NAME}/llvm-project/08-clang-install-modulemaps-with-headers.patch"
    COMMAND "${CMAKE_COMMAND}" -E rm -rR .git
  )
endif()

file(WRITE "${CMAKE_BINARY_DIR}/lp-p/src/lp/.keep" "")

ExternalProject_Add(lp
  ${llvm_project_args}
  DOWNLOAD_DIR "${llvmup_toolchains_downloads_dir}"
  PREFIX "lp-p"

  BINARY_DIR "lp-p/src/lp-b"
  STAMP_DIR "lp-p/src/lp-s"

  ${TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS}

  PATCH_COMMAND ""
    ${llvm_project_patch_commands}

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND ""
)
