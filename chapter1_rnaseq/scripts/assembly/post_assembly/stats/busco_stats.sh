#!/bin/bash

# Check arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <input_fasta> <lineage_dataset> <output_dir> [num_threads]"
    exit 1
fi

INPUT_FASTA="$1"
LINEAGE="$2"
OUTPUT_DIR="$3"
THREADS="${4:-1}"  # Default to 1 thread if not provided

# Load BUSCO module
module load BUSCO/5.5.0-foss-2022b

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Change to output directory to contain all BUSCO artifacts
cd "$OUTPUT_DIR" || exit


# Run BUSCO with specified number of threads
busco -i "../../../../../$INPUT_FASTA" \
      -l "$LINEAGE" \
      -o busco_run \
      -m transcriptome \
      -c "$THREADS" \
      --out_path .
