#!/usr/bin/env bash
set -e

# Define the data directory relative to the script location
# Inside the container, this will resolve to /tools/ps-to-pdf/data
DATA_DIR="$(dirname "$0")/data"

# Check if data directory exists
if [[ ! -d "$DATA_DIR" ]]; then
  echo "Error: Data directory '$DATA_DIR' not found." >&2
  echo "Please create 'tools/ps-to-pdf/data/' and place your .ps files inside." >&2
  exit 1
fi

# Find PostScript files
ps_files=$(find "$DATA_DIR" -maxdepth 1 -name '*.ps' -print)

if [[ -z "$ps_files" ]]; then
  echo "No .ps files found in '$DATA_DIR'."
  exit 0
fi

echo "Found PostScript files to convert:"
echo "$ps_files"
echo "---"

# Convert each file
file_count=0
error_count=0
while IFS= read -r ps_file; do
  file_count=$((file_count + 1))
  pdf_file="$DATA_DIR/$(basename "$ps_file" .ps).pdf"
  echo "Converting '$ps_file' to '$pdf_file'..."
  if gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -sOutputFile="$pdf_file" "$ps_file"; then
    echo "Successfully converted '$ps_file'."
  else
    echo "Error: Failed to convert '$ps_file'." >&2
    error_count=$((error_count + 1))
  fi
  echo "---"
done <<< "$ps_files"

echo "Conversion process finished."
echo "Processed $file_count files."
if [[ $error_count -gt 0 ]]; then
  echo "$error_count conversion(s) failed." >&2
  exit 1
fi
exit 0
