#!/bin/bash

# Load FastQC
module load FastQC/0.12.1-Java-11

# Check arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_dir> <output_dir>"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run FastQC on all paired FASTQ files
for file in "$INPUT_DIR"/*_paired.fastq.gz; do
    fastqc -t 4 -o "$OUTPUT_DIR" "$file"
done
