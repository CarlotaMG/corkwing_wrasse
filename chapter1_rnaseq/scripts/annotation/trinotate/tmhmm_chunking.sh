#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <pep_file> <output_dir> <max_bytes>"
    exit 1
fi

# DEfine arguments
PEP_FILE="$1"
OUTPUT_DIR="$2"
MAX_BYTES="$3"  

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"

echo "Splitting $PEP_FILE into chunks of ~<= ${MAX_BYTES} bytes each..."

# Initialize counters
chunk=0
bytes=0

# First chunk directory
dir=$(printf "%s/chunk_%03d" "$OUTPUT_DIR" "$chunk")
mkdir -p "$dir"
outfile=$(printf "%s/chunk_%03d.pep" "$dir" "$chunk")
: > "$outfile"

# Split by bytes without breaking FASTA records
awk -v MAX="$MAX_BYTES" -v BASE="$OUTPUT_DIR" '
function new_chunk() {
    chunk++
    bytes = 0
    dir = sprintf("%s/chunk_%03d", BASE, chunk)
    system("mkdir -p " dir)
    outfile = sprintf("%s/chunk_%03d.pep", dir, chunk)
    close(outfile)
}
BEGIN {
    chunk = 0
    bytes = 0
    dir = sprintf("%s/chunk_%03d", BASE, chunk)
    outfile = sprintf("%s/chunk_%03d.pep", dir, chunk)
}
/^>/ {
    # Start new chunk if adding this header exceeds the byte limit
    if (bytes >= MAX && bytes > 0) new_chunk()
}
{
    line = $0 "\n"
    if (bytes + length(line) > MAX && $0 ~ /^>/ && bytes > 0) new_chunk()
    printf "%s", line >> outfile
    bytes += length(line)
}
' "$PEP_FILE"

echo "Done: Created chunks directories under $OUTPUT_DIR"
