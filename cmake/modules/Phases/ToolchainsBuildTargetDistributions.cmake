include_guard(GLOBAL)

message(NOTICE "toolchains: Configuring phases: `build-target-distributions`")

set(llvm_project_depends "")
set(llvm_project_build_byproducts "")
set(llvm_project_cmake_args_LLVM_DISTRIBUTIONS "")
set(llvm_project_cmake_args_LLVM_EXTERNAL_PROJECTS "")
set(llvm_project_cmake_args_LLVM_ENABLE_PROJECTS "")
set(llvm_project_build_commands "")
set(llvm_project_install_commands "")

set(llvm_project_cross_compilation_flags "")
if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
  list(APPEND llvm_project_cross_compilation_flags
    ${toolchains_cross_compilation_system_flags}
    ${toolchains_cross_compilation_compiler_target_flags}
  )
endif()

list(APPEND llvm_project_cmake_args
  "-DLLVM_TARGETS_TO_BUILD=${TOOLCHAINS_LLVM_TARGETS_TO_BUILD}"

  "-DLLVM_ENABLE_PIC=OFF"
  "-DLLVM_ENABLE_LTO=${TOOLCHAINS_ENABLE_LTO}"
  "-DLLVM_ENABLE_BINDINGS=OFF"
  "-DLLVM_ENABLE_LIBEDIT=OFF"
  "-DLLVM_ENABLE_LIBPFM=OFF"
  "-DLLVM_ENABLE_LIBXML2=OFF"
  "-DLLVM_ENABLE_TERMINFO=OFF"
  "-DLLVM_ENABLE_Z3_SOLVER=OFF"
  "-DLLVM_ENABLE_ZLIB=OFF"
  "-DLLVM_ENABLE_ZSTD=OFF"

  "-DLLVM_USE_LINKER=${CMAKE_LINKER}"
  "-DLLVM_USE_SYMLINKS=ON"
  "-DLLVM_OPTIMIZED_TABLEGEN=ON"

  "-DCLANG_BUILD_TOOLS=ON"
)
if(CMAKE_HOST_APPLE)
  list(APPEND llvm_project_cmake_args
    "-DCMAKE_LIBTOOL=${CMAKE_LIBTOOL}"
  )
endif()

###########################################
# Configuration specific to bootstrapping #
###########################################

if(TOOLCHAINS_ENABLE_CROSS_COMPILE)
  list(APPEND llvm_project_depends
    "tlp-host"
  )
else()
  list(APPEND llvm_project_depends
    "lp"
  )
endif()

###############################
# Configure the distributions #
###############################

message(NOTICE "toolchains: Configuring distributions")

###########################
# Configure distributions #
###########################

include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/distributions/clang.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/distributions/llvm.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/distributions/mlir.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/distributions/swift.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/distributions/tool_clang.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/modules/Phases/distributions/tool_lld.cmake")

###################################
# Configure the external projects #
###################################

list(REMOVE_DUPLICATES llvm_project_cmake_args_LLVM_EXTERNAL_PROJECTS)
list(SORT llvm_project_cmake_args_LLVM_EXTERNAL_PROJECTS)
list(JOIN llvm_project_cmake_args_LLVM_EXTERNAL_PROJECTS "|" llvm_project_cmake_args_LLVM_EXTERNAL_PROJECTS)
list(APPEND llvm_project_cmake_args
  "-DLLVM_EXTERNAL_PROJECTS=${llvm_project_cmake_args_LLVM_EXTERNAL_PROJECTS}"
)

##################################
# Configure the enabled projects #
##################################

list(REMOVE_DUPLICATES llvm_project_cmake_args_LLVM_ENABLE_PROJECTS)
list(SORT llvm_project_cmake_args_LLVM_ENABLE_PROJECTS)
list(JOIN llvm_project_cmake_args_LLVM_ENABLE_PROJECTS "|" llvm_project_cmake_args_LLVM_ENABLE_PROJECTS)
list(APPEND llvm_project_cmake_args
  "-DLLVM_ENABLE_PROJECTS=${llvm_project_cmake_args_LLVM_ENABLE_PROJECTS}"
)

####################################
# Configure the multi-distribution #
####################################

# Convert distribution lists to strings separated by '|' to avoid parsing issues in `ExternalProject_Add`.
list(JOIN llvm_project_cmake_args_LLVM_DISTRIBUTIONS "|" llvm_project_cmake_args_LLVM_DISTRIBUTIONS)
list(APPEND llvm_project_cmake_args
  "-DLLVM_DISTRIBUTIONS=${llvm_project_cmake_args_LLVM_DISTRIBUTIONS}"
)

##################################################################
# Configure the `vcvarsall.bat` launcher for Windows MSVC builds #
##################################################################

string(REPLACE "armv7" "arm" toolchains_pkg_config_triple "${toolchains_target_triple_simplified}")
set(toolchains_cmake_command "")
if(CMAKE_HOST_LINUX)
  list(APPEND toolchains_cmake_command
    CMAKE_COMMAND
      "${CMAKE_COMMAND}" -E env "PKG_CONFIG_PATH=/usr/lib/${toolchains_pkg_config_triple}/pkgconfig"
      "${CMAKE_COMMAND}"
  )
endif()
if(CMAKE_HOST_WIN32)
  list(APPEND toolchains_cmake_command
    CMAKE_COMMAND "${toolchains_cmake_vcvars_target}"
  )
endif()

ExternalProject_Add(tlp
  ${toolchains_llvm_project_args}
  PREFIX "tlp-p"

  BINARY_DIR "tlp-p/src/tlp-b"
  STAMP_DIR "tlp-p/src/tlp-s"

  DEPENDS
    ${llvm_project_depends}

  BUILD_BYPRODUCTS
    ${llvm_project_build_byproducts}

  ${TOOLCHAINS_EXTERNAL_PROJECT_LOG_OPTIONS}

  ${toolchains_cmake_command}

  CMAKE_ARGS
    --fresh
    -Wno-deprecated
    -Wno-dev
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/i"
    "-DCMAKE_VERBOSE_MAKEFILE=${CMAKE_VERBOSE_MAKEFILE}"
    ${llvm_project_cross_compilation_flags}
    ${llvm_project_cmake_args}

  BUILD_COMMAND ""
    ${llvm_project_build_commands}

  INSTALL_COMMAND ""
    ${llvm_project_install_commands}
)
