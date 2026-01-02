# Step-by-Step Provisioning Guide for RunPod

If you are new to RunPod or cloud-based GPUs, this guide will walk you through the entire process of setting up a pod and running these provisioning scripts.  This specific walkthrough demonstrates the **Wan 2.2 5B FastWan distillation**, which provides high-quality 720p text-to-video (and mediocre image-to-video) at impressive speeds, but ComfyUI is capable of so much more.  For some other provisioning scripts, look [here](./README.md).  Or, once you become comfortable with downloading and using arbitrary models, browse through the many available templates inside ComfyUI or on [CivitAI](https://civitai.com/) and pick out something you'd like to try.  

---

## 1. Account Setup and Funding
Before you can deploy a GPU, you must create a RunPod account.  Once registered, navigate to the **Billing** section.  RunPod operates on a pay-as-you-go model; you will need to top up your account with a minimum of $10 to begin.  For this tutorial, we are using an **RTX 3090** on the Community Cloud, which typically costs less than **$0.25/hr**.  RunPod bills to the nearest second, so your actual cost for a short testing session will be just a few cents.  

## 2. Select Your Base Template
Navigate to the **Templates** or **GPU Selection** screen.  For these scripts, we recommend starting with a high-performance base.  
* **Template Choice:** Selecting the default RunPod ComfyUI template works well.  In this example, we are using the **ComfyUI - Blackwell Edition (5090 / B200)** as a robust starting point (the 5090 / B200 in the title merely indicates that it's updated to support these GPUs, not that they are the minimum requirement).  

![Template Selection](./images/choose_template.jpg)

## 3. Configure Storage and Overrides
To ensure the model weights have enough room and to keep costs down, you need to adjust the disk settings.  
* **Volume Disk:** Set this to **0**.  This is temporary storage for general testing and prevents you from being billed for storage after the pod is terminated.  
* **Container Disk:** Increase this to **150 GB**.  The model weights for Wan 2.2 are large and require plenty of space.  
* Click **Set Overrides** to confirm these changes.  

![Storage Configuration](./images/zero_volume.jpg)

## 4. Review Deployment Parameters
Perform a final sanity check on your pod summary.  Ensure the template listed is correct.  Verify that you have a GPU with at least 16 GB of VRAM (for the "full-fat" version of this script, a 16 GB+ card like the 3090 is required).  Confirm that the "Stopped Pod disk cost" is **$0.00/hr**.  Once ready, hit the large **Deploy** button at the bottom of the screen.  

![Deployment Summary](./images/deploy_parameters.jpg)

## 5. Monitor the Boot Process
After deployment, click on your pod in the "My Pods" list to expand the menu.  
* **System Logs:** Click the **Logs** tab and then the **System** button.  Wait until you see the image load and the "start container" sequence begin.  

![System Logs](./images/system_done.jpg)

* **Container Logs:** Switch to the **Container** button.  Wait until the logs indicate that "All startup tasks have been completed."  

![Container Logs](./images/container_done.jpg)

## 6. Open the Terminal
Go to the **Connect** tab.  Click on **Connect to JupyterLab**.  Once Jupyter opens, find the "Other" section at the bottom of the launcher and click the **Terminal** icon.  

![Connecting](./images/connect_to_jupyter.jpg)
![Terminal Icon](./images/terminal.jpg)

## 7. Run the Provisioning Script
Copy the curl command for the FastWan 5B script from the main repository.  In the Jupyter terminal, right-click and choose **Paste**, then hit **Enter**.  

```bash
curl -s https://raw.githubusercontent.com/FNGarvin/provisioning/main/fastwan-5b.sh | bash
```

The script will automatically download the necessary model weights, LoRAs, and custom nodes.  

![Pasting Script](./images/paste.jpg)

## 8. Launch ComfyUI
Once the terminal displays `Provisioning complete` or something similar, return to your RunPod dashboard browser tab.  Go back to the **Connect** tab (the same place you found the Jupyter link) and click the link for **Port 8188 (ComfyUI)**.  

![Provisioning Complete](./images/provisioning_complete.jpg)
![Return to Connect Tab](./images/connect_to_jupyter.jpg)

## 9. Select Template and Prompt
When ComfyUI opens, you may see a yellow alert regarding a front-end mismatch or other warnings.  Simply click the **X** to dismiss it.  

![Dismissing Alerts](./images/alert.jpg)

1. Click the **Templates** button in the ComfyUI sidebar if the template selection dialog is not already up.  
2. Select the template appropriate for your script (in this case, **FastWan-Simple**).  
3. **Prompting:** Enter your text prompt.  
4. **Image-to-Video (Optional):** If you wish to use an image as input, click the **Load Image** node and press `Ctrl+B` (or right-click and choose "Enable") to activate it, and upload your file.  
5. Hit **Run**.  

![Workflow Setup](./images/select_template.jpg)
![Prompting](./images/prompt_and_go.jpg)

## 10. Results and Saving
On an RTX 3090, a five-second video at 24fps typically takes between **110 to 120 seconds** to generate.  Once the process is complete, right-click the output video and select **Save Video As...** if you wish to download your work.  

![Saving Work](./images/save_your_work.jpg)

### Completed Demo
Below is a preview of the output.  Please note that the animated GIF is compressed for web viewing; the actual generated MP4 file has significantly higher fidelity and smoother motion.  

![FastWan Demo](./images/horses.gif)  
[Download the high-quality MP4 here](./images/horses.mp4)

---

### Important: Cleaning Up
When you are finished with your session, remember to **Terminate** your pod from the RunPod dashboard.  It's the red button seen below:

![Don't be late to terminate](./images/connect_to_jupyter.jpg)

---

## Addendum: Operating via Mobile Phone

If you are forced to navigate the ComfyUI interface on a mobile device, the smaller screen real estate introduces a few unique hurdles.  Here is how to handle them:

### Accessing the Run Button
On many mobile browsers, the ComfyUI toolbar is too wide to fit the screen, often hiding the **Run** (Queue Prompt) button.  To fix this, look for the small grid/grip icon on the far right of the visible toolbar.  Touch and drag this "grip" to the left to slide the toolbar over and reveal the hidden buttons.  

![Revealing the Run Button](./images/click-dots-and-drag-hidden-run-button.png)

### Enabling Image-to-Video (Removing Bypass)
To use a source image on a mobile device, you must take the **Load Image** node off of "bypass" mode.  Because right-clicking is not an option, follow these steps:
1.  **Select the Node:** Tap the **Load Image** node once to highlight it.  
2.  **Open the Menu:** Tap the three dots (context menu) that appear in the node's floating toolbar.  
3.  **Remove Bypass:** Scroll down and tap **Remove Bypass**.  The node will change from a purple/greyed-out state to its active colors.  

![Removing Bypass on Mobile](./images/click-dots-and-remove-bypass-for-i2v.png)

> [!NOTE]
> While these workarounds make mobile use possible, a desktop or laptop remains the highly recommended way to interact with these tools due to the complexity of the node-based layout.