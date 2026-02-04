#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: $0 <url>"
  exit 1
fi

DOWNLOAD_DIR="/downloads/yt-dlp"
mkdir -p "$DOWNLOAD_DIR"

# Use a unique filename template including the video ID to prevent overwrites
# and specify the format to ensure a proper video file is downloaded.
# Added --extractor-args to bypass some bot detection
yt-dlp --format 'bestvideo+bestaudio/best' \
       --extractor-args "youtube:player_client=android,web" \
       -o "$DOWNLOAD_DIR/%(title)s - [%(id)s].%(ext)s" "$1"
