#!/bin/bash

# Run BUSCO on a Trinity-assembled transcriptome using the Saga module system.

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <input_fasta> <lineage_dataset> <output_dir>"
    exit 1
fi

INPUT_FASTA="$1"
LINEAGE="$2"
OUTPUT_DIR="$3"

# Load BUSCO module 
module load BUSCO/5.5.0-foss-2022b

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run BUSCO
busco -i "$INPUT_FASTA" \
      -l "$LINEAGE" \
      -o "$(basename "$OUTPUT_DIR")" \
      -m transcriptome \
      --out_path "$OUTPUT_DIR"
