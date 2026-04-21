# LaTeX Container

A single Apple Container CLI image that provides LaTeX to any project folder — no per-project setup required.

## How it works

- One Docker image (`ubuntu-latex`) holds the full LaTeX installation.
- A set of small wrapper scripts live on your `$PATH`, one for each tool.
- When VSCode LaTeX Workshop compiles a `.tex` file, it calls the appropriate wrapper script.
- The script spins up a throwaway container, mounts **only that project's folder**, runs the tool, and exits.
- The PDF lands right next to your `.tex` file, on the host. No persistent container. No cleanup. No per-project config.

```
~/projects/thesis/   →  container mounts this  →  thesis.pdf appears here
~/projects/paper/    →  container mounts this  →  paper.pdf appears here
```

## First-time setup

```bash
# 1. Clone this repo
git clone <your-repo-url> latex-container
cd latex-container

# 2. Build the image, install all wrapper scripts, and optionally
#    merge the latex-workshop settings into your global VSCode settings
make install-all
# This will prompt for your sudo password to copy scripts to /usr/local/bin,
# then ask whether to merge the VSCode settings automatically.
```

That's it. You never need to touch this repo again unless you want to update the LaTeX installation.

## Per-project usage

1. Open **any** folder in VSCode.
2. Write your `.tex` file.
3. Hit the LaTeX Workshop **Build** button (or `Cmd+Shift+P` → `LaTeX Workshop: Build with recipe`).
4. The PDF appears in the same folder.

The default recipe is `latexmk (full — biber + refs)`, which handles citations, cross-references, and TOC resolution automatically. For simple documents you can switch to a `pdflatex` recipe via `Cmd+Shift+P` → `LaTeX Workshop: Build with recipe`.

### VSCode settings

If you chose to merge settings during `make install-all`, your global VSCode `settings.json` is already configured. If you skipped it, you can run it any time:

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
            "name": "pdflatex (single pass)",
            "tools": ["pdflatex-container"]
        },
        {
            "name": "pdflatex (two pass — TOC / refs)",
            "tools": ["pdflatex-container", "pdflatex-container-2"]
        },
        {
            "name": "latexmk (full — biber + refs)",
            "tools": ["latexmk-container"]
        }
    ],
    "latex-workshop.latex.recipe.default": "latexmk (full — biber + refs)",
    "latex-workshop.formatting.latex": "latexindent",
    "latex-workshop.formatting.latexindent.path": "latexindent-container"
}
```

## Updating LaTeX packages

Edit the `Dockerfile`, then:

```bash
make build
# (no need to re-run make install-all — the scripts on PATH stay the same)
```

## Commands

| Command | What it does |
|---|---|
| `make build` | Build the image |
| `make install` | Build + install `pdflatex-container` wrapper |
| `make install-latexmk` | Build + install `latexmk-container` wrapper |
| `make install-pandoc` | Build + install `pandoc-container` wrapper |
| `make install-latexindent` | Build + install `latexindent-container` wrapper |
| `make install-vscode-settings` | Merge latex-workshop settings into global VSCode settings |
| `make install-all` | All of the above |
| `make uninstall` | Remove all wrapper scripts from `/usr/local/bin` |
| `make check` | Verify all tools work inside the image |
| `make clean-images` | Delete the built image |

## File layout

```
latex-container/
├── Dockerfile              # LaTeX image definition
├── Makefile                # Build + install automation
├── README.md
├── .vscode/
│   └── settings.json       # Reference VSCode settings (also merged by make install-all)
└── scripts/
    ├── pdflatex-container.sh       # Drop-in pdflatex wrapper
    ├── latexmk-container.sh        # Drop-in latexmk wrapper (biber + full refs)
    ├── pandoc-container.sh         # Drop-in pandoc wrapper
    ├── latexindent-container.sh    # Drop-in latexindent wrapper (formatting)
    └── merge-vscode-settings.sh    # Merges .vscode/settings.json into global VSCode settings
```