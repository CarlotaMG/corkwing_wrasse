#!/bin/bash

# Usage: blastp.sh <pep_file> <singularity_image> <fasta_file> <output_dir>
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <pep_file> <singularity_image> <fasta_file> <output_dir>"
    exit 1
fi

PEP_FILE="$1"
SINGULARITY_IMAGE="$2"
DB_FASTA="$3"
OUTPUT_DIR="$4"

# Derive BLAST DB prefix from FASTA filename
BLAST_DB_DIR=$(dirname "$DB_FASTA")
BLAST_DB_PREFIX=$(basename "$DB_FASTA" .fasta)
BLAST_DB="$BLAST_DB_DIR/$BLAST_DB_PREFIX"

# Create BLAST DB directory if it doesn't exist
mkdir -p "$BLAST_DB_DIR"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Download Swiss-Prot if FASTA file is missing
if [ ! -f "$DB_FASTA" ]; then
    echo "FASTA file not found. Downloading UniProtKB/Swiss-Prot..."
    wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz \
         -O "${DB_FASTA}.gz"
    gunzip "${DB_FASTA}.gz"
fi
# Create BLAST DB if not already present
if [ ! -f "${BLAST_DB}.pin" ]; then
    echo "Creating BLAST database..."
    singularity exec \
      --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
      --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
      "$SINGULARITY_IMAGE" \
      makeblastdb -in "$DB_FASTA" -dbtype prot -out "$BLAST_DB"
else
    echo "BLAST database already exists. Skipping creation."
fi

# Run BLASTP
echo "Running BLASTP..."
singularity exec \
  --bind /cluster/projects/nn12014k:/cluster/projects/nn12014k \
  --bind /cluster/work/users/carlota:/cluster/work/users/carlota \
  "$SINGULARITY_IMAGE" \
  blastp -query "$PEP_FILE" -db "$BLAST_DB" -out "$OUTPUT_DIR/blastp.outfmt6" -evalue 1e-5 -num_threads 8 -max_target_seqs 5 -outfmt 6

