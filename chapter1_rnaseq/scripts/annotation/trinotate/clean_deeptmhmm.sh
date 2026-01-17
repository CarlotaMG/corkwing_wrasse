#!/usr/bin/env bash
# Convert DeepTMHMM "GFF-like" 4-column output to valid 9-column GFF3
# Keeps only TMhelix features (alpha-helical), drops inside/outside
# Usage: bash clean_deeptmhmm.sh IN_GFF OUT_GFF

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input_gff> <output_gff>" >&2
  exit 1
fi

IN="$1"
OUT="$2"

# Ensure input exists
if [[ ! -s "$IN" ]]; then
  echo "[ERROR] Input file missing or empty: $IN" >&2
  exit 1
fi

# Create parent dir of OUT if needed
mkdir -p "$(dirname "$OUT")"

# Write a valid GFF3 header and convert lines
{
  echo "##gff-version 3"
  echo "##converted-by=clean_deeptmhmm.sh"
  echo "##date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  awk '
    BEGIN { OFS="\t" }
    # Skip comment and chunk separator lines
    /^#/ { next }
    /^\/\// { next }

    # Accept whitespace- or tab-delimited 4-column lines:
    # seqid  state  start  end
    {
      # Trim to 4 fields even if extra spaces
      seqid=$1; type=$2; start=$3; end=$4;

      # Basic sanity checks
      if (seqid == "" || type == "" || start == "" || end == "") next;
      if (start !~ /^[0-9]+$/ || end !~ /^[0-9]+$/) next;

      # Keep only TMhelix for Trinotate
      if (type != "TMhelix") next;

      # Normalize values for GFF3 (9 columns)
      source="DeepTMHMM";
      score=".";
      strand=".";
      phase=".";

      # Make a stable ID per feature
      attr="ID=" seqid "_TMhelix_" start "_" end;

      print seqid, source, type, start, end, score, strand, phase, attr;
    }
  ' "$IN"
} > "$OUT"

# Quick validation: ensure we produced at least one TMhelix
if ! grep -q "^#" "$OUT"; then
  echo "[ERROR] Output missing header (unexpected)." >&2
  exit 1
fi

TMN=$(grep -cv "^#" "$OUT" || true)
echo "[INFO] Wrote $TMN TMhelix features to: $OUT"

if [[ $TMN -eq 0 ]]; then
  echo "[WARN] No TMhelix rows found. The output is valid but empty for Trinotate loading."
fi
