#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <rsem_dir> <singularity_image> <output_dir>"
    exit 1
fi

# Assign input arguments to variables
RSEM_DIR="$1"
SINGULARITY_IMAGE="$2"
OUTPUT_DIR="$3"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Initialize combined output file with header
echo -e "FPKM_threshold_genes\tnum_features_genes\tFPKM_threshold_isoforms\tnum_features_isoforms" > "$OUTPUT_DIR/cumul_counts_combined.txt"

# Loop through each sample directory
for sample_dir in "$RSEM_DIR"/rsem_*; do
    if [ -d "$sample_dir" ]; then
        GENE_RESULTS="$sample_dir/RSEM.genes.results"
        ISOFORM_RESULTS="$sample_dir/RSEM.isoforms.results"

        # Count gene-level features above FPKM thresholds
        singularity exec --bind "$(pwd):$(pwd)" "$SINGULARITY_IMAGE" \
            /usr/local/bin/util/misc/count_features_given_MIN_FPKM_threshold.pl "$GENE_RESULTS" \
            > "$OUTPUT_DIR/cumul_counts_genes_${sample_dir##*/}.txt"

        # Count isoform-level features above FPKM thresholds
        singularity exec --bind "$(pwd):$(pwd)" "$SINGULARITY_IMAGE" \
            /usr/local/bin/util/misc/count_features_given_MIN_FPKM_threshold.pl "$ISOFORM_RESULTS" \
            > "$OUTPUT_DIR/cumul_counts_isoforms_${sample_dir##*/}.txt"

        # Combine gene and isoform counts into one line
        paste <(tail -n +2 "$OUTPUT_DIR/cumul_counts_genes_${sample_dir##*/}.txt") \
              <(tail -n +2 "$OUTPUT_DIR/cumul_counts_isoforms_${sample_dir##*/}.txt") \
              >> "$OUTPUT_DIR/cumul_counts_combined.txt"
    fi
done
