IMAGE_NAME = al23-latex

GIT_EMAIL ?= user@example.com
GIT_NAME  ?= Your Name

# Install destination for the wrapper script
INSTALL_DIR = /usr/local/bin
SCRIPT_NAME = pdflatex-container

.PHONY: start build install uninstall check clean-images help

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
# install: copy the wrapper script to PATH
# so VSCode (and your shell) can call it
# ----------------------------------------
install: build
	@echo "📦 Installing wrapper script to $(INSTALL_DIR)/$(SCRIPT_NAME)..."
	@sudo cp pdflatex-container.sh $(INSTALL_DIR)/$(SCRIPT_NAME)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_NAME)
	@echo "✅ Installed. You can now call '$(SCRIPT_NAME)' from anywhere."

# ----------------------------------------
# uninstall: remove the wrapper script
# ----------------------------------------
uninstall:
	@echo "🗑  Removing $(INSTALL_DIR)/$(SCRIPT_NAME)..."
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_NAME)
	@echo "✅ Uninstalled."

# ----------------------------------------
# check: smoke-test that LaTeX is available
# inside the image
# ----------------------------------------
check: start
	@echo "🔍 Checking pdflatex version inside image..."
	container run --rm $(IMAGE_NAME) pdflatex --version

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
	@echo "  make build      — Build the Docker image (run once)"
	@echo "  make install    — Build + install wrapper script to /usr/local/bin"
	@echo "  make uninstall  — Remove the wrapper script"
	@echo "  make check      — Verify pdflatex works inside the image"
	@echo "  make clean-images — Delete the built image"
	@echo ""
	@echo "Per-project usage after 'make install':"
	@echo "  Just open any folder in VSCode and compile with LaTeX Workshop."
	@echo "  No per-project setup needed."
	@echo ""
