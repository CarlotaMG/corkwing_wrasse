#!/bin/bash

# Run TrinityStats.pl on a Trinity-assembled transcriptome using Singularity.

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <trinity_fasta> <singularity_image> <output_file>"
    exit 1
fi

TRINITY_FASTA="$1"
SINGULARITY_IMAGE="$2"
OUTPUT_FILE="$3"

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Run TrinityStats.pl inside the Singularity container
singularity exec --bind "$(dirname "$TRINITY_FASTA")":"$(dirname "$TRINITY_FASTA")" "$SINGULARITY_IMAGE" \
    /usr/local/bin/util/TrinityStats.pl "$TRINITY_FASTA" > "$OUTPUT_FILE"
