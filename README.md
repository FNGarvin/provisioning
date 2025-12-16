# Provisioning Scripts for ComfyUI on Slim Docker Environments

This repository contains a curated collection of shell scripts (`.sh`) designed to automatically provision and set up specific models and custom nodes within a specific ComfyUI container image.

These scripts are optimized for performance by leveraging multi-connection downloads (`aria2c`). The Nunchaku scripts are now configured to use official, pre-built binaries for faster setup.

## Quickstart

* Pull and run the `madiator2011/better-comfyui:slim-5090` image
* Wait for the container to finish its minutes-long setup
* Open a shell using Zasper (the Jupyter clone this image ships with)/ssh/exec -it bash/whatever
* Run a script from the selection available that corresponds with your intended workflow, eg: ```curl -s [https://raw.githubusercontent.com/FNGarvin/provisioning/main/fastwan-5b.sh](https://raw.githubusercontent.com/FNGarvin/provisioning/main/fastwan-5b.sh) | bash```
* Wait for the script to complete, then launch open the ComfyUI app with your browser and choose a suitable template

## ⚠️ Environment Assumptions

All provisioning scripts are specifically configured for and assume the following environment:

* **Base Image:** `madiator2011/better-comfyui:slim-5090` (or similar minimal image).

## 📜 Script Index

Scripts are divided into core architectures and optional add-ons.

### Core Provisioning Scripts (Base Architectures)

These scripts install models and custom nodes for a functional core environment. Please be aware that the Nunchaku optimizations are exclusive to NVidia GPUs and the superior FP4 models are exclusive to RTX5xxx series GPUs.

| Filename | Architecture | Focus | Target GPU | Key Actions |
| :--- | :--- | :--- | :--- | :--- |
| `fastwan-5b.sh` | **Wan 2.2** | FP16/Safetensors | 16GB+ VRAM | Installs Wan 2.2 5B models and the FastWan-MovieGen custom node. |
| `fastwan-5b-8gb.sh` | **Wan 2.2** | GGUF Q3\_K\_S | Tested on 8GB VRAM | Installs GGUF-quantized models for tight VRAM constraints, plus ComfyUI-GGUF node. |
| `fastwan-5b-12gb.sh`| **Wan 2.2** | GGUF Q6\_K | Tested on 12GB VRAM | Installs intermediate-quality GGUF-quantized models, plus ComfyUI-GGUF node. |
| `qwen.sh`| **Qwen-Image** | Base GGUF | Tested on 12GB VRAM | Installs Q4 Qwen-Image GGUF with ComfyUI-GGUF node. |
| `flux_nunchaku_fp4.sh`| **FLUX.1** | Nunchaku FP4 | REQUIRES RTX 5XXX Series | Installs core FLUX models and installs Nunchaku for FP4 acceleration (Highest Performance). Also grabs the LORAs used in the Nunchaku example templates. |
| `flux_nunchaku_int4.sh`| **FLUX.1** | Nunchaku INT4 | GTX 1660 Ti and newer | Installs core FLUX models and installs Nunchaku for INT4 acceleration. Also grabs the LORAs used in the Nunchaku example templates. |
| `qwen_nunchaku_fp4.sh`| **Qwen-Image** | Nunchaku FP4 + GGUF | REQUIRES RTX 5XXX Series | Installs Qwen Nunchaku model and installs Nunchaku pairing with Q4 GGUF text encoder for FP4 acceleration. |
| `qwen_nunchaku_int4.sh`| **Qwen-Image** | Nunchaku INT4 + GGUF | GTX 1660 Ti and newer | Installs Qwen Nunchaku model and installs Nunchaku pairing with Q4 GGUF text encoder. |
| `flux2.sh`| **FLUX.2** | FP8/Safetensors | 16GB+ VRAM | Installs FLUX.2 models (Text Encoder, Diffusion Model, VAE). |

### Add-on Provisioning Scripts (Optional Models)

These scripts, located in the addons subdirectory, download optional diffuser models into the `models/diffusion_models` directory intended for pairing with one of the scripts above. Run like this: ```curl -s [https://raw.githubusercontent.com/FNGarvin/provisioning/main/addons/nunchaku_krea_int4.sh](https://raw.githubusercontent.com/FNGarvin/provisioning/main/addons/nunchaku_krea_int4.sh) | bash```

| Filename | Architecture | Focus | Complementary Script |
| :--- | :--- | :--- | :--- |
| `qwen-edit.sh` | Qwen-Image-Edit-2509 | Base Qwen-Image-Edit-2509 GGUF model. | `qwen.sh` |
| `nunchaku_qwen-edit_fp4.sh`| Qwen-Image-Edit-2509 | Nunchaku Qwen-Image-Edit-2509 FP4 model. | `qwen_nunchaku_fp4.sh` |
| `nunchaku_qwen-edit_int4.sh`| Qwen-Image-Edit-2509 | Nunchaku Qwen-Image-Edit-2509 INT4 model. | `qwen_nunchaku_int4.sh` |
| `nunchaku_kontext_fp4.sh`| FLUX.1 | Nunchaku FLUX.1-Kontext FP4 model. | `flux_nunchaku_fp4.sh` |
| `nunchaku_kontext_int4.sh`| FLUX.1 | Nunchaku FLUX.1-Kontext INT4 model. | `flux_nunchaku_int4.sh` |
| `nunchaku_krea_fp4.sh` | FLUX.1 | Nunchaku FLUX.1-Krea FP4 model. | `flux_nunchaku_fp4.sh` |
| `nunchaku_krea_int4.sh`| FLUX.1 | Nunchaku FLUX.1-Krea INT4 model. | `flux_nunchaku_int4.sh` |

## ⚠️ Current Known Issues and Workarounds

### ComfyUI LORA Loader Crash (Temporary Fix)

As of this release, a recent upstream ComfyUI commit introduced a bug that causes a crash when loading LORAs, particularly when using Nunchaku, due to an unexpected attribute access in `comfy/supported_models_base.py`. This issue has been logged upstream ([GitHub issue #710](https://github.com/nunchaku-tech/ComfyUI-nunchaku/issues/710)).

* **Workaround:** All Nunchaku provisioning scripts (the `flux_*` and `qwen_*` scripts) now include a hack that comments out the problematic lines of code. This is a temporary fix intended for immediate functionality.
* **Post-Fix Behavior:** Even with this fix, you may still experience issues when attempting to load a new LORA without first unloading the current model. For reliable LORA swapping, you may need to click the "Unload all models" button on the toolbar (if available) before switching the LORA.
* **Future Remediation:** We suspect that a proper fix from the developers may arrive after their immediate academic commitments (e.g., final exams) conclude. Once an upstream fix is merged, this hack will be removed from the provisioning scripts in a future update.

## ⚖️ Licensing

Please note the specific licensing for each set of scripts:

* **CC BY-NC 4.0:** The three **`fastwan-5b*`** provisioning scripts retain their original **CC BY-NC 4.0** license.
* **Apache License 2.0** Nunchaku is copyright Han Labs and generously licensed under the terms of the Apache License.
* **Public Domain:** All other scripts are released into the **Public Domain**.
