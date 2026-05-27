# Requirements — OpenVSCode Platform

## Design Intent

A local-first PWA. The goal is a single shell command — `edit` — that opens a browser-based IDE pre-configured for the current project's file type, with all tooling baked in. No marketplace downloads at runtime, no manual extension configuration, no per-project setup beyond a single template marker file.

For local deployment, the platform uses Apple Container CLI to run per-project Linux containers. Each container serves a full OpenVSCode Server IDE as a Progressive Web App. Different project types---LaTeX documents (Latex runtime), screenplays (Fountain), formal logic (Lean)---use different container images that pre-install the correct language tools and editor extensions.

---

## Functional Requirements

### 1. Workflow

**FR-1.1** A developer shall be able to open a project for editing with a single command: `cd <project-dir> && edit`

**FR-1.2** If a container for that project is already running, `edit` shall reconnect to it (open the URL) rather than start a duplicate.

**FR-1.3** If no container is running, `edit` shall start one and open the browser immediately. The browser shall display a loading state until the IDE is ready; it shall not show an error page.

**FR-1.4** The project directory shall be mounted into the container as `/workspace`. Files edited in the IDE are written directly to the host filesystem. No sync step is required.

**FR-1.5** Stopping a container (`make stop` or `container stop <name>`) shall be the only required cleanup. No data is lost — the project files remain on the host.

**FR-1.6** The same project directory shall always bind to the same port across container restarts. Port assignment shall be derived deterministically from the absolute project path.

---

### 2. Project Templates

**FR-2.1** Each project directory shall contain a `.vscode-template` file with a single word identifying its type (e.g. `latex`, `fountain`). If absent, the default template is `latex`.

**FR-2.2** The `edit` command shall read `.vscode-template` and start the corresponding container image (e.g. `openvscode-latex`, `openvscode-fountain`).

**FR-2.3** Each template image shall pre-install all required system tools, language runtimes, and editor extensions for that project type. No internet access shall be required at container runtime for core functionality.

**FR-2.4** Templates currently required:
- **latex** — full TeX Live stack, LaTeX Workshop extension, PDF viewer
- **fountain** — Fountain screenplay support (pending Open VSX availability)

**FR-2.5** Adding a new template shall require only: a `Containerfile` in `platform/templates/<name>/`, an optional `settings.json`, and a `build-<name>` target in the Makefile.

---

### 3. Container Images

**FR-3.1** All template images shall share a common base image (`openvscode-base`) containing: Ubuntu 24.04, Node.js 25, OpenVSCode Server, the PWA proxy server, the MCP sidecar, and all custom extensions.

**FR-3.2** Custom extensions shall be compiled and packaged during the image build. No extension shall be downloaded from any marketplace at runtime.

**FR-3.3** Extensions sourced from Open VSX shall be installed during image build only.

**FR-3.4** The base image build shall be reproducible. Tool versions (OpenVSCode Server, Node.js) shall be pinned as Makefile variables.

---

### 4. IDE & Browser Experience

**FR-4.1** The IDE shall be served as a Progressive Web App. It shall be installable from the browser address bar as a standalone macOS app.

**FR-4.2** The IDE shall open in the browser immediately after `edit` is run. A loading splash screen shall be shown while the container initialises; the browser shall not navigate to an error page.

**FR-4.3** The PWA proxy server (`pwa-server.ts`) shall reverse-proxy all requests to OpenVSCode Server, serving only the PWA shell files (`manifest.json`, `sw.js`) statically.

**FR-4.4** The proxy shall serve workspace files (PDFs, images, assets) at `/workspace-files/<path>`, enabling browser-native rendering without routing through OpenVSCode's internal resource port.

**FR-4.5** The IDE shall shut down automatically after a configurable idle period (default: 30 minutes of no HTTP activity).

---

### 5. Custom Extensions

