#!/bin/bash

# Trimming paired-end reads with Trimmomatic

# Check input arguments
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <file_R1> <file_R2> <output_dir> <adapter_file> <threads>"
    exit 1
fi

# Assign input variables
FILE_R1="$1"
FILE_R2="$2"
OUTPUT_DIR="$3"
ADAPTERS="$4"
THREADS="$5"

# Extract sample name
BASENAME=$(basename "$FILE_R1" _R1.fastq.gz)

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run Trimmomatic with quality and adapter trimming
java -jar "$EBROOTTRIMMOMATIC/trimmomatic-0.39.jar" PE -threads "$THREADS" \
    "$FILE_R1" "$FILE_R2" \
    "$OUTPUT_DIR/${BASENAME}_R1_paired.fastq.gz" "$OUTPUT_DIR/${BASENAME}_R1_unpaired.fastq.gz" \
    "$OUTPUT_DIR/${BASENAME}_R2_paired.fastq.gz" "$OUTPUT_DIR/${BASENAME}_R2_unpaired.fastq.gz" \
    ILLUMINACLIP:"$ADAPTERS":2:30:10 \  # Adapter trimming
    SLIDINGWINDOW:4:5 \                 # Quality trimming in sliding window
    LEADING:5 TRAILING:5 \              # Trim low-quality bases from ends
    MINLEN:30 \                         # Drop short reads
    MAXINFO:30:0.4 \                    # Adaptive trimming
    HEADCROP:10 CROP:100                # Crop reads to uniform length
