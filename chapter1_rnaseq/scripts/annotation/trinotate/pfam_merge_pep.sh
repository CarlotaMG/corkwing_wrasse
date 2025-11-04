#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <chunks_dir> <output_file>"
    exit 1
fi

chunks="$1"
out="$2"

# Create or clear output file
> "$out"

# Loop through chunk directories and merge .pep files
for dir in "$chunks"/chunk_*; do
    file="$dir/$(basename "$dir").pep"
    [ -f "$file" ] && cat "$file" >> "$out" && echo "✓ $file" || echo "⚠️ Missing $file"
done

# Final message
echo "Done: merged into $out"
