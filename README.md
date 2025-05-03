# NixOS Utilities Collection

This repository provides a collection of command-line utilities run within a secure and reproducible environment using Docker and NixOS. Each tool leverages `nix-shell` to provide its specific dependencies.

## Purpose

Often, command-line tasks require specific dependencies or a controlled environment for security or reproducibility. This collection uses Docker and NixOS (`nixos/nix` image) to provide isolated environments for various utilities, managed via a simple `Makefile` interface.

## Prerequisites

1.  **Docker:** Must be installed and running on your host machine.
2.  **GPG Keypair:** You need a GPG keypair configured locally (usually in `~/.gnupg`). The public key must have been used to encrypt the Vault unseal keys if using the `vault-decrypt` tool.
3.  **Tool-Specific Setup:** Depending on the tool, you might need to create specific directories and populate them:
    *   **For `vault-decrypt`:** Create `tools/vault-gpg-unseal/gnupg/`.
        *   **IMPORTANT:** This directory will be mounted into the container as `/root/.gnupg`. For security, it should contain **only the necessary GPG key files (private keys, trustdb.gpg etc.)** required for decryption, copied from your host `~/.gnupg`.
        *   **DO NOT** mount your entire host `~/.gnupg` directory directly.
        *   Ensure permissions on copied files are secure (e.g., `chmod 600` for private keys).
        *   This directory (`tools/vault-gpg-unseal/gnupg/`) is included in `.gitignore`.
    *   **For `ps-to-pdf`:** Create `tools/ps-to-pdf/data/` and place your input `.ps` files inside. This directory is also ignored by git.

## Setup

1.  Clone this repository.
2.  Perform any necessary tool-specific setup as described in Prerequisites (e.g., creating `tools/vault-gpg-unseal/gnupg/` and copying keys, or creating `tools/ps-to-pdf/data/`).
3.  Ensure you have `make` installed on your system.

## Usage

This collection uses a `Makefile` to simplify running the tools. Each tool has its own target(s).

### Available Tools

*   **Vault GPG Decrypt (`vault-decrypt`, `vault-shell`)**
    *   Purpose: Decrypts GPG-encrypted HashiCorp Vault unseal keys provided via standard input.
    *   Requires: `tools/vault-gpg-unseal/gnupg/` directory created and populated with necessary GPG keys (see Prerequisites).
    *   Commands:
        *   `make vault-decrypt`: Run the decryption interactively.
        *   `make vault-shell`: Open an interactive shell in the tool's Nix environment.

*   **PostScript to PDF (`ps-to-pdf`)**
    *   Purpose: Converts all `.ps` files found in `tools/ps-to-pdf/data/` to `.pdf` files in the same directory.
    *   Requires: User must create the `tools/ps-to-pdf/data/` directory and place input `.ps` files there.
    *   Commands:
        *   `make ps-to-pdf`: Run the conversion process.

### Running a Tool

1.  **Run a specific tool:**
    *   Use the `make` command followed by the tool's target name. For example, to run the Vault key decryption:
        ```bash
        make vault-decrypt
        ```
    *   Follow any specific instructions provided by the tool (e.g., pasting keys for `vault-decrypt`).

2.  **Access a Tool's Interactive Shell:**
    *   Some tools provide a shell target (e.g., `vault-shell`) for direct access to their specific NixOS container environment:
        ```bash
        make vault-shell
        ```
    *   This is useful for debugging or running related commands within the tool's context. Type `exit` to leave the shell.

3.  **Show Available Tool Targets:**
    *   To see available `make` targets for the tools:
        ```bash
        make help
        ```
        or simply:
        ```bash
        make
        ```

## Repository Structure

*   `Makefile`: Provides simple commands (`make <tool-target>`) to run utilities.
*   `tools/`: Contains the individual utility scripts and resources.
    *   `tools/vault-gpg-unseal/`: Contains the Vault GPG decryption tool.
        *   `unseal.sh`: The core script for decryption.
        *   `examples/`: Contains example GPG key files.
        *   `gnupg/`: Directory created by user to hold necessary GPG keys (ignored by git).
    *   `tools/ps-to-pdf/`: Contains the PostScript to PDF conversion tool.
        *   `convert.sh`: The core script for conversion.
        *   `data/`: Directory created by user for input `.ps` and output `.pdf` files (ignored by git).
*   `.gitignore`: Prevents sensitive/generated directories (`tools/vault-gpg-unseal/gnupg/`, `tools/ps-to-pdf/data/`) and other specified files (`memory-bank`, `history.md`, `vault.out.txt`) from being committed.
*   `memory-bank/`: Contains project documentation for Cline (ignored by git).
*   `README.md`: This file.
