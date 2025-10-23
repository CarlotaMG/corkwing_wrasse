#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <rsem_dir> <gene_trans_map> <singularity_image> <output_dir>"
    exit 1
fi

# Assign input arguments to variables
RSEM_DIR="$1"
GENE_TRANS_MAP="$2"
SINGULARITY_IMAGE="$3"
OUTPUT_DIR="$4"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Create dummy file to avoid header issues in matrix compilation
DUMMY="$RSEM_DIR/dummy_RSEM.genes.results"
echo -e "gene_id\ttranscript_id(s)\tlength\teffective_length\texpected_count\tTPM\tFPKM" > "$DUMMY"

# Collect RSEM result files
GENE_FILES=$(find "$RSEM_DIR" -name "RSEM.genes.results" | sort -V)
ISOFORM_FILES=$(find "$RSEM_DIR" -name "RSEM.isoforms.results" | sort -V)

# Prepend dummy file to avoid header mismatch
GENE_FILES="$DUMMY $GENE_FILES"
ISOFORM_FILES="$DUMMY $ISOFORM_FILES"

# Compile gene-level abundance matrix
singularity exec --bind "$(pwd):$(pwd)" "$SINGULARITY_IMAGE" \
    /usr/local/bin/util/abundance_estimates_to_matrix.pl \
    --est_method RSEM \
    --out_prefix "$OUTPUT_DIR/abundance_matrix_genes" \
    --gene_trans_map "$GENE_TRANS_MAP" \
    --name_sample_by_basedir \
    $GENE_FILES | grep -v "TRINITY_DUMMY"

# Compile isoform-level abundance matrix
singularity exec --bind "$(pwd):$(pwd)" "$SINGULARITY_IMAGE" \
    /usr/local/bin/util/abundance_estimates_to_matrix.pl \
    --est_method RSEM \
    --out_prefix "$OUTPUT_DIR/abundance_matrix_isoforms" \
    --gene_trans_map "$GENE_TRANS_MAP" \
    --name_sample_by_basedir \
    $ISOFORM_FILES | grep -v "TRINITY_DUMMY"
