#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Usage: $0 <trinotate_report.xls> <tmhmm.gff3> <outdir>" >&2
    exit 1
fi

TRINO="$1"
TMGFF="$2"
OUT="$3"
mkdir -p "$OUT"

# --- helper: convert transcript → gene ---
TO_GENE='
  function to_gene(id, g){
    g=id
    sub(/\.p[0-9]+$/, "", g)
    sub(/_i[0-9]+$/, "", g)
    return g
  }
'

############################
# 1) SignalP (gene-level) and transcript flags
############################
awk -F'\t' -v OFS='\t' '
  '"$TO_GENE"'
  NR==1 {
    for(i=1;i<=NF;i++) {
      if($i=="transcript_id") tid=i
      if($i=="SignalP") sp=i
    }
    next
  }
  {
    t=$tid
    v=$sp
    pos = (v!="." && v!="") ? 1 : 0
    g=to_gene(t)
    seen[g]=1
    if(pos) sig[g]=1
    print t, pos > "'"$OUT/signalp_deeptmhmm_by_transcript.tsv.tmp_sp"'"
  }
  END {
    print "gene_id","signalp_pos" > "'"$OUT/signalp_by_gene.collapsed.tsv"'"
    for(g in seen)
      print g, (sig[g]?1:0) >> "'"$OUT/signalp_by_gene.collapsed.tsv"'"
  }
' "$TRINO"

sort -o "$OUT/signalp_by_gene.collapsed.tsv" "$OUT/signalp_by_gene.collapsed.tsv"

################################
# 2) DeepTMHMM (gene + transcript; normalize to transcript IDs)
################################
awk -v OFS='\t' '
  function to_gene(id, g){ g=id; sub(/\.p[0-9]+$/, "", g); sub(/_i[0-9]+$/, "", g); return g }
  function to_tx(id, t){ t=id; sub(/\.p[0-9]+$/, "", t); return t }

  BEGIN { FS="\t" }
  /^#/ || /^\/\// || NF<2 { next }

  {
    raw=$1
    type3=$3
    type2=$2   # some raw files mark TMhelix in column 2

    isHelix = (type3=="TMhelix" || type2=="TMhelix")

    tx = to_tx(raw)
    g  = to_gene(tx)

    seenG[g]=1
    seenT[tx]=1
    if(isHelix) { tmG[g]=1; tmT[tx]=1 }
  }
  END {
    print "gene_id","tmhmm_pos" > "'"$OUT/deeptmhmm_by_gene.collapsed.tsv"'"
    for(g in seenG) print g, (tmG[g]?1:0) >> "'"$OUT/deeptmhmm_by_gene.collapsed.tsv"'"

    # transcript-level flags normalized to transcript IDs (no .p<nr>)
    for(t in seenT) print t, (tmT[t]?1:0) >> "'"$OUT/signalp_deeptmhmm_by_transcript.tsv.tmp_tm"'"
  }
' "$TMGFF"

sort -o "$OUT/deeptmhmm_by_gene.collapsed.tsv" "$OUT/deeptmhmm_by_gene.collapsed.tsv"

################################
# 3) Join transcript-level tables (both are transcript IDs now)
################################
join -t $'\t' -a1 -a2 -e 0 -o 0,1.2,2.2 \
    <(sort "$OUT/signalp_deeptmhmm_by_transcript.tsv.tmp_sp") \
    <(sort "$OUT/signalp_deeptmhmm_by_transcript.tsv.tmp_tm") \
  | awk -v OFS='\t' 'BEGIN{print "transcript_id","signalp_pos","tmhmm_pos"}{print}' \
  > "$OUT/signalp_deeptmhmm_by_transcript.tsv"

rm -f "$OUT/signalp_deeptmhmm_by_transcript.tsv.tmp_sp" "$OUT/signalp_deeptmhmm_by_transcript.tsv.tmp_tm"

echo "Done!"
echo "  $OUT/signalp_by_gene.collapsed.tsv"
echo "  $OUT/deeptmhmm_by_gene.collapsed.tsv"
echo "  $OUT/signalp_deeptmhmm_by_transcript.tsv"
