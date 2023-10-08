#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -x

pushd() {
  command pushd "$@" > /dev/null
}

popd() {
  command popd "$@" > /dev/null
}

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

CMAKE_SOURCE_DIR=$(realpath "${DIR}/../scripts/..")

pushd "${CMAKE_SOURCE_DIR}"

tail -F \
  ./b/ctest/{release}.log \
  ./b/tt-p/output.log \
  ./b/tt-p/tt-clang-p/src/tt-clang-s/tt-clang-{download,patch,configure,build,install}.log \
  ./b/tt-p/tt-llvm-p/src/tt-llvm-s/tt-llvm-{download,patch,configure,build,install}.log \
  ./b/tt-p/tt-mlir-p/src/tt-mlir-s/tt-mlir-{download,patch,configure,build,install}.log \
  ./b/tt-p/tt-swift-p/src/tt-swift-s/tt-swift-{download,patch,configure,build,install}.log \
  ./b/tt-p/tt-tool_clang-p/src/tt-tool_clang-s/tt-tool_clang-{download,patch,configure,build,install}.log \
  ./b/tt-p/tt-tool_lld-p/src/tt-tool_lld-s/tt-tool_lld-{download,patch,configure,build,install}.log \
  2>/dev/null &
tail_pid=$!

cleanup() {
  kill $tail_pid
  popd
}
trap cleanup EXIT

ctest $@
