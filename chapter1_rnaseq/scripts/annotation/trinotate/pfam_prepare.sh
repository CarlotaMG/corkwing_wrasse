#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <pfam_hmm_path> <singularity_image>"
    exit 1
fi

PFAM_HMM="$1"
SINGULARITY_IMAGE="$2"

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
        --bind "$(pwd):$(pwd)" \
        "$SINGULARITY_IMAGE" \
        hmmpress "$PFAM_HMM"
else
    echo "Pfam-A.hmm already indexed."
fi

echo "Pfam-A.hmm preparation complete."