**FR-5.1 Project Status** — A status bar item shall display the active project template type (read from `.vscode-template`) with a matching icon. It shall update if the file is saved while the IDE is open.

**FR-5.2 Project Dashboard** — A dashboard panel shall be accessible from the status bar. It shall display:
- Metric cards: total word count, file count, line count, build log count
- Bar chart: word count per top-level section or folder
- Line chart: build duration history with pass/fail status per run
- Data table: per-file word and line counts

**FR-5.3** The dashboard UI shall follow the **Fluent Professional** design system specified in `platform/extensions/project-dashboard/DESIGN.md`: light theme, Inter typography, deep-blue primary colour, 4px base spacing grid, white card surfaces with `#EDEBE9` borders.

**FR-5.4** Dashboard UI components shall be implemented as **native web components** (Custom Elements API). No frontend framework (React, Vue, etc.) shall be used.

**FR-5.5 PDF Viewer** — A "View PDF" status bar button shall open the compiled PDF in a new browser tab via the `/workspace-files/` route. If multiple PDFs exist in the workspace, a quick-pick list shall be shown.

---

### 6. Build & Developer Workflow

**FR-6.1** The following `make` targets shall be available from `platform/`:

| Target | Action |
|---|---|
| `make start` | Start the Apple Container system daemon |
| `make build` | Build all images (base + all templates) |
| `make build-base` | Build the shared base image only |
| `make build-<template>` | Build a specific template image |
| `make run [DIR=<path>]` | Start a container for a project directory |
| `make stop [DIR=<path>]` | Stop the container for a project directory |
| `make logs [DIR=<path>]` | Tail container logs |
| `make dev-ext [EXT=<name>] [DIR=<path>]` | Hot-swap an extension into a running container |
| `make install` | Install the `edit` command to `/usr/local/bin` |
| `make check` | Smoke-test the built images |

**FR-6.2** `make build` with no source changes shall complete significantly faster than a clean build, due to container layer caching.

**FR-6.3** `make dev-ext` shall enable extension iteration without a full image rebuild. It shall: copy extension source into the running container via the mounted workspace volume, compile it using the container's Node.js, install the resulting `.vsix`, and clean up. The developer shall then reload the VS Code window.

**FR-6.4** The `edit` command shall be a standalone shell script installable to any directory on `$PATH`. It shall have no dependencies beyond the Apple Container CLI binary.

---

### 7. MCP Server (optional sidecar)

**FR-7.1** Each running container shall optionally run an MCP (Model Context Protocol) filesystem server as a sidecar process.

**FR-7.2** The MCP server shall expose tools: `read_file`, `write_file`, `list_directory`.

**FR-7.3** All MCP file operations shall be restricted to the `/workspace` directory. Path traversal attempts shall be rejected.

**FR-7.4** The MCP server shall support both stdio (default) and TCP transport (`MCP_PORT` environment variable).

---

## Technical Constraints

- **Container runtime:** Apple Container CLI (`container` binary). Docker/Podman are not used.
- **Host OS:** macOS only (Apple Container CLI is macOS-specific).
- **Container OS:** Ubuntu 24.04.
- **Node.js:** Version 25, installed from the official binary tarball (not the distro package).
- **OpenVSCode Server:** gitpod fork, pinned version. Microsoft's VS Code Server is not used.
- **Extension registry:** Open VSX only. The Microsoft marketplace is not used.
- **Network:** Core editing functionality shall not require internet access at runtime. Features that require internet (e.g. Open VSX update checks) shall fail silently.
- **Port range:** Ports are allocated in the range 49152–65533, derived from the project path hash.

---

## Out of Scope (deferred)

- Cloud deployment (ECS, S3, remote containers)
- Multi-user access or authentication
- Windows or Linux host support
- VS Code Desktop integration (extensions, settings sync)
- Offline font loading (Inter is loaded from Google Fonts; requires internet for first load)
- Fountain/screenplay template (pending Open VSX extension availability)
