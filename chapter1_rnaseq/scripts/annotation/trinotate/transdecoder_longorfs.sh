#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <transcriptome_fasta> <gene_trans_map> <singularity_image> <output_dir>"
    exit 1
fi

TRANSCRIPTOME="$1"
GENE_TRANS_MAP="$2"
SINGULARITY_IMAGE="$3"
OUTPUT_DIR="$4"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run TransDecoder.LongOrfs inside Singularity
singularity exec \
  --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
  --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
  "$SINGULARITY_IMAGE" \
  bash -c "TransDecoder.LongOrfs -t '$TRANSCRIPTOME' --gene_trans_map '$GENE_TRANS_MAP' -O '$OUTPUT_DIR'"


# singularity exec --bind "$(pwd):$(pwd)" "$SINGULARITY_IMAGE" \
#  TransDecoder.LongOrfs -t "$TRANSCRIPTOME" \
#  --gene_trans_map "$GENE_TRANS_MAP" \
#  -O "$OUTPUT_DIR"
