#!/usr/bin/env bash
#
# Title:    flux2.sh
# Author:   FNGarvin
# License:  CC BY-NC 4.0
#
#END OF HEADER

#
# NOTE: This script is specifically designed for use with the
# madiator2011/better-comfyui:slim-5090 Docker image.
# It assumes the environment and paths match that image.
#

# --- Configuration ---
# Define base paths to avoid using 'cd'. This makes the script more robust.
readonly COMFYUI_DIR="/workspace/madapps/ComfyUI"

# --- Dependencies ---
echo "INFO: Updating package list and installing aria2..."
apt-get update && apt-get install -y --no-install-recommends aria2

# --- Model Downloads ---
echo "INFO: Downloading Flux2 models..."
# Use the --dir option for aria2c to specify output location directly.

# Text Encoder (FP8)
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o mistral_3_small_flux2_fp8.safetensors "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/text_encoders/mistral_3_small_flux2_fp8.safetensors?download=true"

# Diffusion Model
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o flux2_dev_fp8mixed.safetensors "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/diffusion_models/flux2_dev_fp8mixed.safetensors?download=true"

# VAE
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/vae" -o flux2-vae.safetensors "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors?download=true"

echo "INFO: Model downloads complete. Please click 'Refresh' in the ComfyUI interface."

