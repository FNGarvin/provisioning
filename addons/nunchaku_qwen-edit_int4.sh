#!/usr/bin/env bash
readonly COMFYUI_DIR="/workspace/madapps/ComfyUI"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o svdq-int4_r128-qwen-image-edit-2509-lightningv2.0-8steps.safetensors "https://huggingface.co/nunchaku-tech/nunchaku-qwen-image-edit-2509/resolve/main/svdq-int4_r128-qwen-image-edit-2509-lightningv2.0-8steps.safetensors?download=true"
