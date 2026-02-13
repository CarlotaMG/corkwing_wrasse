#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <SIF_PATH> <DB_DIR>" >&2
  exit 1
fi

SIF="$(realpath "$1")"
DB_DIR="$(realpath -m "$2")"

# Container tag
TAG_URI="docker://quay.io/biocontainers/eggnog-mapper:2.1.13--pyhdfd78af_2"

# Confirmed working v5.0.2 mirror
BASE_URL="http://eggnog5.embl.de/download/emapperdb-5.0.2"

mkdir -p "$(dirname "$SIF")"
mkdir -p "$DB_DIR"

# Pull SIF if not present
if [[ -f "$SIF" ]]; then
  echo "[OK] Found SIF: $SIF"
else
  echo "[INFO] Pulling eggnog-mapper container..."
  apptainer pull "$SIF" "$TAG_URI"
  echo "[OK] SIF ready."
fi

# Download all five DB files
cd "$DB_DIR"

echo "[INFO] Downloading eggNOG v5.0.2 files..."
wget -c "$BASE_URL/eggnog.db.gz"
wget -c "$BASE_URL/eggnog.taxa.tar.gz"
wget -c "$BASE_URL/eggnog_proteins.dmnd.gz"
wget -c "$BASE_URL/mmseqs.tar.gz"
wget -c "$BASE_URL/pfam.tar.gz"

echo "[INFO] Unpacking..."

# Unpack core search/annotation databases
[[ -f eggnog.db ]] || gunzip -c eggnog.db.gz > eggnog.db
[[ -f eggnog_proteins.dmnd ]] || gunzip -c eggnog_proteins.dmnd.gz > eggnog_proteins.dmnd
[[ -f eggnog.taxa.db ]] || tar -xzf eggnog.taxa.tar.gz

# Unpack search/realignment databases so all modes are ready
tar -xzf mmseqs.tar.gz || true
tar -xzf pfam.tar.gz || true

echo "[OK] eggNOG v5.0.2 database prepared in: $DB_DIR"
echo "[INFO] Contents should include:"
echo "  - eggnog.db"
echo "  - eggnog.taxa.db"
echo "  - eggnog_proteins.dmnd"
echo "  - mmseqs/  (for -m mmseqs)"
echo "  - pfam/    (for PFAM realignment)"
