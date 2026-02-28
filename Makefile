IMAGE_NAME = ubuntu-latex

GIT_EMAIL ?= user@example.com
GIT_NAME  ?= Your Name

# Install destination for the wrapper scripts
INSTALL_DIR  = /usr/local/bin
SCRIPT_PDF   = pdflatex-container
SCRIPT_MK    = latexmk-container

.PHONY: start build install install-latexmk install-all uninstall check clean-images help

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
	@sudo cp pdflatex-container.sh $(INSTALL_DIR)/$(SCRIPT_PDF)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_PDF)
	@echo "✅ $(SCRIPT_PDF) installed."

# ----------------------------------------
# install-latexmk: copy latexmk wrapper to PATH
# (handles biber + multi-pass automatically)
# ----------------------------------------
install-latexmk: build
	@echo "📦 Installing '$(SCRIPT_MK)' to $(INSTALL_DIR)..."
	@sudo cp latexmk-container.sh $(INSTALL_DIR)/$(SCRIPT_MK)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_MK)
	@echo "✅ $(SCRIPT_MK) installed."

# ----------------------------------------
# install-all: install both wrapper scripts
# ----------------------------------------
install-all: install install-latexmk
	@echo "✅ All scripts installed."

# ----------------------------------------
# uninstall: remove both wrapper scripts
# ----------------------------------------
uninstall:
	@echo "🗑  Removing wrapper scripts from $(INSTALL_DIR)..."
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_PDF)
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_MK)
	@echo "✅ Uninstalled."

# ----------------------------------------
# check: smoke-test pdflatex and latexmk
# ----------------------------------------
check: start
	@echo "🔍 Checking pdflatex version..."
	container run --rm $(IMAGE_NAME) pdflatex --version
	@echo "🔍 Checking latexmk version..."
	container run --rm $(IMAGE_NAME) latexmk --version

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
	@echo "  make build           — Build the Docker image (run once)"
	@echo "  make install         — Build + install pdflatex wrapper"
	@echo "  make install-latexmk — Build + install latexmk wrapper (biber + full refs)"
	@echo "  make install-all     — Build + install both wrappers"
	@echo "  make uninstall       — Remove both wrapper scripts"
	@echo "  make check           — Verify pdflatex and latexmk work inside the image"
	@echo "  make clean-images    — Delete the built image"
	@echo ""
	@echo "Per-project usage after 'make install-all':"
	@echo "  Open any folder in VSCode and compile with LaTeX Workshop."
	@echo "  Use 'latexmk (full)' recipe for documents with citations/references."
	@echo "  No per-project setup needed."
	@echo ""