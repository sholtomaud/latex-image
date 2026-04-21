#!/usr/bin/env bash
# latexindent-container — run latexindent inside the ubuntu-latex container
set -euo pipefail

IMAGE_NAME="ubuntu-latex"

container system start >/dev/null 2>&1 || true

if [ "$#" -lt 1 ]; then
    echo "Usage: latexindent-container [flags] /path/to/file.tex" >&2
    exit 1
fi

# Find the .tex file — it may not be the last arg
TEX_FILE_HOST=""
OTHER_ARGS=()
SKIP_NEXT=false

for arg in "$@"; do
    if [[ "$SKIP_NEXT" == "true" ]]; then
        # This is the value after -c — translate host path to container path
        OTHER_ARGS+=("/workspace/")
        SKIP_NEXT=false
    elif [[ "$arg" == "-c" ]]; then
        OTHER_ARGS+=("-c")
        SKIP_NEXT=true
    elif [[ "$arg" == *.tex ]] && [[ -z "$TEX_FILE_HOST" ]]; then
        TEX_FILE_HOST="$arg"
    else
        OTHER_ARGS+=("$arg")
    fi
done

if [[ -z "$TEX_FILE_HOST" ]]; then
    echo "Error: no .tex file found in arguments" >&2
    exit 1
fi

TEX_FILE_HOST="$(cd "$(dirname "$TEX_FILE_HOST")" && pwd)/$(basename "$TEX_FILE_HOST")"
HOST_DIR="$(dirname "$TEX_FILE_HOST")"
TEX_FILENAME="$(basename "$TEX_FILE_HOST")"
CONTAINER_DIR="/workspace"

container run \
    --rm \
    --mount "type=bind,source=${HOST_DIR},target=${CONTAINER_DIR}" \
    --cwd "${CONTAINER_DIR}" \
    "${IMAGE_NAME}" \
    latexindent "${OTHER_ARGS[@]}" "${CONTAINER_DIR}/${TEX_FILENAME}"