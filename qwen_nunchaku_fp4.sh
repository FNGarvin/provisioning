#!/usr/bin/env bash
#
# Author: FNGarvin
#
# NOTE: This script is specifically designed for use with the
# madiator2011/better-comfyui:slim-5090 Docker image.
# It assumes the environment and paths match that image, including the presence
# of the ComfyUI Manager, Python venv, and necessary build tools.
#
# USAGE:
#   ./qwen_nunchaku_fp4.sh
#

# --- Configuration ---
readonly COMFYUI_DIR="/workspace/madapps/ComfyUI"
readonly VENV_PATH="${COMFYUI_DIR}/.venv/bin/activate"
readonly SUPPORTED_MODELS_BASE_PATH="${COMFYUI_DIR}/comfy/supported_models_base.py"
readonly NUNCHAKU_WHEEL_URL="https://github.com/nunchaku-tech/nunchaku/releases/download/v1.0.2/nunchaku-1.0.2+torch2.9-cp312-cp312-linux_x86_64.whl"

# --- Core Dependencies ---
apt-get update || exit 1
apt-get install -y aria2 || exit 1

# --- Nunchaku Installation ---

# 1. Install the Nunchaku Custom Node
echo "INFO: Installing ComfyUI-nunchaku custom node..."
git clone https://github.com/mit-han-lab/ComfyUI-nunchaku.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-nunchaku" || exit 1

# 2. Activate the virtual environment
echo "INFO: Activating Python virtual environment..."
# shellcheck source=/dev/null
source "${VENV_PATH}" || exit 1

# 3. Install Nunchaku Python package from official v1.0.2 wheel
echo "INFO: Installing Nunchaku from official wheel: ${NUNCHAKU_WHEEL_URL}"
pip install "${NUNCHAKU_WHEEL_URL}" || exit 1

# Install the GGUF Python dependency for the GGUF Text Encoder model
pip3 install --upgrade gguf || exit 1

# --- Apply ComfyUI LORA Loader Patch ---
# The target is to comment out the last 3 lines (122, 123, 124) of supported_models_base.py
# that cause a LORA loader crash due to an unexpected getattr call.
echo "INFO: Applying patch to ComfyUI LORA loader supported_models_base.py..."
# Find the line number of the first line to be commented out (should be the start of __getattr__)
LINE_START=$(grep -n "__getattr__" "${SUPPORTED_MODELS_BASE_PATH}" | cut -d: -f1)

if [ -n "${LINE_START}" ]; then
    # Calculate the end line by adding 2 (for 3 lines total)
    LINE_END=$((LINE_START + 2))
    echo "INFO: Commenting out lines ${LINE_START}-${LINE_END} in supported_models_base.py."
    # Use sed to comment out the three lines
    sed -i "${LINE_START},${LINE_END}s/^/#&/" "${SUPPORTED_MODELS_BASE_PATH}"
else
    echo "WARN: Could not find __getattr__ in supported_models_base.py. Patch skipped."
fi

# --- Model Downloads ---
echo "INFO: Downloading Qwen-Image models..."

# Ensure all target model directories exist
mkdir -p "${COMFYUI_DIR}/models/diffusion_models" "${COMFYUI_DIR}/models/text_encoders" "${COMFYUI_DIR}/models/vae" "${COMFYUI_DIR}/models/loras"

# Models (Updated for Nunchaku - Lora is now merged)
# Diffuser/UNet Models -> models/diffusion_models/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o svdq-fp4_r128-qwen-image-lightningv1.1-8steps.safetensors "https://huggingface.co/nunchaku-tech/nunchaku-qwen-image/resolve/main/svdq-fp4_r128-qwen-image-lightningv1.1-8steps.safetensors?download=true" || exit 1

# Text Encoder Models -> models/text_encoders/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o qwen_2.5_vl_7b_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors?download=true" || exit 1

# VAE Model -> models/vae/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/vae" -o qwen_image_vae.safetensors "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors?download=true" || exit 1

# --- Restart ComfyUI Service ---
echo "INFO: Restarting ComfyUI service..."
pkill -f "main.py" || true
nohup python "${COMFYUI_DIR}/main.py" --listen 0.0.0.0 --port 8188 > "${COMFYUI_DIR}/comfyui.log" 2>&1 &

echo "INFO: Provisioning complete. ComfyUI is starting."

#END OF qwen_nunchaku_fp4.sh
