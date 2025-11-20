#!/bin/bash

# Define arguments
FASTA_FILE="$1"
OUTPUT_DIR="$2"
CHUNK_SIZE=2000  

echo "[$(date)] Starting BLASTX chunking..."
echo "Input FASTA: $FASTA_FILE"
echo "Output directory: $OUTPUT_DIR"
echo "Chunk size: $CHUNK_SIZE"

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"

# Count total sequences
TOTAL_SEQS=$(grep -c "^>" "$FASTA_FILE")
NUM_CHUNKS=$(( (TOTAL_SEQS + CHUNK_SIZE - 1) / CHUNK_SIZE ))  # Round up

echo "[$(date)] Splitting $TOTAL_SEQS sequences into $NUM_CHUNKS chunks of ~${CHUNK_SIZE} sequences each..."

# Split using awk
awk -v n=$CHUNK_SIZE -v base="$OUTPUT_DIR" '
BEGIN {
    chunk=0; count=0;
    dir=sprintf("%s/chunk_%03d", base, chunk);
    system("mkdir -p " dir);
    file=sprintf("%s/chunk_%03d.fa", dir, chunk);
}
/^>/ {
    if (count >= n) {
        chunk++; count=0;
        dir=sprintf("%s/chunk_%03d", base, chunk);
        system("mkdir -p " dir);
        file=sprintf("%s/chunk_%03d.fa", dir, chunk);
    }
    count++;
}
{ print >> file }
' "$FASTA_FILE"

echo "[$(date)] Done: Created $NUM_CHUNKS chunks under $OUTPUT_DIR"
