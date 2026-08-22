#!/usr/bin/env bash
# pdflatex-container
#
# Drop-in replacement for pdflatex that runs inside the ubuntu-latex container
# machine. The machine shares the macOS home directory at the same path, so
# arguments need no path translation -- only the working directory has to be
# carried across, which `container machine run -w` does.
#
# Transparent proxy: the argument list is passed through untouched, so
# `pdflatex --version` (LaTeX Workshop runs one to detect MiKTeX) and every
# caller-supplied flag behave exactly as the real binary would. Like the real
# pdflatex, output lands in the current directory, not beside the input file.

set -euo pipefail

MACHINE_NAME="ubuntu-latex"

# VS Code spawns build tools with a minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin),
# which does not include /usr/local/bin, so `container` has to be located by
# absolute path rather than looked up on PATH.
CONTAINER_BIN="${CONTAINER_BIN:-/usr/local/bin/container}"
[ -x "${CONTAINER_BIN}" ] || CONTAINER_BIN="$(command -v container || true)"
[ -n "${CONTAINER_BIN}" ] || {
    echo "pdflatex-container: cannot find the 'container' CLI (looked in /usr/local/bin and on PATH)." >&2
    exit 127
}

# `container machine run` boots the machine on demand; there is no `machine start`.

exec "${CONTAINER_BIN}" machine run -n "${MACHINE_NAME}" -w "${PWD}" pdflatex "$@"
