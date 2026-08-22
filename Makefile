MACHINE_NAME   = ubuntu-latex
MACHINE_IMAGE  = ubuntu-latex-machine
INSTALL_DIR    = /usr/local/bin
SCRIPT_PDF     = pdflatex-container
SCRIPT_MK      = latexmk-container
SCRIPT_PANDOC  = pandoc-container
SCRIPT_INDENT  = latexindent-container
MERGE_SCRIPT   = scripts/merge-vscode-settings.sh

.PHONY: machine-build machine-create machine-start machine-stop machine-rm machine-shell \
        install install-latexmk install-pandoc install-latexindent \
        install-vscode-settings install-all launchd-install launchd-uninstall \
        uninstall check help

# ----------------------------------------
# machine-build: build the machine image
# Run once (or after editing Containerfile)
# ----------------------------------------
machine-build:
	@echo "Starting container system..."
	container system start
	@echo "Building machine image '$(MACHINE_IMAGE)'..."
	container build -t "$(MACHINE_IMAGE)" .
	@echo "Build complete."

# ----------------------------------------
# machine-create: create the persistent machine from the image
# ----------------------------------------
machine-create: machine-build
	@echo "Creating container machine '$(MACHINE_NAME)'..."
	container machine create --set-default --name "$(MACHINE_NAME)" "$(MACHINE_IMAGE)"
	@echo "Machine '$(MACHINE_NAME)' created and running."

# ----------------------------------------
# machine-start: start an existing machine (idempotent)
# ----------------------------------------
machine-start:
	@container system start
	@echo "Booting machine '$(MACHINE_NAME)' (no-op if already running)..."
	container machine run -n "$(MACHINE_NAME)" true

# ----------------------------------------
# machine-stop: stop the machine
# ----------------------------------------
machine-stop:
	container machine stop "$(MACHINE_NAME)"

# ----------------------------------------
# machine-rm: stop and permanently delete the machine
# ----------------------------------------
machine-rm:
	-container machine stop "$(MACHINE_NAME)"
	container machine rm "$(MACHINE_NAME)"

# ----------------------------------------
# machine-shell: open an interactive shell inside the machine
# ----------------------------------------
machine-shell:
	container machine run -n "$(MACHINE_NAME)"

# ----------------------------------------
# launchd-install: auto-start the machine at every login
# ----------------------------------------
launchd-install:
	@bash scripts/install-launchd.sh "$(MACHINE_NAME)"

# ----------------------------------------
# launchd-uninstall: remove the auto-start agent
# ----------------------------------------
launchd-uninstall:
	@bash scripts/uninstall-launchd.sh

# ----------------------------------------
# install: install pdflatex wrapper script
# Installed under both the container name and the native name so that
# LaTeX Workshop's built-in recipes and our custom ones both work.
# ----------------------------------------
install:
	@echo "Installing pdflatex wrappers to $(INSTALL_DIR)..."
	@sudo cp scripts/pdflatex-container.sh $(INSTALL_DIR)/$(SCRIPT_PDF)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_PDF)
	@sudo cp scripts/pdflatex-container.sh $(INSTALL_DIR)/pdflatex
	@sudo chmod +x $(INSTALL_DIR)/pdflatex
	@echo "Done."

# ----------------------------------------
# install-latexmk: install latexmk wrapper script
# ----------------------------------------
install-latexmk:
	@echo "Installing latexmk wrappers to $(INSTALL_DIR)..."
	@sudo cp scripts/latexmk-container.sh $(INSTALL_DIR)/$(SCRIPT_MK)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_MK)
	@sudo cp scripts/latexmk-container.sh $(INSTALL_DIR)/latexmk
	@sudo chmod +x $(INSTALL_DIR)/latexmk
	@echo "Done."

# ----------------------------------------
# install-pandoc: install pandoc wrapper script
# ----------------------------------------
install-pandoc:
	@echo "Installing pandoc wrappers to $(INSTALL_DIR)..."
	@sudo cp scripts/pandoc-container.sh $(INSTALL_DIR)/$(SCRIPT_PANDOC)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_PANDOC)
	@sudo cp scripts/pandoc-container.sh $(INSTALL_DIR)/pandoc
	@sudo chmod +x $(INSTALL_DIR)/pandoc
	@echo "Done."

# ----------------------------------------
# install-latexindent: install latexindent wrapper script
# ----------------------------------------
install-latexindent:
	@echo "Installing latexindent wrappers to $(INSTALL_DIR)..."
	@sudo cp scripts/latexindent-container.sh $(INSTALL_DIR)/$(SCRIPT_INDENT)
	@sudo chmod +x $(INSTALL_DIR)/$(SCRIPT_INDENT)
	@sudo cp scripts/latexindent-container.sh $(INSTALL_DIR)/latexindent
	@sudo chmod +x $(INSTALL_DIR)/latexindent
	@echo "Done."

# ----------------------------------------
# install-vscode-settings: merge latex-workshop settings into VSCode
# ----------------------------------------
install-vscode-settings:
	@bash $(MERGE_SCRIPT)

# ----------------------------------------
# install-all: full first-time setup
# Build image, create machine, install wrappers, set up auto-start, configure VSCode
# ----------------------------------------
install-all: machine-create install install-latexmk install-pandoc install-latexindent launchd-install install-vscode-settings
	@echo ""
	@echo "Setup complete. Open any .tex file in VSCode and build with LaTeX Workshop."
	@echo "The machine starts automatically at each login."
	@echo ""

# ----------------------------------------
# uninstall: remove wrapper scripts, launchd agent, and machine
# ----------------------------------------
uninstall: launchd-uninstall machine-rm
	@echo "Removing wrapper scripts from $(INSTALL_DIR)..."
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_PDF) $(INSTALL_DIR)/pdflatex
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_MK)  $(INSTALL_DIR)/latexmk
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_PANDOC) $(INSTALL_DIR)/pandoc
	@sudo rm -f $(INSTALL_DIR)/$(SCRIPT_INDENT) $(INSTALL_DIR)/latexindent
	@echo "Uninstalled."

# ----------------------------------------
# check: verify the machine is running and all tools work
# ----------------------------------------
check:
	@echo "Machine state:"
	@container machine ls
	@echo ""
	@echo "Checking LaTeX tools inside machine..."
	@container machine run -n "$(MACHINE_NAME)" pdflatex --version | head -1
	@container machine run -n "$(MACHINE_NAME)" latexmk --version | head -1
	@container machine run -n "$(MACHINE_NAME)" pandoc --version | head -1
	@container machine run -n "$(MACHINE_NAME)" latexindent --version | head -1
	@echo "All checks passed."

help:
	@echo ""
	@echo "First-time setup:"
	@echo "  make install-all             — Build image + create machine + install wrappers + launchd + VSCode settings"
	@echo ""
	@echo "Machine lifecycle:"
	@echo "  make machine-start           — Start the machine manually"
	@echo "  make machine-stop            — Stop the machine"
	@echo "  make machine-shell           — Open a shell inside the machine"
	@echo "  make machine-rm              — Delete the machine and its filesystem"
	@echo ""
	@echo "Maintenance:"
	@echo "  make machine-build           — Rebuild the image (after editing Containerfile)"
	@echo "  make check                   — Verify machine is up and all tools work"
	@echo "  make install-vscode-settings — Re-merge latex-workshop settings into VSCode"
	@echo "  make uninstall               — Remove everything"
	@echo ""
