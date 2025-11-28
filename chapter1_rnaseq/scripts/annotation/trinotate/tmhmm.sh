#!/bin/bash

# Usage: tmhmm.sh <pep_fasta> <output_file> <tmhmm_dir>
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <pep_fasta> <output_file> <tmhmm_dir>"
    exit 1
fi

PEP_FASTA="$1"
OUTPUT_FILE="$2"
TMHMM_DIR="$3"
TMHMM_BIN="$TMHMM_DIR/bin/tmhmm"

# Check binary
if [ ! -x "$TMHMM_BIN" ]; then
    echo "Error: TMHMM binary not found at $TMHMM_BIN"
    exit 1
fi

echo "Running TMHMM on $PEP_FASTA..."
"$TMHMM_BIN" "$PEP_FASTA" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "TMHMM completed successfully. Output saved to $OUTPUT_FILE"
else
    echo "TMHMM failed."
    exit 1
fi
