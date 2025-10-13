#!/bin/bash

# Guided de novo transcriptome assembly using Trinity via Singularity.

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <bam_file> <singularity_image> <output_dir>"
    exit 1
fi

BAM_FILE="$1"
SINGULARITY_IMAGE="$2"
OUTPUT_DIR="$3"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run Trinity with Singularity
singularity exec --bind "$(dirname "$BAM_FILE")":"$(dirname "$BAM_FILE")" "$SINGULARITY_IMAGE" Trinity \
    --genome_guided_bam "$BAM_FILE" \
    --genome_guided_max_intron 20000 \
    --max_memory 160G \
    --CPU 16 \
    --SS_lib_type RF \
    --min_contig_length 300 \
    --bflyHeapSpaceMax 10G \
    --bflyCPU 16 \
    --output "$OUTPUT_DIR"
