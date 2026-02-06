#!/usr/bin/env bash

set -euo pipefail

PEP_FILE="${1:?FASTA (.pep) file required}"
OUT_DIR="${2:?Output directory required}"
SIF="${3:?Singularity image required}"
PURGE_EMBEDDINGS="${4:-1}"  # 1 = purge (default), 0 = keep embeddings on shared

# Optional: force-remove shared tmp even if populated (use with PURGE_EMBEDDINGS=0)
REMOVE_TMP_ON_SUCCESS="${REMOVE_TMP_ON_SUCCESS:-0}"

CHUNK_NAME="$(basename "${PEP_FILE}" .pep)"
OUT_RES="${OUT_DIR}/deeptmhmm_out/biolib_results"

[[ -s "${PEP_FILE}" ]] || { echo "[ERROR] FASTA missing: ${PEP_FILE}" >&2; exit 2; }

# Prepare result directory only (no shared tmp unless explicitly keeping embeddings)
mkdir -p "${OUT_RES}"
find "${OUT_RES}" -type f -size 0 -delete || true

# Choose node-local scratch for heavy intermediates
# Prefer Saga's $LOCALSCRATCH (requires --gres=localscratch:<size>), otherwise fallback to /tmp
LOCAL_BASE="${LOCALSCRATCH:-/tmp}"
if [[ ! -d "${LOCAL_BASE}" || ! -w "${LOCAL_BASE}" ]]; then
  echo "[WARN] Node-local scratch not writable; falling back to /tmp"
  LOCAL_BASE="/tmp"
fi
LOCAL_JOB_TMP="${LOCAL_BASE}/deeptmhmm_${SLURM_JOB_ID:-$$}_${SLURM_ARRAY_TASK_ID:-0}"
LOCAL_EMB="${LOCAL_JOB_TMP}/embeddings"
mkdir -p "${LOCAL_EMB}"

if [[ -n "${LOCALSCRATCH:-}" ]]; then
  echo "[INFO] Using LOCALSCRATCH: ${LOCAL_JOB_TMP}"
else
  echo "[INFO] Using node-local /tmp: ${LOCAL_JOB_TMP}"
fi

CPUS="${SLURM_CPUS_PER_TASK:-3}"
TIME_BIN="$(command -v /usr/bin/time || true)"
TIME_ARGS="-v"

# -------------------- RUN BLOCK (robust to non-zero RC) -----------------------
# We capture the container’s return code but treat the run as success
# if the two required outputs exist and are non-empty.
set +e

${TIME_BIN:-/bin/true} ${TIME_ARGS} \
apptainer exec \
  --bind "${PEP_FILE}:/work/${CHUNK_NAME}.pep" \
  --bind "${OUT_DIR}:/work" \
  --bind "${LOCAL_EMB}:/openprotein/embeddings" \
  --bind "${LOCAL_JOB_TMP}:/openprotein/tmp" \
  --pwd /openprotein \
  --writable-tmpfs \
  "${SIF}" \
  bash -lc "
    set -euo pipefail
    export CUDA_VISIBLE_DEVICES=''  # force CPU
    export OMP_NUM_THREADS='${CPUS}'
    export MKL_NUM_THREADS='${CPUS}'
    export OPENBLAS_NUM_THREADS='${CPUS}'
    echo '[INFO] Running DeepTMHMM...'
    python3 -u predict.py --fasta '/work/${CHUNK_NAME}.pep'
    mkdir -p /work/deeptmhmm_out/biolib_results
    for f in predicted_topologies.3line TMRs.gff3 deeptmhmm_results.md plot.png; do
      [ -f \"/openprotein/\$f\" ] && cp \"/openprotein/\$f\" \"/work/deeptmhmm_out/biolib_results/\$f\"
    done
  " 2>&1

RC=$?
set -e
# ------------------------------------------------------------------------------

# Validate required outputs & decide success
REQ1="${OUT_RES}/predicted_topologies.3line"
REQ2="${OUT_RES}/TMRs.gff3"

if [[ ! -s "${REQ1}" || ! -s "${REQ2}" ]]; then
  echo "[ERROR] Missing required outputs: ${REQ1} or ${REQ2}. apptainer RC=${RC}" >&2
  # Clean node-local tmp before failing
  rm -rf "${LOCAL_JOB_TMP}" || true
  exit 1
fi

echo "[INFO] DeepTMHMM completed. apptainer RC=${RC}"
echo "[INFO] Outputs:"
ls -lh "${OUT_RES}" || true

# Only copy embeddings back if explicitly asked to keep them
if [[ "${PURGE_EMBEDDINGS}" != "1" ]]; then
  echo "[INFO] Keeping embeddings -> copying from node-local to shared..."
  SHARED_EMB="${OUT_DIR}/deeptmhmm_tmp/embeddings"
  mkdir -p "${SHARED_EMB}"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "${LOCAL_EMB}/" "${SHARED_EMB}/" || true
  else
    cp -a "${LOCAL_EMB}/." "${SHARED_EMB}/" || true
  fi
  if [[ "${REMOVE_TMP_ON_SUCCESS}" == "1" ]]; then
    echo "[INFO] REMOVE_TMP_ON_SUCCESS=1: deleting shared deeptmhmm_tmp after copy"
    rm -rf "${OUT_DIR}/deeptmhmm_tmp" || true
  fi
else
  echo "[INFO] PURGE_EMBEDDINGS=1 (default): embeddings remain on node and will be discarded."
fi

# Clean node-local scratch
rm -rf "${LOCAL_JOB_TMP}" || true

# Ensure final structure is as requested:
# - Only 'deeptmhmm_out/biolib_results/*' on shared by default
# - Remove any empty 'deeptmhmm_tmp' if it exists and is empty
if [[ -d "${OUT_DIR}/deeptmhmm_tmp" ]]; then
  find "${OUT_DIR}/deeptmhmm_tmp" -type d -empty -delete || true
  rmdir "${OUT_DIR}/deeptmhmm_tmp" 2>/dev/null || true
fi
