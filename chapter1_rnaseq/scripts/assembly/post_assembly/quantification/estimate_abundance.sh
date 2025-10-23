#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <left_reads> <right_reads> <transcriptome_fasta> <singularity_image> <output_dir> <thread_count>"
    exit 1
fi

# Assign input arguments to variables
LEFT_READS="$1"
RIGHT_READS="$2"
TRINITY_ASSEMBLY="$3"
SINGULARITY_IMAGE="$4"
OUTPUT_DIR="$5"
THREAD_COUNT="$6"

# Extract sample name from left reads filename
BASENAME=$(basename "$LEFT_READS" _R1_paired.fastq.gz)

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run Trinity utility script inside Singularity to estimate transcript abundance using RSEM
singularity exec --bind "$(pwd):$(pwd)" "$SINGULARITY_IMAGE" \
    /usr/local/bin/util/align_and_estimate_abundance.pl \
    --transcripts "$TRINITY_ASSEMBLY" \
    --seqType fq \
    --left "$LEFT_READS" \
    --right "$RIGHT_READS" \
    --est_method RSEM \
    --aln_method bowtie2 \
    --trinity_mode \
    --prep_reference \
    --thread_count "$THREAD_COUNT" \
    --output_dir "$OUTPUT_DIR/rsem_${BASENAME}" \
    1>"$OUTPUT_DIR/rsem_${BASENAME}.out" 2>"$OUTPUT_DIR/rsem_${BASENAME}.err"
