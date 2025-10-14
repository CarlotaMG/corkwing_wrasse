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

# Change to output directory to contain all BUSCO artifacts
cd "$OUTPUT_DIR" || exit

# Run BUSCO using relative path to input FASTA
busco -i "../../../../../$INPUT_FASTA" \
      -l "$LINEAGE" \
      -o busco \
      -m transcriptome \
      --out_path .
