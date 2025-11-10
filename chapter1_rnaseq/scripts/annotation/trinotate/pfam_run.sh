#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <pep_file> <singularity_image> <pfam_hmm> <output_dir>"
    exit 1
fi

# Input arguments
PEP_FILE="$1"
SINGULARITY_IMAGE="$2"
PFAM_HMM="$3"
OUTPUT_DIR="$4"

# Extract base names
CHUNK_NAME=$(basename "$PEP_FILE" .pep)
PFAM_BASENAME=$(basename "$PFAM_HMM")

# Use chunk directory as local Pfam directory
LOCAL_PFAM_DIR="$OUTPUT_DIR"
echo "Using chunk directory for Pfam files: $LOCAL_PFAM_DIR"
mkdir -p "$LOCAL_PFAM_DIR"

# Rsync Pfam-A.hmm and index files to chunk directory
echo "Copying Pfam-A.hmm and index files to $LOCAL_PFAM_DIR..."
rsync -av ${PFAM_HMM}* "$LOCAL_PFAM_DIR/"
echo "Copy complete. Contents of $LOCAL_PFAM_DIR:"
ls -lh "$LOCAL_PFAM_DIR"

# Run hmmscan using local Pfam copy
echo "Running hmmscan on $CHUNK_NAME..."
singularity exec \
  --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
  --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
  "$SINGULARITY_IMAGE" \
  hmmscan \
    --domtblout "$OUTPUT_DIR/${CHUNK_NAME}.domtblout" \
    --domE 1e-2 \
    "$LOCAL_PFAM_DIR/$PFAM_BASENAME" "$PEP_FILE"
