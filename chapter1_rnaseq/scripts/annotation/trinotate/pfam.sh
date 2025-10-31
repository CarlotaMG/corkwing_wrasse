#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <pep_file> <singularity_image> <pfam_hmm> <output_dir> <threads>"
    exit 1
fi


# Define input arguments
PEP_FILE="$1"
SINGULARITY_IMAGE="$2"
PFAM_HMM="$3"
OUTPUT_DIR="$4"
THREADS="$5"

# Extract directory and base name of Pfam HMM file
PFAM_DIR=$(dirname "$PFAM_HMM")
PFAM_PREFIX=$(basename "$PFAM_HMM" .hmm)

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Download Pfam-A.hmm if missing
if [ ! -f "$PFAM_HMM" ]; then
    echo "Pfam-A.hmm not found. Downloading..."
    wget http://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz -O "${PFAM_HMM}.gz"
    gunzip "${PFAM_HMM}.gz"
fi

# Index Pfam-A.hmm if needed
if [ ! -f "${PFAM_HMM}.h3f" ]; then
    echo "Indexing Pfam-A.hmm with hmmpress..."
    singularity exec \
      --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
      --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
      "$SINGULARITY_IMAGE" \
      hmmpress "$PFAM_HMM"
fi

# Run hmmscan with domain E-value threshold
echo "Running hmmscan..."
singularity exec \
  --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
  --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
  "$SINGULARITY_IMAGE" \
  hmmscan --cpu "$THREADS" \
          --domtblout "$OUTPUT_DIR/pfam.domtblout" \
          --domE 1e-5 \
          "$PFAM_HMM" "$PEP_FILE"
