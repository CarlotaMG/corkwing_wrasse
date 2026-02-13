#!/usr/bin/env bash
set -euo pipefail

# Positional arguments from the SLURM script
SIF="$1"
DB_DIR="$2"
INPUT_FASTA="$3"
OUT_PREFIX="$4"
OUT_DIR="$5"
THREADS="$6"

# Scratch directory (SAGA gives LOCALSCRATCH; otherwise use /tmp)
SCR="${LOCALSCRATCH:-/tmp}/eggnog_${OUT_PREFIX}_$$"
mkdir -p "$SCR"/{in,out,tmp,db}

# Stage input FASTA
rsync -ah "$INPUT_FASTA" "$SCR/in/input.faa"

# Stage DIAMOND DB (hot file) into scratch
rsync -ah "$DB_DIR/eggnog_proteins.dmnd" "$SCR/db/"

# Run eggNOG-mapper (fixed behaviour: DIAMOND + dbmem + PFAM realign)
# Bind the real DB dir as /db (read-only) and scratch DIAMOND as /scratchdb
EGGNOG_DATA_DIR="/db" \
apptainer exec \
  --bind "$SCR/in:/work/in" \
  --bind "$SCR/out:/work/out" \
  --bind "$SCR/tmp:/work/tmp" \
  --bind "$DB_DIR:/db:ro" \
  --bind "$SCR/db:/scratchdb" \
  "$SIF" \
  emapper.py \
    -i /work/in/input.faa \
    --output "$OUT_PREFIX" \
    --output_dir /work/out \
    --temp_dir /work/tmp \
    --data_dir /db \
    --cpu "$THREADS" \
    --override \
    --itype proteins \
    -m diamond \
    --dmnd_db /scratchdb/eggnog_proteins.dmnd \
    --dbmem \
    --pfam_realign realign

# Save results back to OUT_DIR
mkdir -p "$OUT_DIR"
rsync -ah "$SCR/out/" "$OUT_DIR/"

echo "[DONE] eggnog finished. Results saved to $OUT_DIR"
