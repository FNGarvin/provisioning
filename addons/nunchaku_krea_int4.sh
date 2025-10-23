#!/usr/bin/env bash
readonly COMFYUI_DIR="/workspace/madapps/ComfyUI"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o svdq-int4_r32-flux.1-krea-dev.safetensors "https://huggingface.co/nunchaku-tech/nunchaku-flux.1-krea-dev/resolve/main/svdq-int4_r32-flux.1-krea-dev.safetensors?download=true"
