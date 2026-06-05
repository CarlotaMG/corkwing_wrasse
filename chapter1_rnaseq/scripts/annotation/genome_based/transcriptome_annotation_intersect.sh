#!/bin/bash

# Intersects transcriptome alignment with genome annotation.
# Includes header standardisation to match GFF sequence identifiers.

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <input_sorted.bam> <annotation.gff.gz> <output_dir>"
    exit 1
fi

INPUT_BAM="$1"
GFF="$2"
OUTPUT_DIR="$3"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Define output files
OUTPUT_FILE="${OUTPUT_DIR}/transcriptome_annotation_intersection.bed.gz"
TMP_HEADER="${OUTPUT_DIR}/header.sam"
NEW_HEADER="${OUTPUT_DIR}/new_header.sam"
CORRECTED_BAM="${OUTPUT_DIR}/corrected_tmp.bam"

echo "Starting intersection workflow..."

echo "Extracting BAM header..."
samtools view -H "$INPUT_BAM" > "$TMP_HEADER"

echo "Standardising sequence identifiers..."
sed -E 's/SN:[^|]*\|[^|]*\|/SN:/g' "$TMP_HEADER" > "$NEW_HEADER"

echo "Rebuilding BAM with corrected header..."
samtools reheader "$NEW_HEADER" "$INPUT_BAM" > "$CORRECTED_BAM"

echo "Running bedtools intersect..."
bedtools intersect \
    -abam "$CORRECTED_BAM" \
    -b <(zcat "$GFF") \
    -wa -wb -bed | gzip > "$OUTPUT_FILE"

echo "Cleaning up intermediate files..."
rm "$TMP_HEADER" "$NEW_HEADER" "$CORRECTED_BAM"

echo "Intersection completed successfully!"
echo "Output:"
echo "  $OUTPUT_FILE"
