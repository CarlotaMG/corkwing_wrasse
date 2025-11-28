#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <base_dir>"
    exit 1
fi

# Define arguments
BASE_DIR="$1"
PKG_DIR="$BASE_DIR/signalp6_fast/signalp-6-package"
ENV_DIR="$BASE_DIR/env"

# Create virtual environment
echo "Creating virtual environment at $ENV_DIR..."
python3 -m venv "$ENV_DIR"

# Activate environment
source "$ENV_DIR/bin/activate"

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Pin NumPy to <2 for compatibility
echo "Pinning NumPy..."
pip install "numpy<2"

# Install SignalP from source
echo "Installing SignalP..."
pip install --force-reinstall "$PKG_DIR"

# Copy model weights into environment
echo "Copying model weights..."
SIGNALP_DIR=$(python3 -c "import signalp, os; print(os.path.dirname(signalp.__file__))")
rsync -av "$PKG_DIR/models/" "$SIGNALP_DIR/model_weights/"

# Deactivate environment
deactivate

echo "SignalP environment setup complete at $ENV_DIR"
