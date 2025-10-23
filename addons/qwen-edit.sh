#!/usr/bin/env bash
readonly COMFYUI_DIR="/workspace/madapps/ComfyUI"
aria2c -x 16 -s 16 --dir="${COMFYUI_DIR}/models/diffusion_models" -o Qwen_Image_Edit-Q4_K_M.gguf "https://huggingface.co/QuantStack/Qwen-Image-Edit-GGUF/resolve/main/Qwen_Image_Edit-Q4_K_M.gguf?download=true"
