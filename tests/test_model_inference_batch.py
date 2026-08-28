"""
Drishti — SIH 2026 Problem Statement 26038
Automated Multi-Image Model Inference Sanity Test
"""
import os
import sys
import torch
import torch.nn as nn
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import numpy as np

def run_batch_test():
    print("=" * 70)
    print(" DRISHTI - PYTORCH RESNET-18 BATCH INFERENCE SANITY TEST")
    print("=" * 70)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"[*] Execution Device: {device}")

    ckpt_path = "models/EyeXpert_ResNet18_best.pth"
    if not os.path.isfile(ckpt_path):
        ckpt_path = "models/EyeXpert_ResNet18_state_dict.pth"

    if not os.path.isfile(ckpt_path):
        print(f"[!] ERROR: Checkpoint not found at {ckpt_path}")
        sys.exit(1)

    print(f"[*] Loading Checkpoint: {ckpt_path}")
    model = models.resnet18(weights=None)
    model.fc = nn.Linear(model.fc.in_features, 5)

    ckpt = torch.load(ckpt_path, map_location=device, weights_only=False)
    if isinstance(ckpt, dict) and "model_state_dict" in ckpt:
        model.load_state_dict(ckpt["model_state_dict"])
    elif isinstance(ckpt, dict) and "state_dict" in ckpt:
        model.load_state_dict(ckpt["state_dict"])
    else:
        model.load_state_dict(ckpt)

    model.to(device)
    model.eval()
    print("[*] Model Loaded and set to eval() mode successfully.\n")

    eval_tfm = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

    img_dir = "data/aptos/preprocessed_224"
    files = [f for f in os.listdir(img_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg'))][:15]

    label_names = {
        0: "Level 0: No DR",
        1: "Level 1: Mild NPDR",
        2: "Level 2: Moderate NPDR",
        3: "Level 3: Severe NPDR",
        4: "Level 4: Proliferative DR"
    }

    class_counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
    print(f"{'IMAGE FILENAME':<22} | {'PREDICTED':<22} | {'CONF':<6} | {'PROBABILITIES (L0 -> L4)'}")
    print("-" * 85)

    for fname in files:
        full_path = os.path.join(img_dir, fname)
        img = Image.open(full_path).convert("RGB")
        tensor = eval_tfm(img).unsqueeze(0).to(device)

        with torch.no_grad():
            logits = model(tensor)
            probs = torch.softmax(logits, dim=1).cpu().numpy()[0]
            pred_class = int(np.argmax(probs))
            conf = float(probs[pred_class]) * 100

        class_counts[pred_class] += 1
        probs_formatted = "[" + ", ".join([f"{p:.3f}" for p in probs]) + "]"
        print(f"{fname:<22} | {label_names[pred_class]:<22} | {conf:5.1f}% | {probs_formatted}")

    print("-" * 85)
    print("\n[*] Class Prediction Distribution Across Test Batch:")
    for lvl, count in class_counts.items():
        bar = "#" * (count * 3)
        print(f"    {label_names[lvl]:<24}: {count:2d} cases {bar}")

    unique_classes_predicted = sum(1 for c in class_counts.values() if c > 0)
    print(f"\n[*] Unique DR Classes Predicted: {unique_classes_predicted} / 5")

    if unique_classes_predicted < 2:
        print("[!] SANITY TEST FAILED: Model is predicting only a single constant class for all images!")
        sys.exit(1)
    else:
        print("[*] SANITY TEST PASSED: Model produces dynamic, image-specific predictions across the batch.\n")

if __name__ == "__main__":
    run_batch_test()
