#!/usr/bin/env bash
# Remove the launchd agent that auto-starts the latex container machine.
set -euo pipefail

LABEL="com.$(whoami).latex-machine"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"

launchctl unload "${PLIST_PATH}" 2>/dev/null || true
rm -f "${PLIST_PATH}"
echo "launchd agent removed."
