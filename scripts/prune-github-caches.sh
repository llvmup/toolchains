#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -x

GITHUB_OWNER=llvmup
GITHUB_REPO=toolchains

# NOTE: the leading `/` for the endpoints must be omitted, otherwise the script fails on Windows
gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-Github-Api-Version: 2022-11-28" \
    "repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/caches" \
  | jq ".actions_caches[] | select(.key | test(\"${TARGET_TRIPLE_ARCH}-${TARGET_TRIPLE_SYS}-${TOOLCHAINS_RELEASE_KEY}-(?!${GITHUB_RUN_ID})[0-9]+\"))" \
  | jq -r '.id' \
  | sed 's/[\r\n]*$//' \
  | xargs -I{CACHE_ID} \
      gh api \
        --method DELETE \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/caches/{CACHE_ID}"
