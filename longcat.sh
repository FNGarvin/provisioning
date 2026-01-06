#!/usr/bin/env bash
#
# Title: longcat.sh
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

if [ -d "${MADAPPS_PATH}" ]; then
    COMFYUI_DIR="${MADAPPS_PATH}"
    VENV_NAME=".venv"
    echo "INFO: Detected ComfyUI in Madiator's custom 'madapps' path."
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

# --- 1. Infrastructure & Node Setup ---
echo "INFO: Installing uv and cloning nodes..."
apt-get update && apt-get install -y --no-install-recommends aria2 curl
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="${HOME}/.local/bin:${PATH}"

git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper" || true
git clone https://github.com/kijai/ComfyUI-MelBandRoFormer.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-MelBandRoFormer" || true
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite" || true

# --- 2. Targeted Package Installation ---
echo "INFO: Activating venv and installing node requirements via uv..."
# shellcheck source=/dev/null
source "${VENV_PATH}"

if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt" ]; then
    uv pip install --no-deps -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt"
fi

if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-MelBandRoFormer/requirements.txt" ]; then
    pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-MelBandRoFormer/requirements.txt"
fi

if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" ]; then
    uv pip install --no-deps -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt"
fi

# --- 3. Model Downloads ---
echo "INFO: Downloading LongCat-Avatar models and custom nodes..."

mkdir -p "${COMFYUI_DIR}/models/diffusion_models/LongCat"
mkdir -p "${COMFYUI_DIR}/models/text_encoders"
mkdir -p "${COMFYUI_DIR}/models/vae"
mkdir -p "${COMFYUI_DIR}/models/loras"

aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models/LongCat" -o LongCat-Avatar-single_fp8_e4m3fn_scaled_mixed_KJ.safetensors "https://huggingface.co/Kijai/LongCat-Video_comfy/resolve/main/Avatar/LongCat-Avatar-single_fp8_e4m3fn_scaled_mixed_KJ.safetensors?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/vae" -o wan_2.1_vae.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/loras" -o LongCat-Avatar.safetensors "https://huggingface.co/Kijai/LongCat-Video_comfy/resolve/main/LongCat_distill_lora_alpha64_bf16.safetensors?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o umt5-xxl-enc-bf16.safetensors "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o MelBandRoformer_fp16.safetensors "https://huggingface.co/Kijai/MelBandRoFormer_comfy/resolve/main/MelBandRoformer_fp16.safetensors?download=true"

# --- 4. Restart ---
echo "INFO: Restarting ComfyUI service..."
pkill -f "main.py" || true
nohup python "${COMFYUI_DIR}/main.py" --listen 0.0.0.0 --port 8188 > "${COMFYUI_DIR}/comfyui.log" 2>&1 &

echo "INFO: Provisioning complete. ComfyUI is starting."

#END OF provision.sh