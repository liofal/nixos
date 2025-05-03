#!/usr/bin/env bash

set -e # Exit immediately if a command exits with a non-zero status.

echo "Paste base64 encoded GPG keys one per line."
echo "Press Ctrl+D when finished."
echo "---"

# Check if GPG is available
if ! command -v gpg &> /dev/null; then
    echo "Error: gpg command not found. Ensure it's installed in the environment."
    exit 1
fi

# Check if base64 is available
if ! command -v base64 &> /dev/null; then
    echo "Error: base64 command not found. Ensure it's installed in the environment."
    exit 1
fi

# Ensure GPG can interact with the terminal if needed
export GPG_TTY=$(tty)

# Process standard input
KEY_COUNT=0
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines
  if [[ -z "$line" ]]; then
    continue
  fi

  KEY_COUNT=$((KEY_COUNT + 1))
  ENCRYPTED_KEY_BASE64="$line" # Assume the entire line is the base64 key

  echo "Processing Input Line $KEY_COUNT..."

  # Attempt decryption using default pinentry
  DECRYPTED_KEY=$(echo "$ENCRYPTED_KEY_BASE64" | base64 --decode | gpg --quiet --decrypt)

  if [[ $? -eq 0 ]] && [[ -n "$DECRYPTED_KEY" ]]; then
    echo "Decrypted Key $KEY_COUNT: $DECRYPTED_KEY"
  else
    echo "Error: Failed to decrypt Key $KEY_COUNT. Check GPG setup, key availability, and passphrase if required." >&2
    # Exit the script if one key fails, as subsequent keys likely will too.
    exit 1
  fi
  echo "---"
done

echo "Decryption process finished. Processed $KEY_COUNT lines."
