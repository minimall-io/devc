#!/bin/bash
set -e

if [ -z "$1" ]; then
  container image rm -af
  exit 0
fi

WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"

REPO_NAME=$1

container image rm ${REPO_NAME} 2>/dev/null || true
container build --no-cache \
  -t $REPO_NAME \
  --cpus 4 \
  --memory 12g \
  -f ${WORKSPACE_DIR}/${REPO_NAME}/Dockerfile \
  ${WORKSPACE_DIR}/${REPO_NAME}
