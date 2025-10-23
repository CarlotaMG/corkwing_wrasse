#!/bin/bash

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <input_dir> <output_dir> <adapter_file>"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
ADAPTERS="$3"

mkdir -p "$OUTPUT_DIR"

FILES=($(ls "$INPUT_DIR"/*_R1.fastq.gz))
FILE_R1=${FILES[$SLURM_ARRAY_TASK_ID]}
FILE_R2=${FILE_R1/_R1.fastq.gz/_R2.fastq.gz}
BASENAME=$(basename "$FILE_R1" _R1.fastq.gz)

java -jar "$EBROOTTRIMMOMATIC/trimmomatic-0.39.jar" PE -threads 8 \
    "$FILE_R1" "$FILE_R2" \
    "$OUTPUT_DIR/${BASENAME}_R1_paired.fastq.gz" "$OUTPUT_DIR/${BASENAME}_R1_unpaired.fastq.gz" \
    "$OUTPUT_DIR/${BASENAME}_R2_paired.fastq.gz" "$OUTPUT_DIR/${BASENAME}_R2_unpaired.fastq.gz" \
    ILLUMINACLIP:"$ADAPTERS":2:30:10 \
    SLIDINGWINDOW:4:5 LEADING:5 TRAILING:5 MINLEN:30 MAXINFO:30:0.4 \
    HEADCROP:10 CROP:100
