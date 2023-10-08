#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -x

LLVM_VERSION=17

# Set up the official LLVM deb repo to fetch clang and related dependencies

if ! test -f /etc/apt/sources.list.d/llvmup-llvmorg.list; then
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
  echo "deb     http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VERSION} main" | sudo tee --append /etc/apt/sources.list.d/llvmup-llvmorg.list
  echo "deb-src http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VERSION} main" | sudo tee --append /etc/apt/sources.list.d/llvmup-llvmorg.list
fi

sudo apt update -o Dir::Etc::sourcelist="sources.list.d/llvmup-llvmorg.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
sudo apt upgrade
sudo apt install clang-17 lld-17

TARGETS=()

while getopts "t:" opt; do
  case $opt in
    t) TARGETS+=("$OPTARG");;
  esac
done

for target in "${TARGETS[@]}"
do
  sudo apt install \
    libc6-${target}-cross \
    libc6-dev-${target}-cross \
    libgcc-12-dev-${target}-cross \
    libgcc-s1-${target}-cross \
    libstdc++-12-dev-${target}-cross \
    linux-libc-dev-${target}-cross
done
