#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <SIMG> <TRINOTATE_XLS> <GODIR> <SUMMARYDIR>" >&2
  exit 1
fi

SIMG="$1"
TRI_XLS="$2"
GODIR="$3"
SUMMARYDIR="$4"

mkdir -p "$GODIR" "$SUMMARYDIR"

# Inside-SIF utilities (verified paths in SIF)
EXTRACT="/usr/local/src/Trinotate/util/extract_GO_assignments_from_Trinotate_xls.pl"
GO_SLIM="/usr/local/src/Trinotate/util/gene_ontology/Trinotate_GO_to_SLIM.pl"
REPORT_SUM="/usr/local/src/Trinotate/util/report_summary/trinotate_report_summary.pl"

# Bind roots (as used in prior Trinotate jobs)
BINDS=(-B /cluster/work/users/carlota -B /cluster/projects/nn12014k)

echo "[INFO] Trinotate finalize GO (mandatory all steps)"
echo "[INFO] SIMG=$SIMG"
echo "[INFO] TRI_XLS=$TRI_XLS"
echo "[INFO] GODIR=$GODIR"
echo "[INFO] SUMMARYDIR=$SUMMARYDIR"

# Sanity checks
[[ -s "$SIMG" ]]    || { echo "ERROR: SIF not found: $SIMG" >&2; exit 2; }
[[ -s "$TRI_XLS" ]] || { echo "ERROR: Trinotate report not found: $TRI_XLS" >&2; exit 2; }

# 1) DIRECT GO (for enrichment)
singularity exec "${BINDS[@]}" "$SIMG" bash -lc "
  '$EXTRACT' --Trinotate_xls '$TRI_XLS' --gene > '$GODIR/trinotate_GO_by_gene.tsv'
"
[[ -s "$GODIR/trinotate_GO_by_gene.tsv" ]] || { echo "ERROR: direct GO file is empty." >&2; exit 3; }

# 2) DIRECT + ANCESTRAL GO (for descriptive coverage)
singularity exec "${BINDS[@]}" "$SIMG" bash -lc "
  '$EXTRACT' --Trinotate_xls '$TRI_XLS' --gene --include_ancestral_terms > '$GODIR/trinotate_GO_by_gene_ancestral.tsv'
"
[[ -s "$GODIR/trinotate_GO_by_gene_ancestral.tsv" ]] || { echo "ERROR: ancestral GO file is empty." >&2; exit 4; }

# 3) GO-Slim for DIRECT GO
singularity exec "${BINDS[@]}" "$SIMG" bash -lc "
  '$GO_SLIM' '$GODIR/trinotate_GO_by_gene.tsv' > '$GODIR/trinotate_GO_by_gene.slim.tsv'
"
[[ -s "$GODIR/trinotate_GO_by_gene.slim.tsv" ]] || { echo "ERROR: GO-Slim (direct) is empty." >&2; exit 5; }

# 4) GO-Slim for DIRECT+ANCESTRAL GO
singularity exec "${BINDS[@]}" "$SIMG" bash -lc "
  '$GO_SLIM' '$GODIR/trinotate_GO_by_gene_ancestral.tsv' > '$GODIR/trinotate_GO_by_gene_ancestral.slim.tsv'
"
[[ -s "$GODIR/trinotate_GO_by_gene_ancestral.slim.tsv" ]] || { echo "ERROR: GO-Slim (ancestral) is empty." >&2; exit 6; }

# 5) MANDATORY: Trinotate report summary (positional args)
# Usage per upstream: trinotate_report_summary.pl Trinotate_report.tsv output_prefix
# The .xls is tab-delimited and accepted by the utility.
singularity exec "${BINDS[@]}" "$SIMG" bash -lc "
  '$REPORT_SUM' '$TRI_XLS' '$SUMMARYDIR/trinotate_summary'
"

# Expect at least a main summary output; presence check:
shopt -s nullglob
SUM_FILES=("$SUMMARYDIR"/trinotate_summary*)
if (( ${#SUM_FILES[@]} == 0 )); then
  echo "ERROR: trinotate_report_summary.pl produced no outputs." >&2
  exit 7
fi

echo "[DONE] Outputs:"
ls -lh "$GODIR"/trinotate_GO_by_gene*.tsv "$SUMMARYDIR"/trinotate_summary* 2>/dev/null || true
