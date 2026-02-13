#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <EMAPPER_ANNOT> <OUTDIR>" >&2
  exit 1
fi

IN="$1"
OUTDIR="$2"
mkdir -p "$OUTDIR"
[[ -s "$IN" ]] || { echo "ERROR: not found or empty: $IN" >&2; exit 2; }

# -- find the real header (line starting with '#query', else last '#' line) --
if grep -q '^#query' "$IN"; then
  header=$(grep -m1 '^#query' "$IN" | sed 's/^#//')
else
  header=$(grep '^#' "$IN" | tail -n1 | sed 's/^#//')
fi
[[ -n "${header:-}" ]] || { echo "ERROR: could not detect header" >&2; exit 3; }

IFS=$'\t' read -r -a cols <<< "$header"
declare -A idx; for i in "${!cols[@]}"; do idx["${cols[$i]}"]=$((i+1)); done

require_col () { [[ -n "${idx[$1]:-}" ]] || { echo "WARN: column '$1' not found"; }; }

require_col "GOs"
require_col "KEGG_ko"
require_col "KEGG_Pathway"
require_col "COG_category"

GO_COL=${idx[GOs]:-}
KO_COL=${idx[KEGG_ko]:-}
PATH_COL=${idx[KEGG_Pathway]:-}
COG_COL=${idx[COG_category]:-}

# 1) GO
if [[ -n "${GO_COL:-}" ]]; then
  awk -F'\t' -v G="$GO_COL" 'BEGIN{OFS="\t"} $0!~/^#/ && $G ~ /GO:[0-9]/ {gsub(/\|/, ",", $G); print $1, $G}' "$IN" \
    | awk -F'\t' '!seen[$1,$2]++' > "$OUTDIR/eggnog_GO_by_gene.tsv" || true
fi

# 2) KO (K numbers)
if [[ -n "${KO_COL:-}" ]]; then
  awk -F'\t' -v K="$KO_COL" 'BEGIN{OFS="\t"} $0!~/^#/ && $K ~ /ko:K[0-9]+/ {gsub(/\|/, ",", $K); print $1, $K}' "$IN" \
    | awk -F'\t' '!seen[$1,$2]++' > "$OUTDIR/eggnog_KO_by_gene.tsv" || true
fi

# 3) KEGG Pathways
if [[ -n "${PATH_COL:-}" ]]; then
  awk -F'\t' -v P="$PATH_COL" 'BEGIN{OFS="\t"} $0!~/^#/ && $P ~ /(ko|map)[0-9]{5}/ {gsub(/\|/, ",", $P); print $1, $P}' "$IN" \
    | awk -F'\t' '!seen[$1,$2]++' > "$OUTDIR/eggnog_KEGG_pathway_by_gene.tsv" || true
fi

# 4) COG letter + counts
if [[ -n "${COG_COL:-}" ]]; then
  awk -F'\t' -v C="$COG_COL" 'BEGIN{OFS="\t"} $0!~/^#/ && $C ~ /^[A-Z]$/ {print $1, $C}' "$IN" \
    | awk -F'\t' '!seen[$1,$2]++' > "$OUTDIR/eggnog_COG_by_gene.tsv" || true

  if [[ -s "$OUTDIR/eggnog_COG_by_gene.tsv" ]]; then
    awk -F'\t' '{print $2}' "$OUTDIR/eggnog_COG_by_gene.tsv" | sort | uniq -c | awk '{print $2"\t"$1}' > "$OUTDIR/eggnog_COG_counts.tsv"
  fi
fi

# Simple tallies (if base tables exist)
[[ -s "$OUTDIR/eggnog_KO_by_gene.tsv" ]] && \
  awk -F'\t' '{print $2}' "$OUTDIR/eggnog_KO_by_gene.tsv" | tr ',' '\n' | sed '/^$/d' | sort | uniq -c | awk '{print $2"\t"$1}' > "$OUTDIR/eggnog_KO_counts.tsv" || true

[[ -s "$OUTDIR/eggnog_KEGG_pathway_by_gene.tsv" ]] && \
  awk -F'\t' '{print $2}' "$OUTDIR/eggnog_KEGG_pathway_by_gene.tsv" | tr ',' '\n' | sed '/^$/d' | sort | uniq -c | awk '{print $2"\t"$1}' > "$OUTDIR/eggnog_KEGG_pathway_counts.tsv" || true

echo "[DONE] eggNOG QC tables written to: $OUTDIR"

