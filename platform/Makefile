CONTAINER_BIN  := container
VSCODE_VERSION := 1.109.5
NODE_VERSION   := 25.9.0

INSTALL_DIR    := /usr/local/bin

DIR ?= $(CURDIR)
EXT ?= project-dashboard

.PHONY: start build build-base build-latex build-fountain run stop logs dev-ext install uninstall check help

# ── System ────────────────────────────────────────────────────────────────────

start: ## Start the Apple Container system daemon
	container system start

# ── Build ─────────────────────────────────────────────────────────────────────

build: start build-base build-latex ## Start daemon then build all images

build-base: ## Build shared base image (Node 25 + OpenVSCode Server + custom extension)
	@echo "Building openvscode-base..."
	$(CONTAINER_BIN) build \
		--build-arg VSCODE_VERSION=$(VSCODE_VERSION) \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		-f Containerfile.base \
		-t openvscode-base \
		.
	@echo "Done: openvscode-base"

build-latex: build-base ## Build LaTeX template image
	@echo "Building openvscode-latex..."
	$(CONTAINER_BIN) build \
		-f templates/latex/Containerfile \
		-t openvscode-latex \
		.
	@echo "Done: openvscode-latex"

build-fountain: build-base ## Build Fountain (screenplay) template image
	@echo "Building openvscode-fountain..."
	$(CONTAINER_BIN) build \
		-f templates/fountain/Containerfile \
		-t openvscode-fountain \
		.
	@echo "Done: openvscode-fountain"

# ── Run ──────────────────────────────────────────────────────────────────────
# Use: make run           (runs against current directory)
#      make run DIR=~/my-thesis

run: start ## Run the editor container for DIR (default: current directory)
	@TEMPLATE=$$(cat "$(DIR)/.vscode-template" 2>/dev/null | tr -d '[:space:]'); \
	TEMPLATE=$${TEMPLATE:-latex}; \
	IMAGE="openvscode-$${TEMPLATE}"; \
	NAME="edit-$$(basename "$(DIR)")"; \
	PORT=$$(( 49152 + $$(echo -n "$(DIR)" | cksum | awk '{print $$1}') % 16380 )); \
	VSCODE_PORT=$$(( PORT + 1 )); \
	echo "Starting $${IMAGE} for $$(basename "$(DIR)") on port $${PORT}..."; \
	$(CONTAINER_BIN) run -d --rm \
		--name  "$${NAME}" \
		-v      "$(DIR):/workspace" \
		-e      PORT="$${PORT}" \
		-e      VSCODE_PORT="$${VSCODE_PORT}" \
		-p      "$${PORT}:$${PORT}" \
		"$${IMAGE}"; \
	echo "Editor running → http://localhost:$${PORT}"; \
	echo "Stop with: make stop DIR=$(DIR)"

stop: ## Stop the editor container for DIR (default: current directory)
	@NAME="edit-$$(basename "$(DIR)")"; \
	$(CONTAINER_BIN) stop "$${NAME}" 2>/dev/null && echo "Stopped $${NAME}" || echo "Not running: $${NAME}"

logs: ## Tail logs for the editor container for DIR (default: current directory)
	@NAME="edit-$$(basename "$(DIR)")"; \
	$(CONTAINER_BIN) logs -f "$${NAME}"

# ── Extension hot-swap ───────────────────────────────────────────────────────
# Compile the extension locally and install it into the running container
# without rebuilding the image. Uses the workspace volume as a file transfer
# channel (the only path shared between Mac and container at runtime).
#
# Usage:
#   make dev-ext                            (project-dashboard into current-dir container)
#   make dev-ext EXT=project-status         (different extension)
#   make dev-ext DIR=~/my-thesis            (container for a specific project)

dev-ext: ## Hot-swap an extension into the running container (builds inside container, no npm on host needed)
	@NAME="edit-$$(basename "$(DIR)")"; \
	WORK="$(DIR)/.dev-ext"; \
	rm -rf "$$WORK"; \
	cp -r "$(CURDIR)/extensions/$(EXT)" "$$WORK"; \
	printf '#!/bin/sh\nset -e\ncd /workspace/.dev-ext\nnpm install --silent\nnpm run compile\nnpx vsce package --no-yarn -o /workspace/.dev-ext/out.vsix\n' \
	    > "$$WORK/build.sh"; \
	echo "→ Building $(EXT) inside $$NAME..."; \
	$(CONTAINER_BIN) exec "$$NAME" sh /workspace/.dev-ext/build.sh || \
	    { rm -rf "$$WORK"; echo "ERROR: build failed — run 'make logs DIR=$(DIR)' for details"; exit 1; }; \
	echo "→ Installing..."; \
	$(CONTAINER_BIN) exec "$$NAME" \
	    /opt/openvscode-server/bin/openvscode-server \
	    --install-extension /workspace/.dev-ext/out.vsix \
	    --extensions-dir /opt/vscode-extensions \
	    --user-data-dir  /opt/vscode-data || \
	    { rm -rf "$$WORK"; echo "ERROR: install failed (is the container running?)"; exit 1; }; \
	rm -rf "$$WORK"; \
	echo "✓ $(EXT) installed → Cmd+Shift+P  'Reload Window'"

# ── Install ───────────────────────────────────────────────────────────────────

install: ## Install 'edit' command to $(INSTALL_DIR)
	@sudo cp scripts/edit $(INSTALL_DIR)/edit
	@sudo chmod +x $(INSTALL_DIR)/edit
	@echo "Installed: edit  →  $(INSTALL_DIR)/edit"
	@echo "Usage: cd <project> && edit"

uninstall: ## Remove 'edit' command
	@sudo rm -f $(INSTALL_DIR)/edit
	@echo "Removed: $(INSTALL_DIR)/edit"

# ── Smoke tests ───────────────────────────────────────────────────────────────

check: ## Verify Node 25 and OpenVSCode Server are present in the base image
	@echo "--- Node version ---"
	$(CONTAINER_BIN) run --rm openvscode-base node --version
	@echo "--- OpenVSCode Server ---"
	$(CONTAINER_BIN) run --rm openvscode-base /opt/openvscode-server/bin/openvscode-server --version
	@echo "--- pdflatex (latex image) ---"
	$(CONTAINER_BIN) run --rm openvscode-latex pdflatex --version
	@echo "All checks passed."

# ── Help ──────────────────────────────────────────────────────────────────────

help: ## Show this help
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "One-time setup:"
	@echo "  make build    — build all images"
	@echo "  make install  — install the 'edit' command globally"
	@echo ""
	@echo "Per-project usage (after install):"
	@echo "  cd <project> && edit"
	@echo ""
