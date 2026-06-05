#!/bin/bash

# Aligns a transcriptome FASTA file to a reference genome using minimap2.
# Produces SAM, BAM, sorted BAM, and BAM index files.

# Check arguments
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <transcriptome.fasta> <reference_genome.fasta> <output_dir> [threads]"
    exit 1
fi

TRANSCRIPTOME="$1"
REFERENCE_GENOME="$2"
OUTPUT_DIR="$3"
THREADS="${4:-4}"  # default: 4 threads

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Define output files
SAM_FILE="${OUTPUT_DIR}/alignment.sam"
BAM_FILE="${OUTPUT_DIR}/alignment.bam"
SORTED_BAM_FILE="${OUTPUT_DIR}/alignment.sorted.bam"

echo "Starting transcriptome alignment..."

# Step 1: Align transcriptome to genome (splice-aware)
minimap2 -ax splice -t "$THREADS" "$REFERENCE_GENOME" "$TRANSCRIPTOME" > "$SAM_FILE"

# Step 2: Convert SAM to BAM
samtools view -Sb "$SAM_FILE" > "$BAM_FILE"

# Step 3: Sort BAM
samtools sort "$BAM_FILE" -o "$SORTED_BAM_FILE"

# Step 4: Index BAM
samtools index "$SORTED_BAM_FILE"

echo "Alignment completed successfully!"
echo "Output files:"
echo "  $SORTED_BAM_FILE"
echo "  ${SORTED_BAM_FILE}.bai"
