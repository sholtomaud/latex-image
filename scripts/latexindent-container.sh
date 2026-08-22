#!/usr/bin/env bash
# latexindent-container
#
# Runs latexindent inside the ubuntu-latex container machine. The machine
# shares the macOS home directory at the same path, so the paths LaTeX
# Workshop passes work unchanged; only the working directory is carried
# across, via `container machine run -w`.
#
# Transparent proxy -- see latexmk-container.sh for the rationale.

set -euo pipefail

MACHINE_NAME="ubuntu-latex"

# VS Code spawns build tools with a minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin),
# which does not include /usr/local/bin, so `container` has to be located by
# absolute path rather than looked up on PATH.
CONTAINER_BIN="${CONTAINER_BIN:-/usr/local/bin/container}"
[ -x "${CONTAINER_BIN}" ] || CONTAINER_BIN="$(command -v container || true)"
[ -n "${CONTAINER_BIN}" ] || {
    echo "latexindent-container: cannot find the 'container' CLI (looked in /usr/local/bin and on PATH)." >&2
    exit 127
}

# `container machine run` boots the machine on demand; there is no `machine start`.

exec "${CONTAINER_BIN}" machine run -n "${MACHINE_NAME}" -w "${PWD}" latexindent "$@"
