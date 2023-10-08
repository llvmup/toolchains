#!/bin/bash

GITHUB_REF_REGEX="refs/heads/releases/((llvmorg-[0-9]+)\.[0-9]+\.[0-9]+|(swift-[0-9]+\.[0-9]+)(\.[0-9]+)?)"

# Function for exiting the job early.
function github_exit {
  gh run cancel ${GITHUB_RUN_ID}
  gh run watch  ${GITHUB_RUN_ID}
}

# NOTE:
#   - RELEASE_TAG: the variant, plus full version, plus revision
#   - RELEASE_KEY: the variant, plus major version (llvmorg) or major.minor version (swift)

# Extract the release tag and key from a "push" or "pull_request" action or exit early.
function extract_tag_and_key_strings {
  if [[ ${GITHUB_EVENT_NAME} == $1 ]]; then
    # If the regex matches the ref, extract the tag and key information.
    if [[ $2 =~ ${GITHUB_REF_REGEX} ]]; then
      TOOLCHAINS_RELEASE_REF=${BASH_REMATCH[0]}
      TOOLCHAINS_RELEASE_BRANCH=${BASH_REMATCH[1]}
      TOOLCHAINS_RELEASE_KEY=$([[ ! -z "${BASH_REMATCH[2]}" ]] && echo ${BASH_REMATCH[2]} || echo ${BASH_REMATCH[3]})

      TOOLCHAINS_RELEASE_TAG_LAST=$(git tag --list | grep "^${TOOLCHAINS_RELEASE_BRANCH}" | sort --reverse | head --lines=1 || true)
      if [[ ${TOOLCHAINS_RELEASE_TAG_LAST} =~ ${TOOLCHAINS_RELEASE_BRANCH}\+rev([0-9]+) ]]; then
        let TOOLCHAINS_RELEASE_REV="1 + ${BASH_REMATCH[1]}"
      else
        TOOLCHAINS_RELEASE_REV=0
      fi

      echo TOOLCHAINS_RELEASE_BRANCH=${TOOLCHAINS_RELEASE_BRANCH}
      echo TOOLCHAINS_RELEASE_KEY=${TOOLCHAINS_RELEASE_KEY}
      echo TOOLCHAINS_RELEASE_REV=${TOOLCHAINS_RELEASE_REV}

      echo TOOLCHAINS_RELEASE_BRANCH=${TOOLCHAINS_RELEASE_BRANCH} >> $GITHUB_ENV
      echo TOOLCHAINS_RELEASE_KEY=${TOOLCHAINS_RELEASE_KEY} >> $GITHUB_ENV
      echo TOOLCHAINS_RELEASE_REV=${TOOLCHAINS_RELEASE_REV} >> $GITHUB_ENV
    fi
  fi
}

extract_tag_and_key_strings "push" ${GITHUB_REF}
extract_tag_and_key_strings "pull_request" ${GITHUB_BASE_REF}

# Exit if there were no regex matches from earlier.
if [[ -z "${TOOLCHAINS_RELEASE_REF}" ]]; then
  github_exit
fi
