#!/usr/bin/env bash
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
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o Qwen_Image_Edit-Q4_K_M.gguf "https://huggingface.co/QuantStack/Qwen-Image-Edit-GGUF/resolve/main/Qwen_Image_Edit-Q4_K_M.gguf?download=true"
