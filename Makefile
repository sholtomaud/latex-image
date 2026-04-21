IMAGE_NAME = ubuntu-latex

GIT_EMAIL ?= user@example.com
GIT_NAME  ?= Your Name

# Install destination for the wrapper scripts
INSTALL_DIR    = /usr/local/bin
SCRIPT_PDF     = pdflatex-container
SCRIPT_MK      = latexmk-container
SCRIPT_PANDOC  = pandoc-container
SCRIPT_INDENT  = latexindent-container
MERGE_SCRIPT   = scripts/merge-vscode-settings.sh

.PHONY: start build install install-latexmk install-pandoc install-latexindent install-vscode-settings install-all uninstall check clean-images help

# ----------------------------------------
# start: ensure the Apple container system
# daemon is running before any operation
# ----------------------------------------
start:
	container system start

# ----------------------------------------
# build: build the LaTeX image
# Run once (or after editing Dockerfile)
# ----------------------------------------
build: start
	@echo "🔨 Building image '$(IMAGE_NAME)'..."
	container build -t "$(IMAGE_NAME)" .
	@echo "✅ Build complete."

# ----------------------------------------
# install: copy pdflatex wrapper to PATH
# ----------------------------------------
install: build
	@echo "📦 Installing '$(SCRIPT_PDF)' to $(INSTALL_DIR)..."
	@sudo cp scripts/pdflatex-container.sh $(INSTALL_DIR)/$(SCRIPT_PDF)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_PDF)
	@echo "✅ $(SCRIPT_PDF) installed."

# ----------------------------------------
# install-latexmk: copy latexmk wrapper to PATH
# (handles biber + multi-pass automatically)
# ----------------------------------------
install-latexmk: build
	@echo "📦 Installing '$(SCRIPT_MK)' to $(INSTALL_DIR)..."
	@sudo cp scripts/latexmk-container.sh $(INSTALL_DIR)/$(SCRIPT_MK)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_MK)
	@echo "✅ $(SCRIPT_MK) installed."

# ----------------------------------------
# install-pandoc: copy pandoc wrapper to PATH
# ----------------------------------------
install-pandoc: build
	@echo "📦 Installing '$(SCRIPT_PANDOC)' to $(INSTALL_DIR)..."
	@sudo cp scripts/pandoc-container.sh $(INSTALL_DIR)/$(SCRIPT_PANDOC)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_PANDOC)
	@echo "✅ $(SCRIPT_PANDOC) installed."

# ----------------------------------------
# install-latexindent: copy latexindent wrapper to PATH
# ----------------------------------------
install-latexindent: build
	@echo "📦 Installing '$(SCRIPT_INDENT)' to $(INSTALL_DIR)..."
	@sudo cp scripts/latexindent-container.sh $(INSTALL_DIR)/$(SCRIPT_INDENT)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_INDENT)
	@echo "✅ $(SCRIPT_INDENT) installed."

# ----------------------------------------
# install-vscode-settings: merge latex-workshop
# settings into global VSCode user settings.json
# ----------------------------------------
install-vscode-settings:
	@bash $(MERGE_SCRIPT)

# ----------------------------------------
# install-all: install all wrapper scripts
# and optionally merge VSCode settings
# ----------------------------------------
install-all: install install-latexmk install-pandoc install-latexindent install-vscode-settings
	@echo "✅ All scripts installed."

# ----------------------------------------
# uninstall: remove all wrapper scripts
# ----------------------------------------
uninstall:
	@echo "🗑  Removing wrapper scripts from $(INSTALL_DIR)..."
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_PDF)
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_MK)
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_PANDOC)
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_INDENT)
	@echo "✅ Uninstalled."

# ----------------------------------------
# check: smoke-test all tools inside the image
# ----------------------------------------
check: start
	@echo "🔍 Checking pdflatex..."
	container run --rm $(IMAGE_NAME) pdflatex --version
	@echo "🔍 Checking latexmk..."
	container run --rm $(IMAGE_NAME) latexmk --version
	@echo "🔍 Checking pandoc..."
	container run --rm $(IMAGE_NAME) pandoc --version
	@echo "🔍 Checking latexindent..."
	container run --rm $(IMAGE_NAME) latexindent --version
	@echo "✅ All checks passed."

# ----------------------------------------
# clean-images: remove the built image
# ----------------------------------------
clean-images:
	@echo "🗑  Removing image '$(IMAGE_NAME)'..."
	-container rmi "$(IMAGE_NAME)"
	@echo "✅ Done."

help:
	@echo ""
	@echo "Usage:"
	@echo "  make build                  — Build the Docker image (run once)"
	@echo "  make install                — Build + install pdflatex wrapper"
	@echo "  make install-latexmk        — Build + install latexmk wrapper"
	@echo "  make install-pandoc         — Build + install pandoc wrapper"
	@echo "  make install-latexindent    — Build + install latexindent wrapper"
	@echo "  make install-vscode-settings — Merge latex-workshop settings into VSCode"
	@echo "  make install-all            — Build + install all wrappers + VSCode settings"
	@echo "  make uninstall              — Remove all wrapper scripts"
	@echo "  make check                  — Verify all tools work inside the image"
	@echo "  make clean-images           — Delete the built image"
	@echo ""
	@echo "Per-project usage after 'make install-all':"
	@echo "  Open any folder in VSCode and compile with LaTeX Workshop."
	@echo "  Use 'latexmk (full)' recipe for documents with citations/references."
	@echo "  No per-project setup needed."
	@echo ""