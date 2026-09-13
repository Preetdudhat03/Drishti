"""
Drishti Canonical Retinal Preprocessing & Inference Pipeline
Version: fundus-v1
Shared conceptually across training, evaluation, and production inference.
"""

import hashlib
import uuid
import numpy as np
from PIL import Image
import torch
import torchvision.transforms as transforms
import cv2

PREPROCESSING_VERSION = "fundus-v1"
MODEL_VERSION = "EyeXpert_ResNet18_v1.0"

_EVAL_NORMALIZE = transforms.Normalize(
    mean=[0.485, 0.456, 0.406],
    std=[0.229, 0.224, 0.225]
)

def compute_sha256(raw_bytes: bytes) -> str:
    """Computes authoritative SHA-256 hexadecimal digest for raw image bytes."""
    return hashlib.sha256(raw_bytes).hexdigest()

def crop_retina_bounding_box(pil_img: Image.Image):
    """
    Detects retinal tissue boundary by segmenting non-background pixels (>15 intensity)
    and returns bounding-box coordinates [x0, y0, x1, y1] and cropped PIL Image.
    Matches exact training cropping procedure from train_aptos_real.py.
    """
    w, h = pil_img.size
    img_gray = np.array(pil_img.convert("L"))
    mask = img_gray > 15
    coords = np.argwhere(mask)
    if coords.size > 0:
        y0, x0 = coords.min(axis=0)
        y1, x1 = coords.max(axis=0) + 1
        crop_box = [int(x0), int(y0), int(x1), int(y1)]
        cropped_img = pil_img.crop((x0, y0, x1, y1))
    else:
        crop_box = [0, 0, int(w), int(h)]
        cropped_img = pil_img

    return crop_box, cropped_img

def preprocess_fundus_v1(pil_img: Image.Image, max_dim: int = 512):
    """
    Canonical 'fundus-v1' preprocessing:
    1. Downsamples extreme camera resolutions (>512px) for memory safety.
    2. Auto-crops circular retinal mask (removes black background borders).
    3. Resizes cropped retinal tissue to 224x224 (Bilinear).
    4. Converts to float32 Tensor and applies ImageNet normalization.
    Returns: (tensor_1x3x224x224, crop_box, cropped_pil, proc_pil)
    """
    w_orig, h_orig = pil_img.size
    if max(w_orig, h_orig) > max_dim:
        scale = max_dim / float(max(w_orig, h_orig))
        proc_pil = pil_img.resize((int(w_orig * scale), int(h_orig * scale)), Image.Resampling.BILINEAR)
    else:
        proc_pil = pil_img.copy()

    crop_box, cropped_pil = crop_retina_bounding_box(proc_pil)
    resized_224 = cropped_pil.resize((224, 224), Image.Resampling.BILINEAR)
    tensor = transforms.ToTensor()(resized_224)
    tensor = _EVAL_NORMALIZE(tensor).unsqueeze(0)

    return tensor, crop_box, cropped_pil, proc_pil

def generate_gradcam_and_overlay(model, tensor_img, pil_img, crop_box, pred_level, device="cpu"):
    """
    Computes Layer4 Grad-CAM activation heatmap for predicted class on cropped retina,
    then maps the heatmap back to the coordinate space of the input fundus image.
    Preserves full anatomical landmarks (optic disc, macula, vessel arcades) for clinician review.
    """
    w_orig, h_orig = pil_img.size
    x0, y0, x1, y1 = crop_box

    features = []
    grads = []
    last_conv = model.layer4[1].conv2

    def forward_hook(module, inp, out):
        features.append(out)

    def backward_hook(module, grad_in, grad_out):
        grads.append(grad_out[0])

    hf = last_conv.register_forward_hook(forward_hook)
    hb = last_conv.register_full_backward_hook(backward_hook)

    model.zero_grad()
    logits = model(tensor_img.to(device))
    soft_probs = torch.softmax(logits, dim=1).detach().cpu().numpy()[0]

    score = logits[0, pred_level]
    score.backward()

    hf.remove()
    hb.remove()

    f_act = features[0][0].detach().cpu().numpy()
    g_act = grads[0][0].detach().cpu().numpy()
    weights = np.mean(g_act, axis=(1, 2))
    cam = np.zeros(f_act.shape[1:], dtype=np.float32)
    for idx, w in enumerate(weights):
        cam += w * f_act[idx]
    cam = np.maximum(0, cam)
    if np.max(cam) > 0:
        cam = (cam - np.min(cam)) / (np.max(cam) - np.min(cam) + 1e-8)

    # Map Grad-CAM back to crop_box inside full image dimensions
    crop_w = max(1, x1 - x0)
    crop_h = max(1, y1 - y0)
    cam_cropped = cv2.resize(cam, (crop_w, crop_h), interpolation=cv2.INTER_LINEAR)

    full_cam = np.zeros((h_orig, w_orig), dtype=np.float32)
    full_cam[y0:y1, x0:x1] = cam_cropped
    full_cam = np.clip(full_cam, 0.0, 1.0)

    # Colorize full CAM with Turbo colormap
    cam_uint8 = (full_cam * 255).astype(np.uint8)
    cam_colored_bgr = cv2.applyColorMap(cam_uint8, cv2.COLORMAP_TURBO)
    cam_colored = cv2.cvtColor(cam_colored_bgr, cv2.COLOR_BGR2RGB)

    orig_np = np.array(pil_img.convert("RGB"), dtype=np.float32)
    alpha = (full_cam[:, :, np.newaxis] * 0.45)
    overlay_np = np.clip((1.0 - alpha) * orig_np + alpha * cam_colored.astype(np.float32), 0, 255).astype(np.uint8)

    return {
        "cam_colored": Image.fromarray(cam_colored),
        "overlay_img": Image.fromarray(overlay_np),
        "full_cam_raw": full_cam,
        "crop_box": crop_box,
    }
