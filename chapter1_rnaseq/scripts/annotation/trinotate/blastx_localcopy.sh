#!/bin/bash

# Validate number of arguments (expects 4)
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <fasta_chunk> <blast_db> <output_file> <threads>"
    exit 1
fi

# Define arguments
FASTA_FILE="$1"
BLAST_DB="$2"
OUT_FILE="$3"
THREADS="$4"

echo "[$(date)] Script started."
echo "FASTA chunk: $FASTA_FILE"
echo "BLAST DB: $BLAST_DB"
echo "Output: $OUT_FILE"
echo "Threads: $THREADS"

# If LOCALSCRATCH exists (HPC local scratch), copy BLAST DB there for faster access
if [ -n "$LOCALSCRATCH" ]; then
    echo "[$(date)] LOCALSCRATCH detected: $LOCALSCRATCH"
    echo "Copying BLAST DB to LOCALSCRATCH..."
    rsync -ah "${BLAST_DB}"* "$LOCALSCRATCH/"
    if [ $? -ne 0 ]; then
        echo "[$(date)] ERROR: Failed to copy BLAST DB to LOCALSCRATCH." >&2
        exit 1
    fi
    BLAST_DB="$LOCALSCRATCH/$(basename "$BLAST_DB")"
else
    echo "[$(date)] LOCALSCRATCH not available, using original BLAST DB path."
fi

echo "[$(date)] Running blastx on transcript chunk..."

# Run Blastx
blastx \
  -query "$FASTA_FILE" \
  -db "$BLAST_DB" \
  -out "$OUT_FILE" \
  -evalue 1e-5 \
  -num_threads "$THREADS" \
  -max_target_seqs 1 \
  -outfmt 6

if [ $? -eq 0 ]; then
    echo "[$(date)] blastx finished successfully."
else
    echo "[$(date)] ERROR: blastx failed." >&2
    exit 1
fi

echo "[$(date)] Script completed."
exit 0
