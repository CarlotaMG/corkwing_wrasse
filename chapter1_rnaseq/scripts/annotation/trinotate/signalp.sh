#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <env_dir> <pep_fasta> <output_dir> <threads>"
    exit 1
fi

# Define arguments
ENV_DIR="$1"
PEP_FASTA="$2"
OUTPUT_DIR="$3"
THREADS="$4"

# Define SignalP parameters 
ORGANISM="euk"
MODE="fast"
FORMAT="none"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=== SignalP 6.0 run ==="
echo "Environment: $ENV_DIR"
echo "Input FASTA: $PEP_FASTA"
echo "Output directory: $OUTPUT_DIR"
echo "Threads: $THREADS"
echo "Organism: $ORGANISM | Mode: $MODE | Format: $FORMAT"
echo "========================"

# Activate environment
source "$ENV_DIR/bin/activate"

# Limit threads for HPC stability
export OMP_NUM_THREADS="$THREADS"
export MKL_NUM_THREADS="$THREADS"

# Run SignalP
signalp6 --fastafile "$PEP_FASTA" \
    --output_dir "$OUTPUT_DIR" \
    --organism "$ORGANISM" \
    --mode "$MODE" \
    --format "$FORMAT" \
    --torch_num_threads "$THREADS"

STATUS=$?

# Deactivate environment
deactivate

# Check status
if [ $STATUS -eq 0 ]; then
    echo "SignalP completed successfully. Files in $OUTPUT_DIR:"
    ls -lh "$OUTPUT_DIR"
else
    echo "SignalP failed."
    exit 1
fi
