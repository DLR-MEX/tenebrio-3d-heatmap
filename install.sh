#!/usr/bin/env bash
# Install all required Python dependencies for the heatmap project.

set -e

echo "Installing dependencies..."
pip install -r requirements.txt
echo "Done. All dependencies installed successfully."
