#!/usr/bin/env bash
set -e

# Define the data directory relative to the script location
# Inside the container, this will resolve to /tools/docx-to-pdf/data
DATA_DIR="$(dirname "$0")/data"

# Check if data directory exists
if [[ ! -d "$DATA_DIR" ]]; then
  echo "Error: Data directory '$DATA_DIR' not found." >&2
  echo "Please create 'tools/docx-to-pdf/data/' and place your .docx files inside." >&2
  exit 1
fi

# Find Word files (both .docx and .doc, case-insensitive)
word_files=$(find "$DATA_DIR" -maxdepth 1 \( -iname '*.docx' -o -iname '*.doc' \) -print)

if [[ -z "$word_files" ]]; then
  echo "No .doc or .docx files found in '$DATA_DIR'."
  exit 0
fi

echo "Found Word files to convert:"
echo "$word_files"
echo "---"

# Convert each file
file_count=0
error_count=0
while IFS= read -r word_file; do
  file_count=$((file_count + 1))
  echo "Converting '$word_file' to PDF..."
  
  # Use LibreOffice headless mode to convert to PDF
  # --convert-to pdf: Convert to PDF format
  # --outdir: Specify output directory (same as input directory)
  if libreoffice --headless --convert-to pdf --outdir "$DATA_DIR" "$word_file"; then
    # Determine the base name and construct the PDF file name
    base_name=$(basename "$word_file")
    if [[ "$base_name" == *.docx ]]; then
      pdf_file="$DATA_DIR/${base_name%.docx}.pdf"
    else
      pdf_file="$DATA_DIR/${base_name%.doc}.pdf"
    fi
    echo "Successfully converted '$word_file' to '$pdf_file'."
  else
    echo "Error: Failed to convert '$word_file'." >&2
    error_count=$((error_count + 1))
  fi
  echo "---"
done <<< "$word_files"

echo "Conversion process finished."
echo "Processed $file_count files."
if [[ $error_count -gt 0 ]]; then
  echo "$error_count conversion(s) failed." >&2
  exit 1
fi
exit 0
