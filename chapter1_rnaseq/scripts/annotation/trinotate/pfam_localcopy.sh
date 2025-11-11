#!/bin/bash

# Validate number of arguments (expects 4)
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <pep_file> <pfam_hmm_file> <output_file> <threads>"
    exit 1
fi

# Define input arguments
PEP_FILE="$1"
PFAM_HMM="$2"
OUT_FILE="$3"
THREADS="$4"

echo "[$(date)] Script started."
echo "Peptide file: $PEP_FILE"
echo "Pfam DB: $PFAM_HMM"
echo "Output: $OUT_FILE"
echo "Threads: $THREADS"

# If TMPDIR exists (HPC local scratch), copy Pfam DB there for faster access
if [ -n "$TMPDIR" ]; then
    echo "[$(date)] TMPDIR detected: $TMPDIR"
    echo "Copying Pfam DB to TMPDIR..."
    rsync -ah "${PFAM_HMM}"* "$TMPDIR/"
    if [ $? -ne 0 ]; then
        echo "[$(date)] ERROR: Failed to copy Pfam DB to TMPDIR." >&2
        exit 1
    fi
    PFAM_HMM="$TMPDIR/$(basename "$PFAM_HMM")"
else
    echo "[$(date)] TMPDIR not set, using original Pfam DB path."
fi

echo "[$(date)] Running hmmscan on peptide chunk..."

# Run hmmscan with Pfam HMM database
hmmscan \
  --cpu "$THREADS" \
  --domtblout "$OUT_FILE" \
  --domE 1e-2 \
  --noali \
  --acc \
  "$PFAM_HMM" \
  "$PEP_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date)] hmmscan finished successfully."
else
    echo "[$(date)] ERROR: hmmscan failed." >&2
    exit 1
fi

echo "[$(date)] Script completed."
exit 0
