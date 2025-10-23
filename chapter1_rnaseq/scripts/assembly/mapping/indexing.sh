#!/bin/bash

# Builds a STAR genome index from the reference genome.
# This index is required for mapping reads with STAR.

# Check arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <genome_fasta> <output_dir>"
    exit 1
fi

GENOME_FASTA="$1"
GENOME_INDEX_DIR="$2"

# Create output directory if it doesn't exist
mkdir -p "$GENOME_INDEX_DIR"

# Run STAR genomeGenerate
STAR --runThreadN 8 \
     --runMode genomeGenerate \
     --genomeDir "$GENOME_INDEX_DIR" \
     --genomeFastaFiles "$GENOME_FASTA" \
     --genomeSAindexNbases 13
