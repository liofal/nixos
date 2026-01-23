#!/usr/bin/env bash
set -e

# Define the data directory relative to the script location
# Inside the container, this will resolve to /tools/flv-to-mp4/data
DATA_DIR="$(dirname "$0")/data"

# Check if data directory exists
if [[ ! -d "$DATA_DIR" ]]; then
  echo "Error: Data directory '$DATA_DIR' not found." >&2
  echo "Please create 'tools/flv-to-mp4/data/' and place your .flv files inside." >&2
  exit 1
fi

# Find FLV files (case-insensitive)
flv_files=$(find "$DATA_DIR" -maxdepth 1 -type f -iname '*.flv' -print)

if [[ -z "$flv_files" ]]; then
  echo "No .flv files found in '$DATA_DIR'."
  exit 0
fi

echo "Found FLV files to convert:"
echo "$flv_files"
echo "---"

file_count=0
error_count=0

while IFS= read -r flv_file; do
  file_count=$((file_count + 1))

  base_name=$(basename "$flv_file")
  mp4_file="$DATA_DIR/${base_name%.*}.mp4"

  if [[ -e "$mp4_file" && "${OVERWRITE:-0}" != "1" ]]; then
    echo "Skipping '$flv_file' (output exists: '$mp4_file'). Set OVERWRITE=1 to replace."
    echo "---"
    continue
  fi

  overwrite_flag="-n"
  if [[ "${OVERWRITE:-0}" == "1" ]]; then
    overwrite_flag="-y"
  fi

  echo "Converting '$flv_file' to '$mp4_file'..."

  # Fast path: try to remux without re-encoding.
  # If codecs are incompatible with MP4, fall back to H.264/AAC re-encode.
  if ffmpeg -hide_banner -loglevel error $overwrite_flag -i "$flv_file" -c copy -movflags +faststart "$mp4_file"; then
    echo "Successfully remuxed '$flv_file'."
  else
    rm -f "$mp4_file"
    echo "Remux failed; re-encoding '$flv_file'..."
    if ffmpeg -hide_banner -loglevel error $overwrite_flag -i "$flv_file" \
      -c:v libx264 -preset "${PRESET:-medium}" -crf "${CRF:-23}" \
      -c:a aac -b:a "${AUDIO_BITRATE:-192k}" \
      -movflags +faststart \
      "$mp4_file"; then
      echo "Successfully re-encoded '$flv_file'."
    else
      echo "Error: Failed to convert '$flv_file'." >&2
      error_count=$((error_count + 1))
    fi
  fi

  echo "---"
done <<< "$flv_files"

echo "Conversion process finished."
echo "Processed $file_count files."
if [[ $error_count -gt 0 ]]; then
  echo "$error_count conversion(s) failed." >&2
  exit 1
fi
exit 0
