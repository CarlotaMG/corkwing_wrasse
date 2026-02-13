#!/usr/bin/env bash

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <pep_fasta> <out_dir> <threads>" >&2
  exit 1
fi

PEP_FASTA="$1"
OUTDIR="$2"
THREADS="$3"

if [[ ! -s "$PEP_FASTA" ]]; then
  echo "ERROR: peptide FASTA not found or empty: $PEP_FASTA" >&2
  exit 1
fi

mkdir -p "$OUTDIR"

# Output base (e.g., chunk_000)
BASENAME="$(basename "$PEP_FASTA")"
BASENAME="${BASENAME%.*}"
OUT_BASE="${OUTDIR}/${BASENAME}"

# Temp directory: prefer node-local scratch
if [[ -n "${LOCALSCRATCH:-}" ]]; then
  TMPDIR="${LOCALSCRATCH}/ips_${SLURM_JOB_ID:-$$}"
else
  TMPDIR="/tmp/ips_${SLURM_JOB_ID:-$$}"
fi
mkdir -p "$TMPDIR"

# Check InterProScan availability
if ! command -v interproscan.sh >/dev/null 2>&1; then
  echo "ERROR: interproscan.sh not found in PATH. Load the InterProScan module in the job script." >&2
  exit 1
fi

echo "[$(date)] IPS start | fasta=$PEP_FASTA | out=$OUT_BASE | cpu=$THREADS | tmp=$TMPDIR"

# Core IPS run: TSV for Trinotate, GFF3 for inspection
interproscan.sh \
  --input "$PEP_FASTA" \
  --formats TSV,GFF3 \
  --iprlookup \
  --goterms \
  --disable-precalc \
  -T "$TMPDIR" \
  --cpu "$THREADS" \
  --output-file-base "$OUT_BASE"

echo "[$(date)] IPS done  | outputs: ${OUT_BASE}.interproscan.tsv and .gff3"
