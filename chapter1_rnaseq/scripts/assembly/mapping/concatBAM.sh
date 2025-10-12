#!/bin/bash

# Merges all individual BAM files into a single file for genome-guided Trinity assembly.

# Load SAMtools
module load SAMtools/1.16.1-GCC-11.3.0

# Check arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <bam_dir> <output_bam>"
    exit 1
fi

BAM_DIR="$1"
MERGED_BAM="$2"

# Merge BAM files
samtools merge -f "$MERGED_BAM" "$BAM_DIR"/*.bam
