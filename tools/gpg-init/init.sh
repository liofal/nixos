#!/usr/bin/env bash

set -euo pipefail

GPG_DIR="/root/.gnupg"
PUBKEY_EXPORT_PATH="/tools/vault-gpg-unseal/vault_encrypt_pubkey.asc"

echo "--- Initializing GPG keys for Vault Raft server key encryption ---"

# Ensure the GPG directory exists and has correct permissions
mkdir -p "${GPG_DIR}"
chmod 700 "${GPG_DIR}"

# Configure GPG to use pinentry-curses for interactive prompts
echo "Ensuring gpg-agent is running and configured for pinentry-curses..."
gpg-connect-agent /bye || true # Start agent if not running, ignore error if already running

export GPG_TTY=$(tty)
PINENTRY_PATH=$(which pinentry-curses)

if [ -z "$PINENTRY_PATH" ]; then
    echo "Error: pinentry-curses not found in PATH. This should be provided by the nix-shell environment."
    exit 1
fi
echo "Found pinentry-curses at: ${PINENTRY_PATH}"

# Configure gpg-agent.conf
echo "pinentry-program ${PINENTRY_PATH}" > "${GPG_DIR}/gpg-agent.conf"
echo "allow-loopback-pinentry" >> "${GPG_DIR}/gpg-agent.conf"

# Force gpg-agent to re-read its configuration
gpgconf --kill gpg-agent || true # Kill existing agent, ignore error if not running
gpg-connect-agent /bye || true # Ensure agent is (re)started and picks up new config

echo "Generating a new RSA 4096-bit GPG key pair..."
echo "You will be prompted for a passphrase."

# Generate an RSA 4096-bit key non-interactively for key parameters,
# but pinentry will prompt for the passphrase.
gpg --batch --pinentry-mode loopback --generate-key - <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Vault Key
Name-Comment: For Vault PGP Seal
Name-Email: vault@example.com
Expire-Date: 0
%commit
EOF

echo "GPG key generation complete."

# List keys to find the newly created key's ID
echo "Listing GPG keys to identify the new key..."
# Use the fingerprint (fpr) line to get the key ID, which is more robust for different key types.
# The key ID is the last 16 characters of the fingerprint.
gpg_key_id=$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/{print substr($10, length($10)-15); exit}')

if [ -z "$gpg_key_id" ]; then
    echo "Error: Could not find a GPG key ID. Key generation might have failed."
    exit 1
fi

echo "New GPG key ID identified: ${gpg_key_id}"

# Export the public key in armored format
echo "Exporting armored public key to ${PUBKEY_EXPORT_PATH}..."
gpg --armor --export "${gpg_key_id}" > "${PUBKEY_EXPORT_PATH}"

echo "Public key exported successfully."
echo "GPG key initialization complete. The public key is available at: ${PUBKEY_EXPORT_PATH}"
echo "The private key and other GPG files are in: $(pwd)/tools/vault-gpg-unseal/gnupg/"
echo "Remember to keep your private key secure and its passphrase memorized."
