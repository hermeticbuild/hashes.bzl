#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG=$1
PREFIX="hashes.bzl-${TAG:1}"
ARCHIVE="hashes.bzl-$TAG.tar.gz"

git archive --format=tar --prefix="${PREFIX}/" "${TAG}" | gzip > "${ARCHIVE}"

cat << EOF
## Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "hashes.bzl", version = "${TAG:1}")
\`\`\`

EOF
