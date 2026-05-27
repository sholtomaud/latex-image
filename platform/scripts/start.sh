#!/usr/bin/env bash
# Container entrypoint — starts OpenVSCode Server, the optional MCP sidecar,
# and the PWA proxy server, then waits.
set -e

VSCODE_DIR=$(ls -d /opt/openvscode-server-* 2>/dev/null | head -1)
if [ -z "$VSCODE_DIR" ]; then
  echo "ERROR: openvscode-server not found in /opt" >&2
  exit 1
fi

# Resolve workspace directory.
# In ECS the WORKSPACE_REPO env var triggers a git clone; locally the project
# directory is volume-mounted at /workspace.
if [ -n "$WORKSPACE_REPO" ]; then
  CLONE_DIR="/workspace/$(basename "$WORKSPACE_REPO" .git)"
  if [ ! -d "$CLONE_DIR/.git" ]; then
    echo "Cloning $WORKSPACE_REPO → $CLONE_DIR"
    git clone "$WORKSPACE_REPO" "$CLONE_DIR"
  fi
  OPEN_DIR="$CLONE_DIR"
else
  OPEN_DIR="/workspace"
fi

cleanup() {
  kill "$VSCODE_PID" "$NODE_PID" "${MCP_PID:-}" 2>/dev/null || true
  wait 2>/dev/null || true
}
trap cleanup INT TERM EXIT

# OpenVSCode Server — bound to loopback; the PWA proxy is the only public face
"$VSCODE_DIR/bin/openvscode-server" \
  --host 127.0.0.1 \
  --port "${VSCODE_PORT:-7777}" \
  --without-connection-token \
  --extensions-dir /opt/vscode-extensions \
  --user-data-dir  /opt/vscode-data \
  --default-folder "$OPEN_DIR" &
VSCODE_PID=$!

# MCP filesystem server — started only when the script is present
if [ -f /app/mcp/filesystem-server.ts ]; then
  echo "Starting MCP filesystem server..."
  MCP_WORKSPACE="$OPEN_DIR" \
  node --experimental-strip-types /app/mcp/filesystem-server.ts &
  MCP_PID=$!
fi

# PWA proxy server (Node 25)
# --experimental-strip-types lets Node run the .ts file directly without tsc
node --experimental-strip-types /app/pwa-server.ts &
NODE_PID=$!

echo "IDE ready → http://localhost:${PORT:-5173}"

wait "$NODE_PID"
