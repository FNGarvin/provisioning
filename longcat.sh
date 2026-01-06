#!/usr/bin/env bash
#
# Title: longcat_provision.sh
# Author: FNGarvin
#
#END OF HEADER

#
# NOTE: This script is specifically designed for use with the
# madiator2011/better-comfyui:slim-5090 Docker image OR the runpod/comfyui:latest-5090 one.
# It assumes the environment and paths match that image.
#

# --- Configuration ---
# --- Path Detection and Standardization ---
COMFYUI_DIR=""
MADAPPS_PATH="/workspace/madapps/ComfyUI"
RUNPOD_SLIM_PATH="/workspace/runpod-slim/ComfyUI"

# Check Madiator's 'madapps' path first
if [ -d "${MADAPPS_PATH}" ]; then
    COMFYUI_DIR="${MADAPPS_PATH}"
    VENV_NAME=".venv"
    echo "INFO: Detected ComfyUI in Madiator's custom 'madapps' path."
# Check the standard 'runpod-slim' path
elif [ -d "${RUNPOD_SLIM_PATH}" ]; then
    COMFYUI_DIR="${RUNPOD_SLIM_PATH}"
    VENV_NAME=".venv-cu128"
    echo "INFO: Detected ComfyUI in standard 'runpod-slim' path."
else
    echo "ERROR: ComfyUI directory not found in either expected location."
    echo "Expected locations: ${MADAPPS_PATH} or ${RUNPOD_SLIM_PATH}"
    exit 1
fi
readonly VENV_PATH="${COMFYUI_DIR}/${VENV_NAME}/bin/activate"
# --- End Path Detection ---

# --- Dependencies ---
echo "INFO: Updating package list and installing aria2 + uv..."
apt-get update && apt-get install -y --no-install-recommends aria2 curl
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="${HOME}/.local/bin:${PATH}"

# --- Model & Node Downloads ---
echo "INFO: Downloading LongCat-Avatar models and custom nodes..."

# Ensure target directories exist
mkdir -p "${COMFYUI_DIR}/models/diffusion_models/LongCat"
mkdir -p "${COMFYUI_DIR}/models/text_encoders"
mkdir -p "${COMFYUI_DIR}/models/vae"
mkdir -p "${COMFYUI_DIR}/models/loras"

# 1. Main Video Model (LongCat Avatar)
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models/LongCat" -o LongCat-Avatar-single_fp8_e4m3fn_scaled_mixed_KJ.safetensors "https://huggingface.co/Kijai/LongCat-Video_comfy/resolve/main/Avatar/LongCat-Avatar-single_fp8_e4m3fn_scaled_mixed_KJ.safetensors?download=true"

# 2. VAE (Wan 2.1)
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/vae" -o wan_2.1_vae.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true"

# 3. LoRA (LongCat Distill)
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/loras" -o LongCat-Avatar.safetensors "https://huggingface.co/Kijai/LongCat-Video_comfy/resolve/main/LongCat_distill_lora_alpha64_bf16.safetensors?download=true"

# 4. Text Encoder (umt5-xxl)
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o umt5-xxl-enc-bf16.safetensors "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors?download=true"

# 5. Audio Separator (Mel-Band RoFormer)
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o MelBandRoformer_fp16.safetensors "https://huggingface.co/Kijai/MelBandRoFormer_comfy/resolve/main/MelBandRoformer_fp16.safetensors?download=true"

# --- Custom Nodes ---
echo "INFO: Cloning WanVideoWrapper and VideoHelperSuite..."
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper" || true
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite" || true

# --- Targeted Package Installation ---
echo "INFO: Activating Python venv and installing node requirements via uv..."
# shellcheck source=/dev/null
source "${VENV_PATH}"

# Generate environment constraints to lock existing package versions
echo "INFO: Creating environment constraints to prevent package sidegrades..."
uv pip freeze > /tmp/constraints.txt

# Install requirements for new nodes while respecting constraints
if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt" ]; then
    echo "INFO: Installing dependencies for WanVideoWrapper using uv..."
    uv pip install -c /tmp/constraints.txt -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt"
fi

if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" ]; then
    echo "INFO: Installing dependencies for VideoHelperSuite using uv..."
    uv pip install -c /tmp/constraints.txt -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt"
fi

# --- Restart ComfyUI Service ---
echo "INFO: Restarting ComfyUI service..."
# Kill any running main.py process
pkill -f "main.py" || true

# Start the server using its full path and redirect output to a log file
nohup python "${COMFYUI_DIR}/main.py" --listen 0.0.0.0 --port 8188 > "${COMFYUI_DIR}/comfyui.log" 2>&1 &

echo "INFO: Provisioning complete. ComfyUI is starting."
