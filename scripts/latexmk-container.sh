#!/usr/bin/env bash
# latexmk-container
#
# Drop-in replacement for latexmk that runs inside the ubuntu-latex
# container machine. Handles biber + multi-pass ref resolution automatically.
# The machine shares the macOS home directory at the same path, so no
# bind mount or path translation is needed.

set -euo pipefail

MACHINE_NAME="ubuntu-latex"

container machine start "${MACHINE_NAME}" 2>/dev/null || true

TEX_FILE="${!#}"
TEX_FILE="$(cd "$(dirname "$TEX_FILE")" && pwd)/$(basename "$TEX_FILE")"

cd "$(dirname "$TEX_FILE")"

run_latexmk() {
    container machine run \
        latexmk -pdf -bibtex -cd -interaction=nonstopmode -file-line-error \
        "$@" "${TEX_FILE}"
}

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

set +e
run_latexmk 2>&1 | tee "$LOG"
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
    run_latexmk -g
    exit $?
fi

exit "${status}"
