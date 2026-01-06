#!/usr/bin/env bash
#
# Title: longcat_provision.sh
# Author: Gemini
#
#END OF HEADER

# --- Configuration ---
COMFYUI_DIR=""
MADAPPS_PATH="/workspace/madapps/ComfyUI"
RUNPOD_SLIM_PATH="/workspace/runpod-slim/ComfyUI"

if [ -d "${MADAPPS_PATH}" ]; then
    COMFYUI_DIR="${MADAPPS_PATH}"
    VENV_NAME=".venv"
elif [ -d "${RUNPOD_SLIM_PATH}" ]; then
    COMFYUI_DIR="${RUNPOD_SLIM_PATH}"
    VENV_NAME=".venv-cu128"
else
    echo "ERROR: ComfyUI directory not found."
    exit 1
fi
readonly VENV_PATH="${COMFYUI_DIR}/${VENV_NAME}/bin/activate"

# --- Dependencies ---
echo "INFO: Installing aria2 and standalone uv..."
apt-get update && apt-get install -y --no-install-recommends aria2 curl
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="${HOME}/.local/bin:${PATH}"

# --- Model Downloads ---
echo "INFO: Downloading models..."
mkdir -p "${COMFYUI_DIR}/models/diffusion_models/LongCat"
mkdir -p "${COMFYUI_DIR}/models/text_encoders"
mkdir -p "${COMFYUI_DIR}/models/vae"
mkdir -p "${COMFYUI_DIR}/models/loras"

# Downloads based on your specific commands
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models/LongCat" -o LongCat-Avatar-single_fp8_e4m3fn_scaled_mixed_KJ.safetensors "https://huggingface.co/Kijai/LongCat-Video_comfy/resolve/main/Avatar/LongCat-Avatar-single_fp8_e4m3fn_scaled_mixed_KJ.safetensors?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/vae" -o wan_2.1_vae.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/loras" -o LongCat-Avatar.safetensors "https://huggingface.co/Kijai/LongCat-Video_comfy/resolve/main/LongCat_distill_lora_alpha64_bf16.safetensors?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o umt5-xxl-enc-bf16.safetensors "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o MelBandRoformer_fp16.safetensors "https://huggingface.co/Kijai/MelBandRoFormer_comfy/resolve/main/MelBandRoformer_fp16.safetensors?download=true"

# --- Custom Nodes ---
echo "INFO: Cloning WanVideoWrapper and VideoHelperSuite..."
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper" || true
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite" || true

# --- Targeted Package Installation ---
echo "INFO: Installing node requirements via uv..."
# shellcheck source=/dev/null
source "${VENV_PATH}"

# Target only the nodes required for this specific workflow
if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt" ]; then
    uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt"
fi

if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" ]; then
    uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt"
fi

# --- Restart ComfyUI Service ---
echo "INFO: Restarting ComfyUI..."
pkill -f "main.py" || true
nohup python "${COMFYUI_DIR}/main.py" --listen 0.0.0.0 --port 8188 > "${COMFYUI_DIR}/comfyui.log" 2>&1 &

echo "INFO: Provisioning complete. ComfyUI is starting."
