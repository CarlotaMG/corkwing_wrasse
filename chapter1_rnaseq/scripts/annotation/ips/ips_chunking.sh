#!/usr/bin/env bash

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <pep_file> <chunks_dir> [chunk_size]" >&2
  exit 1
fi

PEP_IN="$1"
CHUNKS_DIR="$2"
CHUNK_SIZE="${3:-32000}"

if [[ ! -s "$PEP_IN" ]]; then
  echo "ERROR: peptide FASTA not found or empty: $PEP_IN" >&2
  exit 1
fi

mkdir -p "$CHUNKS_DIR"

CLEANED="${PEP_IN%.pep}.cleaned.pep"
echo "Cleaning '*' from: $PEP_IN -> $CLEANED"
# Create cleaned file (only if needed)
if grep -q '\*' "$PEP_IN"; then
  sed 's/*//g' "$PEP_IN" > "$CLEANED"
else
  # No '*' found; copy as-is to keep a deterministic 'cleaned' file in provenance
  cp -f "$PEP_IN" "$CLEANED"
fi

TOTAL_SEQS=$(grep -c '^>' "$CLEANED")
if [[ "$TOTAL_SEQS" -eq 0 ]]; then
  echo "ERROR: No FASTA headers (>) found in $CLEANED" >&2
  exit 1
fi

NUM_CHUNKS=$(( (TOTAL_SEQS + CHUNK_SIZE - 1) / CHUNK_SIZE ))
echo "Splitting $TOTAL_SEQS sequences into $NUM_CHUNKS chunks of ~${CHUNK_SIZE} seqs each..."
echo "Output root: $CHUNKS_DIR"

# Split cleaned FASTA
awk -v n="$CHUNK_SIZE" -v base="$CHUNKS_DIR" '
BEGIN {
  chunk=0; count=0;
  dir=sprintf("%s/chunk_%03d", base, chunk);
  system("mkdir -p " dir);
  file=sprintf("%s/chunk_%03d.pep", dir, chunk);
}
/^>/ {
  if (count >= n) {
    chunk++; count=0;
    dir=sprintf("%s/chunk_%03d", base, chunk);
    system("mkdir -p " dir);
    file=sprintf("%s/chunk_%03d.pep", dir, chunk);
  }
  count++;
}
{ print >> file }
' "$CLEANED"

echo "Done. Created $NUM_CHUNKS chunks under: $CHUNKS_DIR"
echo "Cleaned file recorded for provenance: $CLEANED"
