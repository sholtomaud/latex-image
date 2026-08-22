# Requirements — LaTeX Image Platform

## Architecture Overview

Two deployment modes share a single image chain:

```
ubuntu-latex                     (root Containerfile)
  LaTeX toolchain only.
  Used directly by desktop VS Code via wrapper scripts.
       │
       ▼
openvscode-base                  (platform/Containerfile.base)
  + Node.js 25, OpenVSCode Server, custom extensions, PWA proxy.
       │
       ▼
openvscode-latex                 (platform/templates/latex/Containerfile)
  + LaTeX Workshop, PDF viewer.
  Used by the browser PWA and cloud deployments.
```

### Mode 1 — Local / Desktop VS Code

The `ubuntu-latex` image provides the LaTeX toolchain to desktop VS Code via
thin wrapper scripts (`pdflatex-container`, `latexmk-container`, etc.) installed
to `/usr/local/bin`. LaTeX Workshop calls these wrappers as if they were native
binaries. Each compile runs the tool inside a persistent container machine
(`ubuntu-latex`) that shares the macOS home directory at the same path, so no
mounting or path translation is needed.

The machine is started at login by a launchd agent, and `container machine run`
boots it on demand if it is not already up.

Setup: `make install-all` (in repo root) — builds the image and installs all
wrapper scripts and VS Code settings.

### Mode 2 — Platform / Browser PWA

The `openvscode-latex` image (built in `platform/`) runs a full OpenVSCode
Server IDE served as a Progressive Web App. Started per-project via `make run`
in `platform/`. Can be deployed to cloud (Hetzner, etc.) or run locally.

Custom extensions (Project Status, Project Dashboard, Studio Deep) are baked
into `openvscode-base` at build time. No marketplace access required at runtime.

Setup: `make build` in `platform/`, then `make run [DIR=<project>]`.

---

## Build Order

The two parts must be built in order — `openvscode-base` inherits from
`ubuntu-latex`:

```sh
# 1. Build the shared LaTeX base (repo root)
make build

# 2. Build the platform images (platform/)
cd platform && make build
```

---

## Functional Requirements

### 1. Local / Desktop VS Code Mode

**FR-1.1** LaTeX Workshop in desktop VS Code shall compile documents using tools
running inside the `ubuntu-latex` container, with no LaTeX installation on the
host.

**FR-1.2** Wrapper scripts shall be drop-in replacements for `pdflatex`,
`latexmk`, `pandoc`, and `latexindent`. LaTeX Workshop configuration shall
require no per-project setup beyond running `make install-all` once.

**FR-1.3** Each tool invocation shall run inside the persistent `ubuntu-latex`
container machine, which shares the macOS home directory at the same path.
Wrapper scripts shall forward their argument list verbatim and carry only the
working directory across, so no path translation is required.

**FR-1.4** The container machine shall be started at login by a launchd agent.
Wrapper scripts shall not manage machine lifecycle; `container machine run`
boots the machine on demand.

**FR-1.5** Wrapper scripts shall resolve the `container` CLI by absolute path.
VS Code launched from Finder gives spawned tools a minimal PATH that excludes
`/usr/local/bin`.

**FR-1.5** A `make install-all` target (in repo root) shall build the image,
install all wrapper scripts, and merge LaTeX Workshop settings into the user's
VS Code `settings.json`.

---

### 2. Platform / Browser PWA Mode

**FR-2.1** A developer shall be able to open a project for editing with a single
command: `cd <project-dir> && edit`

**FR-2.2** If a container for that project is already running, `edit` shall
reconnect to it (open the URL) rather than start a duplicate.

**FR-2.3** If no container is running, `edit` shall start one and open the
browser immediately with a loading state until the IDE is ready.

**FR-2.4** The project directory shall be mounted as `/workspace`. Files edited
in the IDE are written directly to the host filesystem.

**FR-2.5** The same project directory shall always bind to the same port across
container restarts (deterministic port from path hash).

**FR-2.6** The platform shall be deployable to cloud Linux hosts (e.g. Hetzner)
without modification.

---

### 3. Shared Image Requirements

**FR-3.1** The LaTeX toolchain (TeX Live, latexmk, biber, pandoc) shall be
defined exactly once, in the root `Containerfile` (`ubuntu-latex`).

**FR-3.2** `openvscode-base` shall inherit `FROM ubuntu-latex` so both modes
use an identical LaTeX stack.

**FR-3.3** Tool versions shall be pinned. The TeX Live set installed in
`ubuntu-latex` shall match what is tested in CI.

---

### 4. Project Templates

**FR-4.1** Each project directory may contain a `.vscode-template` file. If
absent, the default template is `latex`.

**FR-4.2** Each template image adds only the VS Code extensions and settings
specific to that file type. The LaTeX stack comes from the inherited base.

**FR-4.3** Templates currently implemented:
- **latex** — LaTeX Workshop, PDF viewer, latexmk recipes, synctex

**FR-4.4** Adding a template requires only: a `Containerfile` in
`platform/templates/<name>/` and a `build-<name>` target in the platform
Makefile.

---

### 5. Custom Extensions (Platform Mode)

**FR-5.1 Project Status** — Status bar shows the active project template type.

**FR-5.2 Project Dashboard** — Panel shows word count, file count, build
history charts, and per-file stats. Implemented as native web components.

**FR-5.3 Studio Deep** — AI writing co-creator using Google Gemini. Sidebar
navigation, typeahead outlet discovery backed by structured Gemini output and
local SQLite cache.

**FR-5.4** All custom extensions are compiled and packaged during `make
build-base`. No marketplace access required at runtime.

---

### 6. Developer Workflow

**FR-6.1** Make targets (repo root):

| Target | Action |
|---|---|
| `make build` | Build `ubuntu-latex` (local mode base) |
| `make install-all` | Build + install all wrapper scripts + VS Code settings |
| `make check` | Smoke-test all tools inside the image |
| `make uninstall` | Remove wrapper scripts |

**FR-6.2** Make targets (`platform/`):

| Target | Action |
|---|---|
| `make build` | Build `openvscode-base` + `openvscode-latex` |
| `make run [DIR=<path>]` | Start editor container for a project |
| `make dev` | Hot-swap all extensions into the running container |
| `make stop` | Stop the running container |
| `make logs` | Tail container logs |
| `make install` | Install the `edit` command to `/usr/local/bin` |

**FR-6.3** `make dev` (platform) enables extension iteration without a full
image rebuild by copying source into the running container, compiling with the
container's Node.js, and installing the resulting `.vsix`.

---

## Technical Constraints

- **Container runtime:** Apple Container CLI (`container`). macOS only.
- **Container OS:** Ubuntu 24.04 (shared across both modes).
- **Node.js:** 25.x (pinned), installed from official tarball.
- **OpenVSCode Server:** gitpod fork, pinned version.
- **Extension registry:** Open VSX for platform extensions. Desktop VS Code
  uses the Microsoft Marketplace for its own extensions (LaTeX Workshop).
- **Port range:** 49152–65533, derived from project path hash.
