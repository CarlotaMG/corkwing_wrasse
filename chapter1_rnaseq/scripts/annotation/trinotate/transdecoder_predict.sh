#!/bin/bash

# Check number of arguments
if [ "$#" -ne 6 ]; then
    echo "Expected 6 arguments: <fasta_file> <singularity_image> <blastp_hits> <pfam_hits> <output_dir> <threads>"
    exit 1
fi

FASTA_FILE="$1"
SINGULARITY_IMAGE="$2"
BLASTP_HITS="$3"
PFAM_HITS="$4"
OUTPUT_DIR="$5"
THREADS="$6"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Symlink all required files from LongOrfs step
echo "Linking LongOrfs outputs..."
ln -sf /cluster/work/users/carlota/results/annotation/trinotate/transdecoder_longorfs/* "$OUTPUT_DIR/"

# Change to output directory so checkpoints and logs stay here
cd "$OUTPUT_DIR" || { echo "Failed to cd into $OUTPUT_DIR"; exit 1; }

# Run TransDecoder.Predict
echo "Running TransDecoder.Predict with $THREADS threads..."
singularity exec \
  --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
  --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
  "$SINGULARITY_IMAGE" \
  TransDecoder.Predict \
    -t "$FASTA_FILE" \
    --retain_blastp_hits "$BLASTP_HITS" \
    --retain_pfam_hits "$PFAM_HITS" \
    --cpu "$THREADS" \
    --output_dir "$OUTPUT_DIR"

echo "TransDecoder.Predict completed. Results saved in $OUTPUT_DIR"
