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
#   ./flux_nunchaku_fp4.sh          # Default: Installs Nunchaku from pre-built wheel.
#   ./flux_nunchaku_fp4.sh build    # Builds Nunchaku from source.
#

# --- Configuration ---
# Define base paths to avoid using 'cd'. This makes the script more robust.
readonly COMFYUI_DIR="/workspace/madapps/ComfyUI"
readonly VENV_PATH="${COMFYUI_DIR}/.venv/bin/activate"
readonly NUNCHAKU_TEMP_DIR="/tmp/nunchaku_build"

# --- Core Dependencies ---
apt-get update || exit 1
apt-get install -y aria2 || exit 1

# --- Nunchaku Installation ---
# This section installs the custom node and the required Python package.
# It uses a pre-built wheel by default for speed, but will compile from
# source if the 'build' parameter is provided.

# Install the Nunchaku Custom Node (required for both methods)
echo "INFO: Installing ComfyUI-nunchaku custom node..."
git clone https://github.com/mit-han-lab/ComfyUI-nunchaku.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-nunchaku" || exit 1

# Activate the virtual environment (required for both methods)
echo "INFO: Activating Python virtual environment..."
# shellcheck source=/dev/null
source "${VENV_PATH}" || exit 1

# Check for the 'build' parameter to decide installation method
if [[ "$1" == "build" ]]; then
    # --- BUILD FROM SOURCE ---
    echo "INFO: 'build' parameter detected. Compiling Nunchaku from source."

    # Install build-time system dependencies
    echo "INFO: Adding NVIDIA CUDA repository for development libraries..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb || exit 1
    dpkg -i cuda-keyring_1.1-1_all.deb || exit 1
    rm cuda-keyring_1.1-1_all.deb || exit 1
    apt-get update || exit 1

    echo "INFO: Installing CUDA development libraries..."
    apt-get install -y build-essential libcublas-dev-12-8 cuda-nvtx-12-8 libcusparse-dev-12-8 libcusolver-dev-12-8 || exit 1

    # Clone and build the Nunchaku Python package
    echo "INFO: Cloning Nunchaku source repository..."
    git clone --recurse-submodules https://github.com/nunchaku-tech/nunchaku.git "${NUNCHAKU_TEMP_DIR}" || exit 1

    echo "INFO: Building and installing Nunchaku Python package..."
    ( cd "${NUNCHAKU_TEMP_DIR}" && MAX_JOBS=$(nproc) pip3 install -e . ) || exit 1

else
    # --- INSTALL FROM PRE-BUILT WHEEL (DEFAULT) ---
    echo "INFO: No 'build' parameter. Installing Nunchaku from pre-built wheel."
    pip install https://github.com/FNGarvin/provisioning/releases/download/nunchaku_wheel/nunchaku-1.0.1+torch2.9-cp312-cp312-linux_x86_64.whl || exit 1
fi

# Placeholder for Xformers
# Dynamically detect the CUDA version PyTorch was built against.
# It gets the version (e.g., "12.1"), removes the dot ("121"), and creates the wheel name ("cu121").
#readonly CUDA_VERSION_STR=$(python3 -c 'import torch; print(torch.version.cuda)')
#readonly CU_WHL_VERSION="cu$(echo "${CUDA_VERSION_STR}" | tr -d '.')"
#echo "INFO: Detected PyTorch CUDA version ${CUDA_VERSION_STR}."
#echo "INFO: Attempting to install xformers for ${CU_WHL_VERSION}..."
#pip3 install -U xformers --index-url "https://download.pytorch.org/whl/${CU_WHL_VERSION}"

# --- Model Downloads ---
echo "INFO: Downloading FLUX.1 models and custom nodes..."

# Ensure all target model directories exist
mkdir -p "${COMFYUI_DIR}/models/diffusion_models"
mkdir -p "${COMFYUI_DIR}/models/text_encoders"
mkdir -p "${COMFYUI_DIR}/models/vae"
mkdir -p "${COMFYUI_DIR}/models/loras"

# Models (FLUX.1 Nunchaku INT4)
# Diffuser/UNet Models -> models/diffusion_models/
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o svdq-fp4_r32-flux.1-dev.safetensors "https://huggingface.co/nunchaku-tech/nunchaku-flux.1-dev/resolve/main/svdq-fp4_r32-flux.1-dev.safetensors?download=true" || exit 1

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
# Kill any running main.py process.
pkill -f "main.py" || true

# Start the server using its full path and redirect output to a log file.
nohup python "${COMFYUI_DIR}/main.py" --listen 0.0.0.0 --port 8188 > "${COMFYUI_DIR}/comfyui.log" 2>&1 &

echo "INFO: Provisioning complete. ComfyUI is starting."

#END OF flux_nunchaku_fp4.sh
