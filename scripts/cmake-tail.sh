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
  ./b/sc-p/src/sc-s/sc-{download,patch,configure,build,install}.log \
  ./b/s-p/src/s-s/s-{download,patch,configure,build,install}.log \
  ./b/lp-p/src/lp-s/lp-{download,patch,configure,build,install}.log \
  ./b/tlp-host-p/src/tlp-host-s/tlp-host-{download,patch,configure,build,install}.log \
  ./b/tlp-p/src/tlp-s/tlp-{download,patch,configure,build,install}.log \
  ./b/tp-p/src/tp-s/tp-{download,patch,configure,build,install}.log \
  ./b/tep-p/src/tep-s/tep-{download,patch,configure,build,install}.log \
  2>/dev/null &
tail_pid=$!

cleanup() {
  kill $tail_pid
  popd
}
trap cleanup EXIT

cmake $@
