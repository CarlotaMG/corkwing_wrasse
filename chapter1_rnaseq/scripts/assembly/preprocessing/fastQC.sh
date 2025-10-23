#!/bin/bash

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <input_dir> <output_dir> [threads]"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
THREADS="${3:-4}"  # Default to 4 threads if not specified

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run FastQC on all FASTQ files
for file in "$INPUT_DIR"/*.{fastq,fastq.gz}; do
    [ -e "$file" ] || continue  # Skip if no matching files
    fastqc -t "$THREADS" -o "$OUTPUT_DIR" "$file"
done
