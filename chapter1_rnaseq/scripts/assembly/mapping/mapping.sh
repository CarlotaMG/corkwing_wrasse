#!/bin/bash

# Maps trimmed paired-end reads to the reference genome using STAR.
# Produces sorted BAM files for each sample.

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <index_dir> <trimmed_dir> <output_dir>"
    exit 1
fi

GENOME_INDEX_DIR="$1"
TRIMMED_DIR="$2"
OUTPUT_DIR="$3"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Get list of R1 files
R1_FILES=($(ls "$TRIMMED_DIR"/*_R1_paired.fastq.gz))

# Loop through each sample
for R1_FILE in "${R1_FILES[@]}"; do
    R2_FILE="${R1_FILE/_R1_paired.fastq.gz/_R2_paired.fastq.gz}"
    BASENAME=$(basename "$R1_FILE" "_R1_paired.fastq.gz")

    STAR --runThreadN 8 \
         --genomeDir "$GENOME_INDEX_DIR" \
         --readFilesIn "$R1_FILE" "$R2_FILE" \
         --readFilesCommand zcat \
         --outFileNamePrefix "${OUTPUT_DIR}/${BASENAME}_" \
         --outSAMtype BAM SortedByCoordinate
done
