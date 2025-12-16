#!/usr/bin/env bash
#
# Title: qwen_provision.sh
# Author: FNGarvin
#
#END OF HEADER

#
# NOTE: This script is specifically designed for use with the
# madiator2011/better-comfyui:slim-5090 Docker image.
# It assumes the environment and paths match that image.
#

# --- Configuration ---
# Define base paths to avoid using 'cd'. This makes the script more robust.
# --- Path Detection and Standardization ---
COMFYUI_DIR=""
MADAPPS_PATH="/workspace/madapps/ComfyUI"
RUNPOD_SLIM_PATH="/workspace/runpod-slim/ComfyUI"

# Check Madiator's 'madapps' path first
if [ -d "${MADAPPS_PATH}" ]; then
    COMFYUI_DIR="${MADAPPS_PATH}"
    echo "INFO: Detected ComfyUI in Madiator's custom 'madapps' path."
# Check the standard 'runpod-slim' path
elif [ -d "${RUNPOD_SLIM_PATH}" ]; then
    COMFYUI_DIR="${RUNPOD_SLIM_PATH}"
    echo "INFO: Detected ComfyUI in standard 'runpod-slim' path."
else
    echo "ERROR: ComfyUI directory not found in either expected location."
    echo "Expected locations: ${MADAPPS_PATH} or ${RUNPOD_SLIM_PATH}"
    exit 1
fi
# --- End Path Detection ---
readonly VENV_PATH="${COMFYUI_DIR}/.venv/bin/activate"

# --- Dependencies ---
echo "INFO: Updating package list and installing aria2..."
apt-get update && apt-get install -y --no-install-recommends aria2

# --- Model & Node Downloads ---
echo "INFO: Downloading Qwen-Image models and custom nodes..."
# Use the --dir option for aria2c to specify output location directly.

# Ensure all target model directories exist
mkdir -p "${COMFYUI_DIR}/models/diffusion_models"
mkdir -p "${COMFYUI_DIR}/models/text_encoders"
mkdir -p "${COMFYUI_DIR}/models/vae"
mkdir -p "${COMFYUI_DIR}/models/loras"

# Models
# Text Encoder (replaces text encoder) -> models/text_encoders/
#aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o Qwen2.5-VL-7B-Instruct-UD-Q4_K_XL.gguf "https://huggingface.co/unsloth/Qwen2.5-VL-7B-Instruct-GGUF/resolve/main/Qwen2.5-VL-7B-Instruct-UD-Q4_K_XL.gguf?download=true"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o qwen_2.5_vl_7b_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors?download=true" || exit 1

# Lora/Lightning (replaces lora) -> models/loras/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/loras" -o Qwen-Image-Lightning-8steps-V1.0.safetensors "https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Lightning-8steps-V1.0.safetensors?download=true"

# VAE (replaces vae) -> models/vae/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/vae" -o qwen_image_vae.safetensors "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors?download=true"

# Diffuser/UNet (replaces diffuser) -> models/diffusion_models/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o qwen-image-Q4_K_M.gguf "https://huggingface.co/city96/Qwen-Image-gguf/resolve/main/qwen-image-Q4_K_M.gguf?download=true"

# Custom Nodes
# Install the GGUF node for loading the Qwen-Image GGUF parts
git clone https://github.com/city96/ComfyUI-GGUF.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-GGUF"

# --- Python Environment & Custom GGUF Package Installation ---
echo "INFO: Activating Python venv and installing required packages..."
# Activate the virtual environment
# shellcheck source=/dev/null
source "${VENV_PATH}"

# Install the GGUF Python dependency for the custom node
pip3 install --upgrade gguf

# Dynamically detect the CUDA version PyTorch was built against.
# It gets the version (e.g., "12.1"), removes the dot ("121"), and creates the wheel name ("cu121").
#readonly CUDA_VERSION_STR=$(python3 -c 'import torch; print(torch.version.cuda)')
#readonly CU_WHL_VERSION="cu$(echo "${CUDA_VERSION_STR}" | tr -d '.')"
#echo "INFO: Detected PyTorch CUDA version ${CUDA_VERSION_STR}."
#echo "INFO: Attempting to install xformers for ${CU_WHL_VERSION}..."
#pip3 install -U xformers --index-url "https://download.pytorch.org/whl/${CU_WHL_VERSION}"

# --- Restart ComfyUI Service ---
echo "INFO: Restarting ComfyUI service..."
# Kill any running main.py process.
pkill -f "main.py" || true

# Start the server using its full path and redirect output to a log file.
nohup python "${COMFYUI_DIR}/main.py" --listen 0.0.0.0 --port 8188 > "${COMFYUI_DIR}/comfyui.log" 2>&1 &

echo "INFO: Provisioning complete. ComfyUI is starting."

#END OF qwen_provision.sh
