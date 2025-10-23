#!/usr/bin/env bash
readonly COMFYUI_DIR="/workspace/madapps/ComfyUI"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o svdq-fp4_r32-flux.1-kontext-dev.safetensors "https://huggingface.co/nunchaku-tech/nunchaku-flux.1-kontext-dev/resolve/main/svdq-fp4_r32-flux.1-kontext-dev.safetensors?download=true"
