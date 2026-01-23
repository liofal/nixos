# Repository Architecture & Agent Guide

This repository implements a collection of command-line utilities that run within isolated, reproducible environments using **Docker** and **NixOS**.

## Architecture Overview

The core design pattern relies on three layers:

1.  **Host Interface (Makefile)**: The entry point for all interactions. Users run `make <target>` commands. The Makefile handles Docker command construction, volume mounting, and environment variable passing.
2.  **Container Runtime (Docker)**: All tools run inside the `nixos/nix` Docker image. This ensures a consistent base system regardless of the host OS.
3.  **Environment Provisioning (Nix)**: Inside the container, `nix-shell` is used to provision the specific dependencies required for each tool (e.g., `yt-dlp`, `ffmpeg`, `inkscape`, `libreoffice`) on the fly.

### Directory Structure

-   `Makefile`: Orchestrator script. Defines targets and Docker run configurations.
-   `tools/`: Contains the source code and scripts for each utility.
    -   `tools/<tool-name>/`: Dedicated directory for a specific tool.
        -   `script.sh`: The actual logic (Bash, Python, etc.).
        -   `data/`: (Optional) Directory for input/output files, often git-ignored.
        -   `shell.nix`: (Optional) Explicit Nix expression for dependencies (sometimes passed inline in Makefile).

## Execution Flow

When an agent or user runs a command like `make yt-dlp URL="..."`:

1.  **Make** triggers the `yt-dlp` target.
2.  **Docker** starts a container from `nixos/nix`.
    -   Mounts `$(PWD)/tools` to `/tools`.
    -   Mounts `$(PWD)/downloads` to `/downloads`.
    -   Mounts host credentials (optional, e.g., `~/.kube`, `~/.aws`).
3.  **Nix** (`nix-shell`) is invoked inside the container.
    -   It installs packages defined in the `-p` flag (e.g., `yt-dlp ffmpeg`).
    -   It executes the tool's script (e.g., `/tools/yt-dlp/download.sh`).
4.  **Output** is written to the mounted volumes (e.g., `downloads/`), making it available on the host.

## Available Tools & Usage

Agents should use the `make` commands to execute tools. **Do not run scripts in `tools/` directly on the host**, as dependencies will likely be missing.

| Tool | Make Target | Description | Dependencies (Nix) |
| :--- | :--- | :--- | :--- |
| **YouTube Downloader** | `make yt-dlp URL="..."` | Downloads videos to `downloads/yt-dlp`. | `yt-dlp`, `ffmpeg` |
| **Vault Decrypt** | `make vault-decrypt` | Decrypts Vault keys. Requires GPG setup. | `gnupg`, `coreutils`, `pinentry-curses` |
| **GPG Init** | `make gpg-init` | Initializes GPG keys for Vault. | `gnupg`, `coreutils`, `pinentry-curses` |
| **PostScript to PDF** | `make ps-to-pdf` | Converts `.ps` files in `tools/ps-to-pdf/data`. | `ghostscript` |
| **DOCX to PDF** | `make docx-to-pdf` | Converts `.docx` files in `tools/docx-to-pdf/data`. | `libreoffice` |
| **SVG to PNG** | `make svg-to-png` | Converts `.svg` files in `tools/svg-to-png/data`. | `inkscape` |
| **FLV to MP4** | `make flv-to-mp4` | Converts `.flv` files in `tools/flv-to-mp4/data`. | `ffmpeg` |
| **Authentik Key** | `make authentik-gen-key` | Generates a random secret key. | `openssl` |
| **Htpasswd Hash** | `make htpasswd-hash` | Generates bcrypt password hashes. | `apacheHttpd`, `coreutils` |

## Development Guidelines

To add a new tool:

1.  **Create Directory**: `mkdir tools/<new-tool-name>`
2.  **Create Script**: Write the script (e.g., `run.sh`) in that directory. Use standard shebangs (e.g., `#!/usr/bin/env bash`).
3.  **Update Makefile**:
    -   Add a new target.
    -   Use `$(DOCKER_RUN_OPTS)` for standard mounts.
    -   Use `nix-shell -p <packages> --run ...` to execute the script.
4.  **Documentation**: Update `README.md` and this `AGENTS.md`.

## Common Issues

-   **Permissions**: Docker runs as root inside the container. Files created in mounted volumes might be owned by root.
-   **Missing Directories**: Some tools require specific data directories (e.g., `tools/ps-to-pdf/data`). Ensure they exist before running.
