#!/bin/bash

# Ensure correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <chunks_dir> <merged_dir>"
    exit 1
fi

# Define arguments
CHUNKS_DIR="$1"    # Path to chunks directory
MERGED_DIR="$2"    # Path to final merged output directory

# Ensure merged directory exists
mkdir -p "$MERGED_DIR"

# Define output files
MERGED_PRED="$MERGED_DIR/signalp_merged.prediction_results.txt"
MERGED_GFF="$MERGED_DIR/signalp_merged.output.gff3"

# Initialize merged files
echo "# SignalP merged predictions" > "$MERGED_PRED"
echo "##gff-version 3" > "$MERGED_GFF"

# Merge all chunks
for CHUNK in "$CHUNKS_DIR"/chunk_*; do
    OUT_DIR="$CHUNK/signalp_out"

    # Merge prediction results
    tail -n +3 "$OUT_DIR/prediction_results.txt" >> "$MERGED_PRED"

    # Merge GFF3 output 
    grep -v "^##" "$OUT_DIR/output.gff3" >> "$MERGED_GFF"
done

echo "Merge complete."
echo "Final prediction file: $MERGED_PRED"
echo "Final GFF3 file: $MERGED_GFF"
