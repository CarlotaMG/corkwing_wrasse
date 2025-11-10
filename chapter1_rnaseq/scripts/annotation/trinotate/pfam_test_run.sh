#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <pep_file> <singularity_image> <pfam_hmm_file> <output_dir>"
    exit 1
fi


# Define input arguments
PEP_FILE="$1"
SINGULARITY_IMAGE="$2"
PFAM_HMM="$3"
OUTPUT_DIR="$4"

# Hmmscan command
singularity exec \
  --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
  --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
  "$SINGULARITY_IMAGE" \
  hmmscan \
    --domtblout "$OUTPUT_DIR/test.domtblout" \
    --domE 1e-2 \
    "$PFAM_HMM" \
    "$PEP_FILE"
