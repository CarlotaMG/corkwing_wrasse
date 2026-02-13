#!/usr/bin/env bash
set -euo pipefail

# InterProScan QC extractor (headerless TSV)
# Input : IPS TSV (query col1; InterPro acc col12; GO terms col14 pipe-separated)
# Output: GO map + InterPro accession counts

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <IPS_TSV> <OUTDIR>" >&2
  exit 1
fi

IN="$1"
OUTDIR="$2"
mkdir -p "$OUTDIR"
[[ -s "$IN" ]] || { echo "ERROR: not found or empty: $IN" >&2; exit 2; }

# 1) GO by gene (col14)
awk -F'\t' 'BEGIN{OFS="\t"} $14 ~ /GO:[0-9]/ {go=$14; gsub(/\|/, ",", go); print $1, go}' "$IN" \
  | awk -F'\t' '!seen[$1,$2]++' > "$OUTDIR/ips_GO_by_gene.tsv" || true

# 2) InterPro accession counts (col12)
awk -F'\t' '$12 != "-" && $12 != "" {print $12}' "$IN" | sort | uniq -c | awk '{print $2"\t"$1}' > "$OUTDIR/ips_interpro_counts.tsv" || true

echo "[DONE] IPS QC tables written to: $OUTDIR"
