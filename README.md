# LaTeX Container

A single Apple Container CLI image that provides LaTeX to any project folder — no per-project setup required.

## How it works

- One Docker image (`al23-latex`) holds the full LaTeX installation.
- A small wrapper script (`pdflatex-container`) lives on your `$PATH`.
- When VSCode LaTeX Workshop compiles a `.tex` file, it calls the wrapper script.
- The script spins up a throwaway container, mounts **only that project's folder**, runs `pdflatex`, and exits.
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

# 2. Build the image and install the wrapper script
make install
# This will prompt for your sudo password to copy the script to /usr/local/bin
```

That's it. You never need to touch this repo again unless you want to update the LaTeX installation.

## Per-project usage

1. Open **any** folder in VSCode.
2. Write your `.tex` file.
3. Hit the LaTeX Workshop **Build** button (or `Cmd+Shift+P` → `LaTeX Workshop: Build with recipe`).
4. The PDF appears in the same folder.

The `.vscode/settings.json` in this repo is only for the container repo itself. For your LaTeX projects, add the settings below to your **user** `settings.json` (`Cmd+Shift+P` → `Open User Settings (JSON)`):

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
        }
    ],
    "latex-workshop.latex.recipe.default": "pdflatex (two pass — TOC / refs)"
}
```

## Updating LaTeX packages

Edit the `Dockerfile`, then:

```bash
make build
# (no need to re-run make install — the script on PATH stays the same)
```

## Commands

| Command | What it does |
|---|---|
| `make build` | Build the image |
| `make install` | Build + install wrapper script to `/usr/local/bin` |
| `make uninstall` | Remove the wrapper script |
| `make check` | Verify pdflatex works inside the image |
| `make clean-images` | Delete the built image |

## File layout

```
latex-container/
├── Dockerfile              # LaTeX image definition
├── Makefile                # Build + install automation
├── pdflatex-container.sh   # Wrapper script (installed to /usr/local/bin)
├── .vscode/
│   └── settings.json       # Reference VSCode settings
└── README.md
```
