# LaTeX Container

A persistent Apple container machine that provides LaTeX to any project folder — no per-project setup, no cold starts.

## Quickstart

**Prerequisites:** [Apple Container CLI](https://developer.apple.com/documentation/virtualization) and the [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) VSCode extension.

```bash
# 1. Clone this repo
git clone <your-repo-url> latex-image
cd latex-image

# 2. Build the machine image, create the persistent machine,
#    install wrapper scripts, set up auto-start, and configure VSCode
make install-all
#    (prompts for sudo to copy scripts to /usr/local/bin,
#     then asks whether to merge VSCode settings)
```

That's it. The machine starts automatically at each login. Open any `.tex` file in VSCode and hit **Build**.

---

## How it works

- One container machine (`ubuntu-latex`) holds the full TeX Live installation and runs persistently in the background.
- A set of small wrapper scripts live on your `$PATH`, one for each tool (`pdflatex-container`, `latexmk-container`, etc.).
- When LaTeX Workshop compiles a `.tex` file, it calls the wrapper script on your Mac.
- The script runs the tool inside the already-warm machine. Because the machine shares your macOS home directory at the same path, no mounting or path translation is needed.
- The PDF lands right next to your `.tex` file. No per-project config. No container cold starts.

```
~/projects/thesis/   →  machine compiles this  →  thesis.pdf appears here
~/projects/paper/    →  machine compiles this  →  paper.pdf appears here
```

The machine is started automatically at login via a launchd agent. The wrapper scripts also start it on demand if it isn't running, so you never need to manage it manually.

---

## Per-project usage

1. Open **any** folder in VSCode.
2. Write your `.tex` file.
3. Hit the LaTeX Workshop **Build** button (or `Cmd+Shift+P` → `LaTeX Workshop: Build with recipe`).
4. The PDF appears in the same folder.

The default recipe is `latexmk (full — biber + refs)`, which handles citations, cross-references, and TOC resolution automatically. For simple documents, switch recipes via `Cmd+Shift+P` → `LaTeX Workshop: Build with recipe`.

---

## VSCode settings

`make install-all` merges the latex-workshop settings into your global VSCode `settings.json` automatically. To run it separately at any time:

```bash
make install-vscode-settings
```

Or add the settings manually via `Cmd+Shift+P` → `Open User Settings (JSON)`:

```json
{
    "latex-workshop.view.pdf.viewer": "browser",
    "latex-workshop.latex.autoClean.run": "onBuilt",
    "latex-workshop.latex.clean.fileTypes": [
        "*.aux", "*.bbl", "*.blg", "*.log", "*.toc",
        "*.lof", "*.lot", "*.fls", "*.out",
        "*.fdb_latexmk", "*.synctex.gz"
    ],
    "latex-workshop.latex.tools": [
        {
            "name": "pdflatex-container",
            "command": "pdflatex-container",
            "args": ["-interaction=nonstopmode", "-file-line-error", "%DOCFILE%"]
        },
        {
            "name": "pdflatex-container-2",
            "command": "pdflatex-container",
            "args": ["-interaction=nonstopmode", "-file-line-error", "%DOCFILE%"]
        },
        {
            "name": "latexmk-container",
            "command": "latexmk-container",
            "args": ["%DOCFILE%"]
        }
    ],
    "latex-workshop.latex.recipes": [
        {
            "name": "latexmk (full — biber + refs)",
            "tools": ["latexmk-container"]
        },
        {
            "name": "pdflatex (single pass)",
            "tools": ["pdflatex-container"]
        },
        {
            "name": "pdflatex (two pass — TOC / refs)",
            "tools": ["pdflatex-container", "pdflatex-container-2"]
        }
    ],
    "latex-workshop.latex.recipe.default": "latexmk (full — biber + refs)",
    "latex-workshop.formatting.latex": "latexindent",
    "latex-workshop.formatting.latexindent.path": "latexindent-container"
}
```

---

## Updating LaTeX packages

Edit `Containerfile`, then rebuild and recreate the machine:

```bash
make machine-rm
make install-all
```

The wrapper scripts on your PATH don't need to change.

---

## Commands

| Command | What it does |
|---|---|
| `make install-all` | Full setup: build image, create machine, install wrappers, launchd agent, VSCode settings |
| `make machine-start` | Start the machine manually |
| `make machine-stop` | Stop the machine |
| `make machine-shell` | Open an interactive shell inside the machine |
| `make machine-rm` | Delete the machine and its filesystem |
| `make machine-build` | Rebuild the image (after editing `Containerfile`) |
| `make launchd-install` | Install the login auto-start agent |
| `make launchd-uninstall` | Remove the login auto-start agent |
| `make install-vscode-settings` | Merge latex-workshop settings into VSCode |
| `make check` | Verify machine is running and all tools work |
| `make uninstall` | Remove wrapper scripts, launchd agent, and machine |

---

## File layout

```
latex-image/
├── Containerfile                   # Machine image definition
├── Makefile                        # Setup and lifecycle automation
├── README.md
├── .vscode/
│   └── settings.json               # Reference VSCode settings (merged by make install-all)
└── scripts/
    ├── pdflatex-container.sh       # pdflatex wrapper → container machine run
    ├── latexmk-container.sh        # latexmk wrapper  → container machine run
    ├── pandoc-container.sh         # pandoc wrapper   → container machine run
    ├── latexindent-container.sh    # latexindent wrapper → container machine run
    ├── install-launchd.sh          # Installs the login auto-start launchd agent
    ├── uninstall-launchd.sh        # Removes the launchd agent
    └── merge-vscode-settings.sh    # Merges .vscode/settings.json into global VSCode settings
```
