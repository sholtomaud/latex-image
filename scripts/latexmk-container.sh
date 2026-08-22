#!/usr/bin/env bash
# latexmk-container
#
# Drop-in replacement for latexmk that runs inside the ubuntu-latex container
# machine. The machine shares the macOS home directory at the same path, so
# arguments need no path translation -- only the working directory has to be
# carried across, which `container machine run -w` does.
#
# The wrapper is a transparent proxy: it never inspects or rewrites the
# argument list. Build flags belong to the caller (see latex-workshop.latex.tools
# in .vscode/settings.json), so probes like `latexmk --version` -- LaTeX
# Workshop runs one to detect MiKTeX -- pass straight through.

set -euo pipefail

MACHINE_NAME="ubuntu-latex"

# VS Code spawns build tools with a minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin),
# which does not include /usr/local/bin, so `container` has to be located by
# absolute path rather than looked up on PATH.
CONTAINER_BIN="${CONTAINER_BIN:-/usr/local/bin/container}"
[ -x "${CONTAINER_BIN}" ] || CONTAINER_BIN="$(command -v container || true)"
[ -n "${CONTAINER_BIN}" ] || {
    echo "latexmk-container: cannot find the 'container' CLI (looked in /usr/local/bin and on PATH)." >&2
    exit 127
}

# `container machine run` boots the machine on demand; there is no `machine start`.

run_latexmk() {
    "${CONTAINER_BIN}" machine run -n "${MACHINE_NAME}" -w "${PWD}" latexmk "$@"
}

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

set +e
run_latexmk "$@" 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}
set -e

# latexmk records a failed run in .fdb_latexmk. If no source file has changed
# since, it declines to retry and replays the stored error instead of building
# ("Nothing to do" + "gave an error in previous invocation of latexmk"). That
# is a dead end whenever the failure was transient rather than a source defect
# -- a stale .aux, say, which one clean pass would have cured -- because the
# fix that clears it never changes a source file, so latexmk never reruns.
# Force one full pass to break out of it.
if [ "${status}" -ne 0 ] && grep -q "error in previous invocation of latexmk" "${LOG}"; then
    echo "latexmk-container: stale failure in .fdb_latexmk; forcing a full rebuild." >&2
    run_latexmk -g "$@"
    exit $?
fi

exit "${status}"
