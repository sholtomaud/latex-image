#!/usr/bin/env bash
# Install a launchd agent that starts the latex container machine at login.
set -euo pipefail

MACHINE_NAME="${1:-ubuntu-latex}"
CONTAINER_BIN="$(which container)"
LABEL="com.$(whoami).latex-machine"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="${PLIST_DIR}/${LABEL}.plist"

mkdir -p "${PLIST_DIR}"

cat > "${PLIST_PATH}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>${CONTAINER_BIN} system start &amp;&amp; ${CONTAINER_BIN} machine run -n ${MACHINE_NAME} true</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/latex-machine.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/latex-machine-error.log</string>
</dict>
</plist>
EOF

launchctl unload "${PLIST_PATH}" 2>/dev/null || true
launchctl load "${PLIST_PATH}"
echo "launchd agent installed: ${PLIST_PATH}"
echo "The machine will start automatically at each login."
