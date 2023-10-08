#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -x

if command -v uname > /dev/null 2>&1; then
  if [[ "$(uname -s)" == "Linux" ]]; then
    case $(uname -m) in
      aarch64|arm64)
        echo "ERROR: This script does not support Linux on ARM64. Try 'apt-install-deps.sh' instead."
        exit 1
        ;;
    esac
  fi
else
  echo "Cannot find 'uname' command. Exiting."
fi

brew install ccache cmake ninja llvm@17 || true
