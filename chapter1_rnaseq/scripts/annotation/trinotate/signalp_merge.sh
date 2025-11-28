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
MERGED_GFF="$MERGED_DIR/signalp_merged.region_output.gff3"

# Initialize merged files
echo "# SignalP merged predictions" > "$MERGED_PRED"
echo "##gff-version 3" > "$MERGED_GFF"

# Merge all chunks
for CHUNK in "$CHUNKS_DIR"/chunk_*; do
    OUT_DIR="$CHUNK/signalp_out"
    cat "$OUT_DIR/prediction_results.txt" >> "$MERGED_PRED"
    grep -v "^##gff-version" "$OUT_DIR/region_output.gff3" >> "$MERGED_GFF"
done

# Overwrite original file with clean version (remove first two comment lines)
tail -n +3 "$MERGED_PRED" > "$MERGED_PRED.tmp" && mv "$MERGED_PRED.tmp" "$MERGED_PRED"

echo "Merge complete."
echo "Final Trinotate-ready file: $MERGED_PRED"
echo "Merged GFF file: $MERGED_GFF"
