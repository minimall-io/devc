#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "usage: devc init <repo>" >&2
  exit 1
fi

DEVC_HOME="${DEVC_HOME:-$(cd -P "$(dirname "$0")" && pwd)}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

REPO_NAME=$1
TARGET="${WORKSPACE_DIR}/${REPO_NAME}/Dockerfile"

if [ -e "$TARGET" ]; then
  echo "devc: $TARGET already exists" >&2
  exit 1
fi

cp "$DEVC_HOME/Dockerfile" "$TARGET"
echo "Created $TARGET"
