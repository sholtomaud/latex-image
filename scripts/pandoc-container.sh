#!/usr/bin/env bash
# pandoc-container.sh — run pandoc inside the ubuntu-latex container
set -euo pipefail

IMAGE_NAME="ubuntu-latex"

container system start >/dev/null 2>&1 || true

# Resolve the input file to an absolute host path
# Find the first argument that looks like a file (not a flag)
INPUT_FILE=""
OUTPUT_FILE=""
EXTRA_ARGS=()

for arg in "$@"; do
    if [[ "$arg" == "-o" ]]; then
        CAPTURING_OUTPUT=true
    elif [[ "${CAPTURING_OUTPUT:-false}" == "true" ]]; then
        OUTPUT_FILE="$arg"
        CAPTURING_OUTPUT=false
    elif [[ "$arg" != -* ]] && [[ -z "$INPUT_FILE" ]]; then
        INPUT_FILE="$(cd "$(dirname "$arg")" && pwd)/$(basename "$arg")"
    else
        EXTRA_ARGS+=("$arg")
    fi
done

HOST_DIR="$(dirname "$INPUT_FILE")"
INPUT_FILENAME="$(basename "$INPUT_FILE")"
CONTAINER_DIR="/workspace"

# Resolve output path — keep it in the same directory as input
if [[ -n "$OUTPUT_FILE" ]]; then
    OUTPUT_FILENAME="$(basename "$OUTPUT_FILE")"
else
    OUTPUT_FILENAME="${INPUT_FILENAME%.md}.pdf"
fi

container run \
    --rm \
    --mount "type=bind,source=${HOST_DIR},target=${CONTAINER_DIR}" \
    --cwd "${CONTAINER_DIR}" \
    "${IMAGE_NAME}" \
    pandoc "${CONTAINER_DIR}/${INPUT_FILENAME}" \
           -o "${CONTAINER_DIR}/${OUTPUT_FILENAME}" \
           "${EXTRA_ARGS[@]}"