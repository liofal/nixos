#!/bin/sh
set -e

# Convert all SVG files in the data/ directory to PNG
for f in data/*.svg; do
  if [ -f "$f" ]; then
    echo "Converting $f to ${f%.svg}.png"
    inkscape --export-type="png" "$f"
  fi
done