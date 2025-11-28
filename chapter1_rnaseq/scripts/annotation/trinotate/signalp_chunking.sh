#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <pep_file> <output_dir>"
    exit 1
fi

# Define arguments
PEP_FILE="$1"
OUTPUT_DIR="$2"
CHUNK_SIZE=10000

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Count total sequences
TOTAL_SEQS=$(grep -c "^>" "$PEP_FILE")
NUM_CHUNKS=$(( (TOTAL_SEQS + CHUNK_SIZE - 1) / CHUNK_SIZE ))  # Round up

echo "Splitting $TOTAL_SEQS sequences into $NUM_CHUNKS chunks of ~${CHUNK_SIZE} sequences each..."

# Split FASTA into chunks
awk -v n=$CHUNK_SIZE -v base="$OUTPUT_DIR" '
BEGIN {
    chunk=0; count=0;
    dir=sprintf("%s/chunk_%03d", base, chunk);
    system("mkdir -p " dir);
    file=sprintf("%s/chunk_%03d.pep", dir, chunk);
}
/^>/ {
    if (count >= n) {
        chunk++; count=0;
        dir=sprintf("%s/chunk_%03d", base, chunk);
        system("mkdir -p " dir);
        file=sprintf("%s/chunk_%03d.pep", dir, chunk);
    }
    count++;
}
{ print >> file }
' "$PEP_FILE"

echo "Done: Created $NUM_CHUNKS chunks under $OUTPUT_DIR"
