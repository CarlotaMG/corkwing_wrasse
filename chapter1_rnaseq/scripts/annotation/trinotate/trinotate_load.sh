#!/usr/bin/env bash
set -euo pipefail

# Args from SLURM wrapper (keep order)
SIMG="$1"
GENE_TRANS_MAP="$2"
TRANSCRIPTS="$3"
PEP="$4"
BLASTP_OUT="$5"
BLASTX_OUT="$6"
PFAM_OUT="$7"
SIGNALP_OUT="$8"
TMHMM_GFF="$9"
OUT_DIR="${10}"
DATA_DIR="${11}"

# Ensure OUT_DIR exists
mkdir -p "$OUT_DIR"

# Trinotate binary inside the container
TRINOTATE="/usr/local/src/Trinotate/Trinotate"

# Binds for Singularity
BINDS=(-B /cluster/work/users/carlota -B /cluster/projects/nn12014k)

exec_in_sing() {
  singularity exec "${BINDS[@]}" "$SIMG" bash -lc "$*"
}

DB="$OUT_DIR/Trinotate.sqlite"

echo "[$(date)] OUT_DIR=$OUT_DIR"
echo "[$(date)] DATA_DIR=$DATA_DIR"
echo "[$(date)] Starting Trinotate load + report"

########################
# Init via SeqLoader   #
########################
# (This populates Transcript + ORF, fixing the empty-report issue.)
echo "[$(date)] Initializing DB via TrinotateSeqLoader..."
exec_in_sing "
  set -euo pipefail
  cd '$OUT_DIR'
  perl /usr/local/src/Trinotate/util/trinotateSeqLoader/TrinotateSeqLoader.pl \
      --sqlite '$DB' \
      --gene_trans_map '$GENE_TRANS_MAP' \
      --transcript_fasta '$TRANSCRIPTS' \
      --transdecoder_pep '$PEP' \
      --bulk_load

  echo '--- Counts after init ---'
  echo -n 'Transcript  '; sqlite3 '$DB' 'SELECT COUNT(*) FROM Transcript;'
  echo -n 'ORF         '; sqlite3 '$DB' 'SELECT COUNT(*) FROM ORF;'
"

########################
# Loaders
########################
echo "[$(date)] Loading BLASTP/BLASTX/PFAM/SignalP/DeepTMHMM..."
exec_in_sing "cd '$OUT_DIR' && '$TRINOTATE' --db '$DB' --LOAD_swissprot_blastp '$BLASTP_OUT'"
exec_in_sing "cd '$OUT_DIR' && '$TRINOTATE' --db '$DB' --LOAD_swissprot_blastx '$BLASTX_OUT'"
exec_in_sing "cd '$OUT_DIR' && '$TRINOTATE' --db '$DB' --LOAD_pfam              '$PFAM_OUT'"
exec_in_sing "cd '$OUT_DIR' && '$TRINOTATE' --db '$DB' --LOAD_signalp           '$SIGNALP_OUT'"
exec_in_sing "cd '$OUT_DIR' && '$TRINOTATE' --db '$DB' --LOAD_deeptmhmm         '$TMHMM_GFF'"

########################
# Final report (robust)
########################
echo "[$(date)] Generating final Trinotate report..."

# Detect supported flags (inside container)
SUPPORTED=$(singularity exec "${BINDS[@]}" "$SIMG" bash -lc "'$TRINOTATE' --help" 2>/dev/null || true)
REPORT_FLAGS=()
if grep -qi -- "--incl_trans" <<<"$SUPPORTED"; then REPORT_FLAGS+=(--incl_trans); fi
if grep -qi -- "--incl_pep"   <<<"$SUPPORTED"; then REPORT_FLAGS+=(--incl_pep);   fi
if grep -qi -- "--pfam_cutoff"<<<"$SUPPORTED"; then REPORT_FLAGS+=(--pfam_cutoff DNC); fi

if ((${#REPORT_FLAGS[@]})); then
  echo "[$(date)] Using report flags: ${REPORT_FLAGS[*]}"
else
  echo "[$(date)] Using report flags: (none)"
fi

# Run report INSIDE the container and redirect INSIDE too
exec_in_sing "
  set -euo pipefail
  cd '$OUT_DIR'
  $TRINOTATE --db \"$DB\" --report ${REPORT_FLAGS[*]:-} > trinotate_annotation_report.xls
"

# Validate size; retry with minimal flags if too small (<10 KB)
size=$(stat -c%s "$OUT_DIR/trinotate_annotation_report.xls" 2>/dev/null || echo 0)
if (( size < 10240 )); then
  echo "[$(date)] Report looks too small ($size bytes); retrying with minimal flags..." >&2
  exec_in_sing "
    set -euo pipefail
    cd '$OUT_DIR'
    $TRINOTATE --db \"$DB\" --report > trinotate_annotation_report.xls
  " 2> "$OUT_DIR/trinotate_report.stderr"
fi

# Final size check
size=$(stat -c%s "$OUT_DIR/trinotate_annotation_report.xls" 2>/dev/null || echo 0)
if (( size < 10240 )); then
  echo "[$(date)] ERROR: Report file still too small or empty ($size bytes). See: $OUT_DIR/trinotate_report.stderr" >&2
  exit 1
fi

echo "[$(date)] Report ready: $OUT_DIR/trinotate_annotation_report.xls"
echo "[$(date)] Done."
