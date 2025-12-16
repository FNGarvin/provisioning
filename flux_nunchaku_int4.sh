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
#   ./flux_nunchaku_int4.sh
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

# --- Apply ComfyUI LORA Loader Patch ---
echo "INFO: Applying patch to ComfyUI LORA loader supported_models_base.py..."
LINE_START=$(grep -n "__getattr__" "${SUPPORTED_MODELS_BASE_PATH}" | cut -d: -f1)

if [ -n "${LINE_START}" ]; then
    LINE_END=$((LINE_START + 2))
    echo "INFO: Commenting out lines ${LINE_START}-${LINE_END} in supported_models_base.py."
    sed -i "${LINE_START},${LINE_END}s/^/#&/" "${SUPPORTED_MODELS_BASE_PATH}"
else
    echo "WARN: Could not find __getattr__ in supported_models_base.py. Patch skipped."
fi

# --- Model Downloads ---
echo "INFO: Downloading FLUX.1 models and custom nodes..."

# Ensure all target model directories exist
mkdir -p "${COMFYUI_DIR}/models/diffusion_models"
mkdir -p "${COMFYUI_DIR}/models/text_encoders"
mkdir -p "${COMFYUI_DIR}/models/vae"
mkdir -p "${COMFYUI_DIR}/models/loras"

# Models (FLUX.1 Nunchaku INT4)
# Diffuser/UNet Models -> models/diffusion_models/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o svdq-int4_r32-flux.1-dev.safetensors "https://huggingface.co/nunchaku-tech/nunchaku-flux.1-dev/resolve/main/svdq-int4_r32-flux.1-dev.safetensors?download=true" || exit 1

# Text Encoder Models -> models/text_encoders/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o clip_l.safetensors "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true" || exit 1
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/text_encoders" -o t5xxl_fp8_e4m3fn_scaled.safetensors "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn_scaled.safetensors?download=true" || exit 1

# VAE Model -> models/vae/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/vae" -o ae.safetensors "https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged/resolve/main/split_files/vae/ae.safetensors?download=true" || exit 1

# Lora Models -> models/loras/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/loras" -o ghibli_style.flux.safetensors "https://huggingface.co/InstantX/FLUX.1-dev-LoRA-Ghibli/resolve/main/ghibli_style.safetensors?download=true" || exit 1
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/loras" -o flux-ghibsky-illustration.safetensors "https://huggingface.co/aleksa-codes/flux-ghibsky-illustration/resolve/main/lora.safetensors?download=true" || exit 1
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/loras" -o flux-ghibsky-illustration.v2.safetensors "https://huggingface.co/aleksa-codes/flux-ghibsky-illustration/resolve/main/lora_v2.safetensors?download=true" || exit 1
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/loras" -o flux1-turbo.safetensors "https://huggingface.co/camenduru/FLUX.1-dev/resolve/fc63f3204a12362f98c04bc4c981a06eb9123eee/FLUX.1-Turbo-Alpha.safetensors?download=true" || exit 1

# --- Restart ComfyUI Service ---
echo "INFO: Restarting ComfyUI service..."
pkill -f "main.py" || true
nohup python "${COMFYUI_DIR}/main.py" --listen 0.0.0.0 --port 8188 > "${COMFYUI_DIR}/comfyui.log" 2>&1 &

echo "INFO: Provisioning complete. ComfyUI is starting."

#END OF flux_nunchaku_int4.sh
