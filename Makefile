# Makefile for NixOS Utilities Collection

# Default target
.DEFAULT_GOAL := help

# Define the Docker image
NIX_IMAGE := nixos/nix

# Define common Docker run options
# Mount tools directory for script access
# Mount tool-specific gnupg directory (read-write) for GPG operations
# Mount common host configs if needed (adjust/remove as necessary)
DOCKER_RUN_OPTS := \
	-it \
	--rm \
	-v $(PWD)/tools/vault-gpg-unseal/gnupg:/root/.gnupg \
	-v $(PWD)/tools:/tools \
	-v $(HOME)/.kube:/root/.kube \
	-v $(HOME)/.aws:/root/.aws \
	-w /tools

# Check if vault-gpg-unseal gnupg directory exists and is not empty
check_gnupg = $(if $(wildcard tools/vault-gpg-unseal/gnupg/*),,$(error Error: ./tools/vault-gpg-unseal/gnupg directory is empty or does not exist. Please create it and copy your necessary GPG key files into it. See README.md))

# Check if ps-to-pdf data directory exists
check_ps_data = $(if $(wildcard tools/ps-to-pdf/data/*),,$(error Error: ./tools/ps-to-pdf/data directory is empty or does not exist. Please create it and place your .ps files inside. See README.md))

## help: Show available tool targets
.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available Tool Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -v help

## vault-decrypt: Run the Vault GPG decryption script interactively. Paste base64 GPG keys, then Ctrl+D.
.PHONY: vault-decrypt
vault-decrypt:
	$(call check_gnupg)
	@echo "Starting Vault GPG decryption environment..."
	@echo "Paste raw base64-encoded GPG key data below (one key per line)."
	@echo "Press Ctrl+D when finished."
	@docker run $(DOCKER_RUN_OPTS) $(NIX_IMAGE) \
		nix-shell -p gnupg coreutils pinentry-curses --run /tools/vault-gpg-unseal/unseal.sh

## vault-shell: Start an interactive shell for the Vault GPG tool environment.
.PHONY: vault-shell
vault-shell:
	$(call check_gnupg)
	@echo "Starting interactive shell in NixOS container (Vault GPG context)..."
	@docker run $(DOCKER_RUN_OPTS) $(NIX_IMAGE) \
		nix-shell -p gnupg coreutils pinentry-curses

## ps-to-pdf: Convert PostScript files in tools/ps-to-pdf/data/ to PDF.
.PHONY: ps-to-pdf
ps-to-pdf:
	$(call check_ps_data)
	@echo "Starting PostScript to PDF conversion..."
	# Override working directory for this target
	@docker run $(DOCKER_RUN_OPTS) -w /tools/ps-to-pdf $(NIX_IMAGE) \
		nix-shell -p ghostscript --run /tools/ps-to-pdf/convert.sh
