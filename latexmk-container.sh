#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="ubuntu-latex"

container system start 2>/dev/null || true

TEX_FILE_HOST="${!#}"
TEX_FILE_HOST="$(cd "$(dirname "$TEX_FILE_HOST")" && pwd)/$(basename "$TEX_FILE_HOST")"

HOST_DIR="$(dirname "$TEX_FILE_HOST")"
TEX_FILENAME="$(basename "$TEX_FILE_HOST")"
CONTAINER_DIR="/workspace"

container run \
    --rm \
    --mount "type=bind,source=${HOST_DIR},target=${CONTAINER_DIR}" \
    --cwd "${CONTAINER_DIR}" \
    "${IMAGE_NAME}" \
    latexmk -pdf -bibtex -interaction=nonstopmode -file-line-error "${CONTAINER_DIR}/${TEX_FILENAME}"