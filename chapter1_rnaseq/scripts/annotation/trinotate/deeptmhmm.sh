#!/usr/bin/env bash
# Check args
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_fasta> <output_dir>"
    exit 1
fi

# Define args
IN="$1"
OUT="$2"

# Ensure input exists
if [ ! -f "$IN" ]; then
    echo "ERROR: Input FASTA not found: $IN"
    exit 1
fi

# Install pybiolib if missing
python3 -c "import biolib" 2>/dev/null || pip3 install --user pybiolib

# Ensure ~/.local/bin is in PATH
export PATH=$HOME/.local/bin:$PATH

# Create output dir and go there
mkdir -p "$OUT"
cd "$OUT"

# Run DeepTMHMM directly here
biolib run DTU/DeepTMHMM --fasta "$(readlink -f "$IN")"

echo "Done. Results are in $OUT/biolib_results"
