#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <pep_file> <singularity_image> <pfam_hmm> <output_dir>"
    exit 1
fi


# Assign input arguments to variables
PEP_FILE="$1"
SINGULARITY_IMAGE="$2"
PFAM_HMM="$3"
OUTPUT_DIR="$4"


# Extract directory and base name of the Pfam HMM file
PFAM_DIR=$(dirname "$PFAM_HMM")
PFAM_PREFIX=$(basename "$PFAM_HMM" .hmm)


# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Download Pfam-A.hmm if missing
if [ ! -f "$PFAM_HMM" ]; then
    echo "Pfam-A.hmm not found. Downloading..."
    wget http://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz -O "${PFAM_HMM}.gz"
    gunzip "${PFAM_HMM}.gz"
fi

# Index Pfam-A.hmm if needed
if [ ! -f "${PFAM_HMM}.h3f" ] || [ ! -f "${PFAM_HMM}.h3i" ] || [ ! -f "${PFAM_HMM}.h3m" ] || [ ! -f "${PFAM_HMM}.h3p" ]; then
    echo "Indexing Pfam-A.hmm with hmmpress..."
    singularity exec \
      --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
      --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
      "$SINGULARITY_IMAGE" \
      hmmpress "$PFAM_HMM"
fi


# Wait until all files are present
while [ ! -f "${PFAM_HMM}.h3f" ] || [ ! -f "${PFAM_HMM}.h3i" ] || [ ! -f "${PFAM_HMM}.h3m" ] || [ ! -f "${PFAM_HMM}.h3p" ]; do
    echo "Waiting for hmmpress to finish..."
    sleep 5
done

# Extract base name of input file for output naming
CHUNK_NAME=$(basename "$PEP_FILE" .pep)

# Run hmmscan
echo "Running hmmscan on $CHUNK_NAME..."
singularity exec \
  --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
  --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
  "$SINGULARITY_IMAGE" \
  hmmscan \
    --domtblout "$OUTPUT_DIR/${CHUNK_NAME}.domtblout" \
    --domE 1e-5 \
    "$PFAM_HMM" "$PEP_FILE"

