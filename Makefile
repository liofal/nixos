# Makefile for NixOS Utilities Collection

# Default target
.DEFAULT_GOAL := help

# Define the Docker image
NIX_IMAGE := nixos/nix

# Define common Docker run options
# Mount tools directory for script access
# Mount tools directory for script access
# Mount common host configs if needed (adjust/remove as necessary)
# Tool-specific mounts (like GPG) are added in the target commands
DOCKER_RUN_OPTS := \
	-it \
	--rm \
	-v $(PWD)/tools:/tools \
	-v $(PWD)/downloads:/downloads \
	-v $(HOME)/.kube:/root/.kube \
	-v $(HOME)/.aws:/root/.aws \
	-w /tools

# Define vault-specific mount
VAULT_GPG_MOUNT := -v $(PWD)/tools/vault-gpg-unseal/gnupg:/root/.gnupg

# Check if vault-gpg-unseal gnupg directory exists and is not empty
check_gnupg = $(if $(wildcard tools/vault-gpg-unseal/gnupg/*),,$(error Error: ./tools/vault-gpg-unseal/gnupg directory is empty or does not exist. Please create it and copy your necessary GPG key files into it. See README.md))

# Check if ps-to-pdf data directory exists
check_ps_data = $(if $(wildcard tools/ps-to-pdf/data/*),,$(error Error: ./tools/ps-to-pdf/data directory is empty or does not exist. Please create it and place your .ps files inside. See README.md))

# Check if docx-to-pdf data directory exists
check_docx_data = $(if $(wildcard tools/docx-to-pdf/data/*),,$(error Error: ./tools/docx-to-pdf/data directory is empty or does not exist. Please create it and place your .docx files inside. See README.md))

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
	@docker run $(DOCKER_RUN_OPTS) $(VAULT_GPG_MOUNT) $(NIX_IMAGE) \
		nix-shell -p gnupg coreutils pinentry-curses --run /tools/vault-gpg-unseal/unseal.sh

## vault-shell: Start an interactive shell for the Vault GPG tool environment.
.PHONY: vault-shell
vault-shell:
	$(call check_gnupg)
	@echo "Starting interactive shell in NixOS container (Vault GPG context)..."
	@docker run $(DOCKER_RUN_OPTS) $(VAULT_GPG_MOUNT) $(NIX_IMAGE) \
		nix-shell -p gnupg coreutils pinentry-curses

# --- GPG Key Initialization ---
GPG_INIT_TOOL_DIR := gpg-init
GPG_INIT_SCRIPT_NAME := init.sh
GPG_INIT_SCRIPT_PATH := /tools/$(GPG_INIT_TOOL_DIR)/$(GPG_INIT_SCRIPT_NAME)

## gpg-init: Initialize GPG keys for Vault Raft server key encryption.
.PHONY: gpg-init
gpg-init:
	@echo "Starting GPG key initialization..."
	@docker run $(DOCKER_RUN_OPTS) $(VAULT_GPG_MOUNT) $(NIX_IMAGE) \
		nix-shell -p gnupg coreutils pinentry-curses --run "$(GPG_INIT_SCRIPT_PATH)"

## ps-to-pdf: Convert PostScript files in tools/ps-to-pdf/data/ to PDF.
.PHONY: ps-to-pdf
ps-to-pdf:
	$(call check_ps_data)
	@echo "Starting PostScript to PDF conversion..."
	# Use common opts, override working directory
	@docker run $(DOCKER_RUN_OPTS) -w /tools/ps-to-pdf $(NIX_IMAGE) \
		nix-shell -p ghostscript --run /tools/ps-to-pdf/convert.sh

# --- Authentik Key Generation ---
AUTHENTIK_TOOL_DIR := authentik-gen-key
AUTHENTIK_SCRIPT_NAME := generate.sh # Just the script name
AUTHENTIK_SCRIPT_PATH := /tools/$(AUTHENTIK_TOOL_DIR)/$(AUTHENTIK_SCRIPT_NAME) # Absolute path in container

.PHONY: authentik-gen-key authentik-shell
authentik-gen-key: ## Generate an Authentik secret key using openssl
	@echo "--- Running Authentik Key Generation ---"
	# Use common opts
	@docker run $(DOCKER_RUN_OPTS) $(NIX_IMAGE) \
		nix-shell -p openssl --run "$(AUTHENTIK_SCRIPT_PATH)"
	@echo "--- Authentik Key Generation Complete ---"

authentik-shell: ## Open a shell in the Authentik key generation environment
	@echo "--- Entering Authentik Key Generation Shell ---"
	# Use common opts, override entrypoint
	@docker run $(DOCKER_RUN_OPTS) --entrypoint nix-shell $(NIX_IMAGE) -p openssl

# --- Htpasswd Hash Generation ---
HTPASSWD_TOOL_DIR := tools/htpasswd-hash
HTPASSWD_SCRIPT_NAME := generate_hash.sh
HTPASSWD_SCRIPT_PATH := /tools/$(HTPASSWD_TOOL_DIR)/$(HTPASSWD_SCRIPT_NAME) # Absolute path in container, but script is called relatively from -w

.PHONY: htpasswd-hash yt-dlp
htpasswd-hash: ## Generate a bcrypt hash for a password using htpasswd. You will be prompted for input.
	@echo "--- Generating htpasswd hash ---"
	@docker run $(DOCKER_RUN_OPTS) \
		-w /tools/htpasswd-hash \
		$(NIX_IMAGE) \
		nix-shell -p apacheHttpd coreutils --run "./$(HTPASSWD_SCRIPT_NAME)"
	@echo "--- htpasswd hash generation complete ---"

.PHONY: docx-to-pdf
docx-to-pdf: ## Convert DOCX files in tools/docx-to-pdf/data/ to PDF.
	$(call check_docx_data)
	@echo "Starting DOCX to PDF conversion..."
	# Use common opts, override working directory
	@docker run $(DOCKER_RUN_OPTS) -w /tools/docx-to-pdf $(NIX_IMAGE) \
		nix-shell -p libreoffice --run /tools/docx-to-pdf/convert.sh

# --- YouTube Downloader ---
URL_ARG := $(word 2,$(MAKECMDGOALS))
yt-dlp: ## Download a YouTube video. Usage: make yt-dlp <url>
	@if [ -z "$(URL_ARG)" ]; then \
		echo "Usage: make yt-dlp <youtube_url>"; \
		exit 1; \
	fi
	@echo "--- Downloading YouTube video ---"
	@docker run $(DOCKER_RUN_OPTS) \
		$(NIX_IMAGE) \
		nix-shell -p yt-dlp ffmpeg --run "/tools/yt-dlp/download.sh $(URL_ARG)"
	@echo "--- Download complete ---"
