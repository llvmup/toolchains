<div align="center">
  <h1><code>toolchains</code></h1>
  <p>
    <strong>LLVM distributions optimized for portability and accessibility</strong>
  </p>
  <p>
    <a href="https://github.com/llvmup/toolchains/actions">
      <img
        src="https://github.com/llvmup/toolchains/workflows/build/badge.svg"
      />
    </a>
  </p>
</div>

## Synopsis

This repository contains a CMake superbuild script for assembling a collection of easy to use, relocatable, multi-distribution LLVM toolchain component packaged as tarballs.

These distributions are intended to be easy to download and use with any of the major operating systems and compiler toolchains, with minimal external dependencies, and no system-level configuration required.

The distributions consist of the following components:

- the [Clang](https://clang.llvm.org/) tool {`clang`, `clang++`, `clang-cl.exe`}
- the [LLD](https://lld.llvm.org/) tool {`ld.lld`, `ld64.lld`, `lld`, `lld-link.exe`}
- headers and static libraries for the [LLVM APIs](https://llvm.org/doxygen/)
- headers and static libraries for the [MLIR APIs](https://mlir.llvm.org/doxygen/)
- headers and static libraries for the [Clang APIs](https://clang.llvm.org/doxygen/)
- headers and static libraries for the [Swift APIs](https://www.swift.org/)

Aside from `clang` and `lld`, the distributions do not contain other toolchain binaries, because they are intended to be used for linking in other projects that [build their own tools](https://clang.llvm.org/docs/index.html#using-clang-as-a-library).

The `lld` tool is included as a convenience because the libraries are compiled with [ThinLTO](https://clang.llvm.org/docs/ThinLTO.html) which requires that a [compatible linker](https://clang.llvm.org/docs/ThinLTO.html#linkers) be available at link time.

Similarly, the `clang` tool is included as a convenience for Rust users of the `cxx-*` crates that link against these libraries, in order to enable a seamless LTO-supporting compilation pipeline, without requiring the user to install and configure an additional compiler manually.

## Usage

You can download the appropriate tarballs for your system from the Releases section.

You can also clone this repository and run the CMake build script yourself to produce the distribution tarballs locally on your workstation. See the build instructions below for further details.

In the future, we intend to build a CLI tool `llvmup` that will automate the process of downloading and extracting the tarballs into a project's build directory and allow for easily maintaining multiple installed versions of the toolchains.

### Building the Distributions with CMake

#### Common Prequisites for all Operating Systems

- [Clang](https://clang.llvm.org/) `17.0.0` or later
- [LLD](https://lld.llvm.org/) `17.0.0` or later
- [CMake](https://cmake.org/) `3.27` or later
- [Ninja](https://ninja-build.org/) `1.11` or later

#### Linux Prerequisites

On Linux, if you are on an `x86_64` system, we recommend installing the prerequisites with [Homebrew](https://brew.sh/):

```bash
brew install ccache cmake ninja llvm@17
```

If you are on a different architecture, but using a Debian-based distribution, we recommend installing the prerequisites with `apt`:

```bash
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
echo "deb     http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VERSION} main" | sudo tee --append /etc/apt/sources.list.d/llvmup-llvmorg.list
echo "deb-src http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VERSION} main" | sudo tee --append /etc/apt/sources.list.d/llvmup-llvmorg.list
sudo apt update -o Dir::Etc::sourcelist="sources.list.d/llvmup-llvmorg.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
sudo apt install clang-17 lld-17
```

Unfortunately `apt` may not have the latest version of `cmake` and `ninja`, so you may need to install those manually.

#### macOS Prerequisites

On macOS (regardless of architecture), we recommend installing the prerequisites with [Homebrew](https://brew.sh/):

```bash
brew install ccache cmake ninja llvm@17
```

Of course you will also need a current Xcode installation as well. The superbuild should work on `macOS 13` or later. Earlier versions have not been tested.

#### Windows Prerequisites

##### Windows System Configuration

- Ensure your system is configured for [Developer Mode](https://learn.microsoft.com/en-us/windows/apps/get-started/developer-mode-features-and-debugging). This is necessary to support CMake's creation of symlinks without requiring administrator privileges.

- Ensure "Enable Win32 long paths" is enabled in the Group Policy Editor. Some parts of the LLVM toolchains may fail to build without this.

##### Windows Git Configuration

First, before checking out the repo on Windows, ensure your git configuration also supports symlinks and longpaths:

```
git config --global core.symlinks true
git config --global core.longpaths true
```

##### Windows MSVC toolchain and Clang toolchain

On Windows, you will need the MSVC toolchain installed. You can obtain this through any of the Visual Studio installers, including the basic [Build Tools](https://visualstudio.microsoft.com/downloads/?q=build+tools#build-tools-for-visual-studio-2022). You can install through `winget` with the following:

```pwsh
winget install Microsoft.VisualStudio.2022.BuildTools
```

We recommend installing the remaining prerequisites with [Scoop](https://scoop.sh/):

```pwsh
scoop install ccache cmake ninja llvm@17.0.5
```

LLVM must to be installed because we compile with ThinLTO, so we use `clang-cl` and `lld`, although the MSVC libraries are still needed during compilation.

#### Building

For a standard build of the distributions it is enough to invoke the following commands:

```
cmake --preset=release
cmake --build --preset=release
```

This will produce a distribution using the official LLVM organization's [llvm/llvm-project](https://github.com/llvm/llvm-project).

The distribution files will be placed in the `dist` directory and have names following the scheme:

```
llvm-llvmorg-17.0.0-aarch64-macos.tar.xz
mlir-llvmorg-17.0.0-aarch64-macos.tar.xz
clang-llvmorg-17.0.0-aarch64-macos.tar.xz
tools-llvmorg-17.0.0-aarch64-macos.tar.xz
```

#### Installing

The tarballs mentioned previously extract to a common directory structure like:

```
trees
└── llvmorg-17.0.0
    └── aarch64-macos
        ├── bin
        ├── include
        ├── lib
        └── share
```

To install the extracted tree, you can run the following commands, after the previously mentioned build commands:

```
cmake --install b
```

This will place the extracted tree at the following location:

```
~/.llvmup/trees/...
```

Additionally, the tarballs will be placed in the following location:

```
~/.llvmup/downloads/...
```

Of course, you can manually extract the tarballs wherever you like, so this step is not strictly necessary.

#### Using the installed toolchains

The installed toolchain trees can be used from CMake in the following way:

```cmake
cmake_minimum_required(VERSION 3.27 FATAL_ERROR)

# NOTE: change this to wherever you extracted the tarballs, as needed
set(TOOLCHAINS_TREES_DIR "$ENV{HOME}/.cache/llvmup")

project(LLVMLibsExample
  LANGUAGES C CXX
)

find_package(LLVM REQUIRED CONFIG
  PATHS "${TOOLCHAINS_TREES_DIR}/trees/llvmorg-17.0.0/aarch64-macos/lib/cmake"
  NO_DEFAULT_PATH
)
find_package(MLIR REQUIRED CONFIG
  PATHS "${TOOLCHAINS_TREES_DIR}/trees/llvmorg-17.0.0/aarch64-macos/lib/cmake"
  NO_DEFAULT_PATH
)
find_package(Clang REQUIRED CONFIG
  PATHS "${TOOLCHAINS_TREES_DIR}/trees/llvmorg-17.0.0/aarch64-macos/lib/cmake"
  NO_DEFAULT_PATH
)

add_executable(example
  "src/main.cxx"
)

target_link_libraries(example PRIVATE
  LLVMSupport
  clangAST
  clangASTMatchers
  clangBasic
  clangFrontend
  clangSerialization
  clangTooling
)
```

##### Enabling Swift Components

Alternatively, you can enable Swift support by passing the `-DTOOLCHAINS_ENABLE_SWIFT=ON"` option to CMake:

```
cmake --preset=release "-DTOOLCHAINS_ENABLE_SWIFT=ON"
cmake --build --preset=release
```

This option changes the source repository to Apple's LLVM fork at [apple/llvm-project](https://github.com/llvm/llvm-project), which is necessary in order to build the Swift components.

##### Enabling or Disabling Other Components

Other options are available to customize the build:

- `-DTOOLCHAINS_ENABLE_MLIR=BOOL` (default: `ON`) - Build the MLIR distribution components
- `-DTOOLCHAINS_ENABLE_CLANG=BOOL` (default: `ON`) - Build the Clang distribution components
- `-DTOOLCHAINS_ENABLE_SWIFT=BOOL` (default: `OFF`) - Build the Swift distribution components
- `-DTOOLCHAINS_ENABLE_TOOL_CLANG=BOOL` (default: `ON`) - Build the `clang` tool distribution components
- `-DTOOLCHAINS_ENABLE_TOOL_LLD=BOOL` (default: `ON`) - Build the `lld` tool distribution components

#### Displaying Informative Build Progress

The superbuild can take awhile, especially on the first run without any ccache support, so it's helpful to know what the current build progress looks like.

Unfortunately, the Ninja CMake generator does not report most of the details of the build progress when using `ExternalProject` like this superbuild script does.

In order to work around that, you can instead launch the CMake build using the `scripts/cmake-tail.sh` script, which is simply a wrapper around the `cmake` command which tails the log files after launching the build:

```
cmake --preset=release
./scripts/cmake-tail.sh --build --preset=release
```

The script works directly on `macOS` and `Linux`. For `windows`, there is a wrapper script with the same invocation syntax named `./scripts/cmake-tail.cmd` that attempts to launch [Git Bash](https://gitforwindows.org/) first, and then invokes the bash script.

#### Cross Compilation

It's also possible to cross compile the distributions for a different target architecture than the host architecture by setting the `TOOLCHAINS_TARGET_ARCH` variable:

```
cmake --preset=release "-DTOOLCHAINS_TARGET_ARCH=riscv64"
cmake --build --preset=release
```

Cross-OS cross-compilation is not currently supported.

##### macOS and Windows

On macOS and Windows, cross-compilation should "just work" for the alternate OS architectures, as long as you have Xcode or Visual Studio installed with the correct SDKs.

##### Linux

###### Cross-packages

On Linux, for Debian based distributions, we provide a helper script `scripts/apt-install-deps.sh -t <arch>` (where `<arch>` could be `arm64` or `riscv64`, for example) which will install the standard prerequisites as well as the cross-compilation packages for specified architecture.

You can also install these manually with `apt`:

```bash
sudo apt install \
  libc6-<arch>-cross \
  libc6-dev-<arch>-cross \
  libgcc-12-dev-<arch>-cross \
  libgcc-s1-<arch>-cross \
  libstdc++-12-dev-<arch>-cross \
  linux-libc-dev-<arch>-cross
```

###### Multiarch

Alternatively, you can configure [Debian](https://wiki.debian.org/Multiarch/HOWTO) or [Ubuntu](https://help.ubuntu.com/community/MultiArch) "Multiarch" support and install the above packages without the `-cross` suffix, but with the architecture specified explicitly, e.g., `libc6:riscv64`.

Multiarch is more work to set up, but more flexible in that you can install any package (not just the `-cross` packages), which may be needed for certain dependencies, (e.g., `uuid-dev` for Swift on Linux).

Multiarch also has the advantage that [QEMU](https://www.qemu.org/) can automatically detect the configuration and seamlessly use installed packages for [transparent](https://wiki.debian.org/QemuUserEmulation) user emulation.

The GitHub workflow script for this repo uses the Multiarch approach, so you can check [action.yaml](.github/actions/build-distributions/action.yaml) for examples of how to set this up locally.
