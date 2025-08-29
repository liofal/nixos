#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: $0 <url>"
  exit 1
fi

DOWNLOAD_DIR="/downloads/yt-dlp"
mkdir -p "$DOWNLOAD_DIR"

# Create a unique temporary directory for each download
TMP_DIR=$(mktemp -d)

# Download to the temporary directory and then move the final file
yt-dlp -o "$TMP_DIR/%(title)s.%(ext)s" "$1"

# Move the completed download to the final destination
mv "$TMP_DIR"/* "$DOWNLOAD_DIR/"

# Clean up the temporary directory
rm -rf "$TMP_DIR"