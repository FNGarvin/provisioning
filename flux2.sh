#!/bin/bash
#
# script: flux2.sh
# author: FNGarvin
# license: MIT
# description: Downloads Flux 2 dev assets using aria2c with header spoofing
#              to bypass Hugging Face throttling and naming issues.
#

# Script name for usage output
SCRIPT_NAME=$(basename "$0")

# Check for aria2c
if ! command -v aria2c &> /dev/null; then
    echo "Error: aria2c is not installed or not in PATH."
    exit 1
fi

# Target Directory
OUTPUT_DIR="models/vae"
mkdir -p "$OUTPUT_DIR"

# List of URLs to download
# Added the VAE link provided. Add other model parts here if needed.
declare -a URLS=(
    "[https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors?download=true](https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors?download=true)"
)

echo "Starting download sequence..."

for url in "${URLS[@]}"; do
    echo "Processing: $url"
    
    # -x 16 -s 16: Max connection splitting
    # --content-disposition: Fixes the '?download=true' filename issue
    # --user-agent: Spoofs wget to bypass potential aria2 blocking/throttling
    # --check-certificate=false: Optional, helps if local SSL certs are outdated
    
    aria2c --dir="$OUTPUT_DIR" \
           --content-disposition \
           --user-agent="Wget/1.21.3" \
           -x 16 -s 16 -j 16 \
           --file-allocation=none \
           --summary-interval=0 \
           "$url"
           
    if [ $? -ne 0 ]; then
        echo "Error downloading: $url"
    fi
done

echo "Batch complete."

# EOF

