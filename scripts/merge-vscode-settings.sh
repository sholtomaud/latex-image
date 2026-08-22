#!/usr/bin/env bash
# merge-vscode-settings.sh
#
# Merges latex-workshop.* keys from .vscode/settings.json into VS Code's user
# settings, with a yes/no prompt first.
#
# VS Code profiles each keep their OWN settings.json and do NOT inherit the
# default profile's, so merging only into User/settings.json leaves every
# profiled window on LaTeX Workshop's built-in recipes. Every profile is
# therefore treated as a target; a profile with no settings.json yet gets one.
set -euo pipefail

CODE_USER="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS="${CODE_USER}/settings.json"
PROFILE_DIR="${CODE_USER}/profiles"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_SETTINGS="${REPO_DIR}/.vscode/settings.json"

if [[ ! -f "$VSCODE_SETTINGS" ]]; then
    echo "⚠️  Could not find VSCode settings at:"
    echo "   ${VSCODE_SETTINGS}"
    echo "   Open VSCode once to initialise it, then re-run: make install-vscode-settings"
    echo ""
    exit 1
fi

# Collect targets: the default profile, then each named profile.
TARGETS=("$VSCODE_SETTINGS")
if [[ -d "$PROFILE_DIR" ]]; then
    while IFS= read -r d; do
        [[ "$(basename "$d")" == "builtin" ]] && continue
        TARGETS+=("${d%/}/settings.json")
    done < <(find "$PROFILE_DIR" -mindepth 1 -maxdepth 1 -type d)
fi

echo ""
echo "⚙️  VSCode Settings"
echo "   This will merge all latex-workshop.* keys from:"
echo "   ${REPO_SETTINGS}"
echo "   into ${#TARGETS[@]} settings file(s):"
for t in "${TARGETS[@]}"; do
    if [[ -f "$t" ]]; then
        echo "     • ${t/#$HOME/~}"
    else
        echo "     • ${t/#$HOME/~}  (will be created)"
    fi
done
echo ""
read -r -p "   Proceed? [y/N] " answer
echo ""

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "⏭  Skipped VSCode settings merge."
    echo "   To apply later, run: make install-vscode-settings"
    echo ""
    exit 0
fi

python3 - "$REPO_SETTINGS" "${TARGETS[@]}" <<'EOF'
import json, os, sys

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

def load(path):
    if not os.path.exists(path):
        return {}
    with open(path) as f:
        text = strip_comments(f.read()).strip()
    return json.loads(text) if text else {}

repo_path, targets = sys.argv[1], sys.argv[2:]
repo = load(repo_path)
merged = {k: v for k, v in repo.items() if k.startswith('latex-workshop')}

for target in targets:
    settings = load(target)
    settings.update(merged)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, 'w') as f:
        json.dump(settings, f, indent=4)
    print(f"✅ Merged {len(merged)} latex-workshop keys into {target.replace(os.path.expanduser('~'), '~')}")

print("")
print("⚠️  Reload each open VSCode window (Cmd+Shift+P → 'Developer: Reload Window')")
print("   — settings are read at window startup.")
EOF
