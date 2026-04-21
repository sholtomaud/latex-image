#!/usr/bin/env bash
# merge-vscode-settings.sh
# Merges latex-workshop.* keys from .vscode/settings.json into the
# global VSCode user settings.json, with a yes/no prompt first.
set -euo pipefail

VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_SETTINGS="${REPO_DIR}/.vscode/settings.json"

echo ""
echo "⚙️  VSCode Settings"
echo "   This will merge all latex-workshop.* keys from:"
echo "   ${REPO_SETTINGS}"
echo "   into:"
echo "   ${VSCODE_SETTINGS}"
echo ""
read -r -p "   Proceed? [y/N] " answer
echo ""

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "⏭  Skipped VSCode settings merge."
    echo "   To apply later, run: make install-vscode-settings"
    echo ""
    exit 0
fi

if [[ ! -f "$VSCODE_SETTINGS" ]]; then
    echo "⚠️  Could not find VSCode settings at:"
    echo "   ${VSCODE_SETTINGS}"
    echo "   Open VSCode once to initialise it, then re-run: make install-vscode-settings"
    echo ""
    exit 1
fi

python3 - "$VSCODE_SETTINGS" "$REPO_SETTINGS" <<'EOF'
import json, sys

def strip_comments(src):
    """Strip // and /* */ comments without touching string contents."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        # String — copy verbatim until closing unescaped quote
        if src[i] == '"':
            out.append(src[i])
            i += 1
            while i < n:
                if src[i] == '\\' and i + 1 < n:
                    out.append(src[i:i+2])
                    i += 2
                    continue
                if src[i] == '"':
                    out.append(src[i])
                    i += 1
                    break
                out.append(src[i])
                i += 1
        # Line comment
        elif src[i] == '/' and i + 1 < n and src[i+1] == '/':
            while i < n and src[i] != '\n':
                i += 1
        # Block comment
        elif src[i] == '/' and i + 1 < n and src[i+1] == '*':
            i += 2
            while i < n and not (src[i] == '*' and i + 1 < n and src[i+1] == '/'):
                i += 1
            i += 2
        else:
            out.append(src[i])
            i += 1
    return ''.join(out)

user_path, repo_path = sys.argv[1], sys.argv[2]

with open(user_path) as f:
    user = json.loads(strip_comments(f.read()))

with open(repo_path) as f:
    repo = json.loads(strip_comments(f.read()))

merged = {k: v for k, v in repo.items() if k.startswith('latex-workshop')}
user.update(merged)

with open(user_path, 'w') as f:
    json.dump(user, f, indent=4)

print(f"✅ Merged {len(merged)} latex-workshop keys into VSCode user settings.")
EOF