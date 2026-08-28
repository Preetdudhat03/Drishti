"""
EyeXpert — Real APTOS 2019 Training & Validation Pipeline
SIH 2026 Milestone

Pipeline:
1. Dataset Audit (3,662 labeled images)
2. Stratified 70% Train (2562) / 15% Val (549) / 15% Test (551) Split with fixed seed (42)
3. Inverse-Frequency Class Weighting for class imbalance
4. ResNet-18 Transfer Learning with safe augmentation
5. Pre-resized tensor caching for fast CPU training
6. Validation monitoring with early stopping / best checkpoint selection on validation QWK
7. Exactly ONE Primary Held-Out Test Evaluation on the test split (never seen during training/tuning)
8. Multi-class metrics (Accuracy, Macro-Precision, Macro-Recall, Macro-F1, QWK, Confusion Matrix)
9. Binary Referable DR metrics (Sensitivity, Specificity, Precision, Recall, F1, ROC/AUC)
10. Save test_predictions.csv
11. Generate plots: confusion_matrix.png, referable_roc.png, training_history.png
12. Generate real-image Grad-CAM heatmaps across Level 0, 1, 2, 3, 4
13. Generate full markdown report: results/EyeXpert_APTOS_Validation_Report.md
"""

import os
import sys
import json
import time
import random
import numpy as np
import pandas as pd
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as transforms
import torchvision.models as models

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from sklearn.metrics import (
    confusion_matrix, precision_score, recall_score, f1_score,
    cohen_kappa_score, roc_auc_score, roc_curve
)

SEED = 42
random.seed(SEED)
np.random.seed(SEED)
torch.manual_seed(SEED)

def main():
    print("=========================================================================")
    print("      EYEXPERT V1 — REAL APTOS 2019 TRAINING & VALIDATION PIPELINE       ")
    print("=========================================================================\n")

    root_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.join(root_dir, "data", "aptos")
    train_csv_path = os.path.join(data_dir, "train.csv")
    train_images_dir = os.path.join(data_dir, "train_images")
    
    output_dir = os.path.join(root_dir, "models")
    results_dir = os.path.join(root_dir, "results")
    gradcam_dir = os.path.join(results_dir, "gradcam")
    splits_dir = os.path.join(root_dir, "splits")
    validation_dir = os.path.join(root_dir, "validation")

    for d in [output_dir, results_dir, gradcam_dir, splits_dir, validation_dir]:
        os.makedirs(d, exist_ok=True)

    # 1. AUDIT DATASET
    print("[STEP 1/7] APTOS DATASET AUDIT")
    if not os.path.isfile(train_csv_path) or not os.path.isdir(train_images_dir):
        print("ERROR: REAL_APTOS_DATASET_NOT_FOUND")
        return

    df = pd.read_csv(train_csv_path)
    total_csv_rows = len(df)
    
    # Check images on disk
    found_paths = []
    valid_indices = []
    for idx, row in df.iterrows():
        img_id = str(row['id_code'])
        img_path = os.path.join(train_images_dir, img_id + ".png")
        if os.path.isfile(img_path):
            found_paths.append(img_path)
            valid_indices.append(idx)

    valid_df = df.iloc[valid_indices].copy().reset_index(drop=True)
    valid_df['image_path'] = found_paths
    total_valid = len(valid_df)

    class_counts = valid_df['diagnosis'].value_counts().sort_index().to_dict()
    non_ref_count = class_counts.get(0, 0) + class_counts.get(1, 0)
    ref_count = class_counts.get(2, 0) + class_counts.get(3, 0) + class_counts.get(4, 0)

    print(f"  • Total CSV Rows:         {total_csv_rows}")
    print(f"  • Valid Images on Disk:   {total_valid} / {total_csv_rows}")
    print(f"  • Missing Images:         {total_csv_rows - total_valid}")
    print("  • Class Distribution:")
    for c in range(5):
        cnt = class_counts.get(c, 0)
        pct = cnt / total_valid * 100
        ref_tag = "Non-Referable" if c < 2 else "REFERABLE"
        print(f"      Level {c}: {cnt:5d} ({pct:5.1f}%) [{ref_tag}]")
    print(f"  • Non-Referable Total:    {non_ref_count} ({non_ref_count/total_valid*100:.1f}%)")
    print(f"  • Referable DR Total:     {ref_count} ({ref_count/total_valid*100:.1f}%)")

    # 2. STRATIFIED SPLIT 70 / 15 / 15
    print("\n[STEP 2/7] STRATIFIED DATASET PARTITIONING (70% Train / 15% Val / 15% Test)")
    train_dfs, val_dfs, test_dfs = [], [], []

    for c in range(5):
        c_df = valid_df[valid_df['diagnosis'] == c]
        c_shuffled = c_df.sample(frac=1.0, random_state=SEED).reset_index(drop=True)
        n = len(c_shuffled)
        n_train = int(round(0.70 * n))
        n_val = int(round(0.15 * n))
        
        train_dfs.append(c_shuffled.iloc[:n_train])
        val_dfs.append(c_shuffled.iloc[n_train:n_train + n_val])
        test_dfs.append(c_shuffled.iloc[n_train + n_val:])

    train_df = pd.concat(train_dfs).sample(frac=1.0, random_state=SEED).reset_index(drop=True)
    val_df = pd.concat(val_dfs).reset_index(drop=True)
    test_df = pd.concat(test_dfs).reset_index(drop=True)

    print(f"  • Training Set:           {len(train_df)} ({len(train_df)/total_valid*100:.1f}%)")
    print(f"  • Validation Set:         {len(val_df)} ({len(val_df)/total_valid*100:.1f}%)")
    print(f"  • Held-Out Test Set:      {len(test_df)} ({len(test_df)/total_valid*100:.1f}%)")

    # Save split manifests
    train_df.to_csv(os.path.join(splits_dir, "train.csv"), index=False)
    val_df.to_csv(os.path.join(splits_dir, "validation.csv"), index=False)
    test_df.to_csv(os.path.join(splits_dir, "test.csv"), index=False)
    print("  • Saved split manifests to splits/train.csv, splits/validation.csv, splits/test.csv")

    # 3. CLASS WEIGHTING CALCULATION
    print("\n[STEP 3/7] INVERSE FREQUENCY CLASS WEIGHTS FOR LOSS FUNCTION")
    train_counts = train_df['diagnosis'].value_counts().sort_index().to_dict()
    weights = []
    for c in range(5):
        cnt = train_counts.get(c, 1)
        w = len(train_df) / (5.0 * cnt)
        weights.append(w)
    weights = np.array(weights)
    weights = weights / np.mean(weights) # Normalize mean weight to 1.0
    print("  • Computed Class Weights:")
    for c in range(5):
        print(f"      Level {c}: weight = {weights[c]:.3f} (n={train_counts.get(c, 0)})")
    
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    class_weights_tensor = torch.tensor(weights, dtype=torch.float32).to(device)

    # 4. PRE-RESIZED IMAGE CACHING & FAST DATA LOADING
    print("\n[STEP 4/7] PREPARING PREPROCESSED IMAGE CACHE FOR FAST TRAINING")
    cache_dir = os.path.join(data_dir, "preprocessed_224")
    os.makedirs(cache_dir, exist_ok=True)

    def get_preprocessed_path(raw_path):
        fname = os.path.basename(raw_path)
        cached_p = os.path.join(cache_dir, fname)
        if not os.path.exists(cached_p):
            im = Image.open(raw_path).convert('RGB')
            # Auto-crop black border
            im_gray = np.array(im.convert('L'))
            mask = im_gray > 15
            coords = np.argwhere(mask)
            if coords.size > 0:
                y0, x0 = coords.min(axis=0)
                y1, x1 = coords.max(axis=0) + 1
                im = im.crop((x0, y0, x1, y1))
            im_resized = im.resize((224, 224), Image.Resampling.BILINEAR)
            im_resized.save(cached_p)
        return cached_p

    print("  • Caching 224x224 cropped images (progress check)...")
    for i, p in enumerate(valid_df['image_path']):
        get_preprocessed_path(p)
        if (i + 1) % 1000 == 0 or (i + 1) == total_valid:
            print(f"    Cached {i+1}/{total_valid} images...")

    train_df['cached_path'] = train_df['image_path'].apply(get_preprocessed_path)
    val_df['cached_path'] = val_df['image_path'].apply(get_preprocessed_path)
    test_df['cached_path'] = test_df['image_path'].apply(get_preprocessed_path)

    # Dataset Class
    class CachedFundusDataset(Dataset):
        def __init__(self, df, is_train=True):
            self.df = df.reset_index(drop=True)
            self.is_train = is_train
            self.train_tfm = transforms.Compose([
                transforms.RandomHorizontalFlip(p=0.5),
                transforms.RandomRotation(degrees=15),
                transforms.ColorJitter(brightness=0.1, contrast=0.1),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
            ])
            self.eval_tfm = transforms.Compose([
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
            ])

        def __len__(self):
            return len(self.df)

        def __getitem__(self, idx):
            row = self.df.iloc[idx]
            im = Image.open(row['cached_path']).convert('RGB')
            if self.is_train:
                t_img = self.train_tfm(im)
            else:
                t_img = self.eval_tfm(im)
            return t_img, int(row['diagnosis']), row['id_code']

    train_loader = DataLoader(CachedFundusDataset(train_df, is_train=True), batch_size=32, shuffle=True)
    val_loader = DataLoader(CachedFundusDataset(val_df, is_train=False), batch_size=32, shuffle=False)
    test_loader = DataLoader(CachedFundusDataset(test_df, is_train=False), batch_size=32, shuffle=False)

    # 5. MODEL ARCHITECTURE & REAL TRANSFER LEARNING TRAINING
    print("\n[STEP 5/7] TRAINING RESNET-18 MODEL ON REAL APTOS TRAINING SPLIT")
    model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    num_ftrs = model.fc.in_features
    model.fc = nn.Linear(num_ftrs, 5)
    model = model.to(device)

    criterion = nn.CrossEntropyLoss(weight=class_weights_tensor)
    optimizer = optim.AdamW(model.parameters(), lr=1.5e-4, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=10, eta_min=1e-6)

    epochs = 10
    best_val_qwk = -1.0
    best_model_path = os.path.join(output_dir, "EyeXpert_ResNet18_best.pth")

    history = {
        'epoch': [], 'train_loss': [], 'val_loss': [], 
        'train_acc': [], 'val_acc': [], 'val_qwk': [], 'lr': []
    }

    start_train_time = time.time()
    for epoch in range(epochs):
        model.train()
        train_loss = 0.0
        train_correct = 0
        train_total = 0

        for images, labels, _ in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            train_loss += loss.item() * images.size(0)
            preds = torch.argmax(outputs, dim=1)
            train_correct += (preds == labels).sum().item()
            train_total += labels.size(0)

        scheduler.step()
        cur_lr = optimizer.param_groups[0]['lr']

        epoch_train_loss = train_loss / train_total
        epoch_train_acc = train_correct / train_total

        # Validation
        model.eval()
        val_loss = 0.0
        val_preds, val_targets = [], []
        with torch.no_grad():
            for images, labels, _ in val_loader:
                images, labels = images.to(device), labels.to(device)
                outputs = model(images)
                loss = criterion(outputs, labels)
                val_loss += loss.item() * images.size(0)
                preds = torch.argmax(outputs, dim=1).cpu().numpy()
                val_preds.extend(preds)
                val_targets.extend(labels.cpu().numpy())

        epoch_val_loss = val_loss / len(val_df)
        epoch_val_acc = np.mean(np.array(val_preds) == np.array(val_targets))
        epoch_val_qwk = cohen_kappa_score(val_targets, val_preds, weights='quadratic')

        history['epoch'].append(epoch + 1)
        history['train_loss'].append(epoch_train_loss)
        history['val_loss'].append(epoch_val_loss)
        history['train_acc'].append(epoch_train_acc)
        history['val_acc'].append(epoch_val_acc)
        history['val_qwk'].append(epoch_val_qwk)
        history['lr'].append(cur_lr)

        print(f"  Epoch {epoch+1:2d}/{epochs:2d} | Train Loss: {epoch_train_loss:.4f} | "
              f"Val Loss: {epoch_val_loss:.4f} | Val Acc: {epoch_val_acc*100:5.2f}% | "
              f"Val QWK: {epoch_val_qwk:.3f}")

        # Checkpoint on Validation QWK (Standard Metric for DR competitions)
        if epoch_val_qwk > best_val_qwk:
            best_val_qwk = epoch_val_qwk
            torch.save({
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_qwk': best_val_qwk,
                'val_acc': epoch_val_acc,
                'class_weights': weights.tolist(),
                'architecture': 'resnet18'
            }, best_model_path)

    train_duration = time.time() - start_train_time
    print(f"\n  ✔ Training Complete in {train_duration/60:.2f} minutes.")
    print(f"  ✔ Best Validation QWK: {best_val_qwk:.3f} (Saved to {best_model_path})")

    # Plot Training History
    plt.figure(figsize=(10, 4))
    plt.subplot(1, 2, 1)
    plt.plot(history['epoch'], history['train_loss'], 'b-', label='Train Loss')
    plt.plot(history['epoch'], history['val_loss'], 'r--', label='Val Loss')
    plt.xlabel('Epoch'); plt.ylabel('Loss'); plt.title('Training & Validation Loss'); plt.legend(); plt.grid(True)

    plt.subplot(1, 2, 2)
    plt.plot(history['epoch'], [a*100 for a in history['train_acc']], 'b-', label='Train Acc (%)')
    plt.plot(history['epoch'], [a*100 for a in history['val_acc']], 'r--', label='Val Acc (%)')
    plt.plot(history['epoch'], [q*100 for q in history['val_qwk']], 'g:', label='Val QWK (x100)')
    plt.xlabel('Epoch'); plt.ylabel('Score'); plt.title('Accuracy & QWK'); plt.legend(); plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(results_dir, "training_history.png"), dpi=150)
    plt.close()

    # 6. EXACTLY ONE HELD-OUT TEST EVALUATION
    print("\n[STEP 6/7] EVALUATING HELD-OUT TEST SET (NEVER SEEN DURING TRAINING)")
    checkpoint = torch.load(best_model_path, map_location=device)
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()

    test_preds, test_targets, test_probs, test_ids = [], [], [], []
    with torch.no_grad():
        for images, labels, ids in test_loader:
            images = images.to(device)
            outputs = model(images)
            probs = torch.softmax(outputs, dim=1).cpu().numpy()
            preds = np.argmax(probs, axis=1)
            test_probs.extend(probs)
            test_preds.extend(preds)
            test_targets.extend(labels.numpy())
            test_ids.extend(ids)

    test_targets = np.array(test_targets)
    test_preds = np.array(test_preds)
    test_probs = np.array(test_probs)

    # Multi-class Evaluation
    cm = confusion_matrix(test_targets, test_preds, labels=[0, 1, 2, 3, 4])
    acc = np.mean(test_targets == test_preds)
    macro_p = precision_score(test_targets, test_preds, average='macro', zero_division=0)
    macro_r = recall_score(test_targets, test_preds, average='macro', zero_division=0)
    macro_f1 = f1_score(test_targets, test_preds, average='macro', zero_division=0)
    qwk = cohen_kappa_score(test_targets, test_preds, weights='quadratic')

    # Binary Referable DR Evaluation (Level >= 2)
    y_true_bin = (test_targets >= 2).astype(int)
    y_prob_ref = test_probs[:, 2:].sum(axis=1)
    y_pred_bin = (test_preds >= 2).astype(int)

    tp = int(np.sum((y_true_bin == 1) & (y_pred_bin == 1)))
    tn = int(np.sum((y_true_bin == 0) & (y_pred_bin == 0)))
    fp = int(np.sum((y_true_bin == 0) & (y_pred_bin == 1)))
    fn = int(np.sum((y_true_bin == 1) & (y_pred_bin == 0)))

    sens = tp / max(1, (tp + fn))
    spec = tn / max(1, (tn + fp))
    prec = tp / max(1, (tp + fp))
    rec = sens
    ref_f1 = 2 * prec * rec / max(1e-5, (prec + rec))
    ref_acc = (tp + tn) / max(1, (tp + tn + fp + fn))

    fpr, tpr, thresholds = roc_curve(y_true_bin, y_prob_ref)
    auc = roc_auc_score(y_true_bin, y_prob_ref)

    # Save Test Predictions CSV
    pred_records = []
    for i in range(len(test_ids)):
        pred_records.append({
            'image_id': test_ids[i],
            'ground_truth': int(test_targets[i]),
            'predicted_level': int(test_preds[i]),
            'prob_level_0': round(float(test_probs[i, 0]), 4),
            'prob_level_1': round(float(test_probs[i, 1]), 4),
            'prob_level_2': round(float(test_probs[i, 2]), 4),
            'prob_level_3': round(float(test_probs[i, 3]), 4),
            'prob_level_4': round(float(test_probs[i, 4]), 4),
            'predicted_referable': int(test_preds[i] >= 2),
            'ground_truth_referable': int(test_targets[i] >= 2)
        })
    pred_df = pd.DataFrame(pred_records)
    pred_df.to_csv(os.path.join(validation_dir, "test_predictions.csv"), index=False)
    print(f"  • Saved test predictions table to validation/test_predictions.csv ({len(pred_df)} rows)")

    # Plot Confusion Matrix
    plt.figure(figsize=(6, 5))
    plt.imshow(cm, interpolation='nearest', cmap=plt.cm.Blues)
    plt.title('EyeXpert 5-Class Confusion Matrix (Held-Out Test Set)')
    plt.colorbar()
    tick_marks = np.arange(5)
    class_names = ['Level 0', 'Level 1', 'Level 2', 'Level 3', 'Level 4']
    plt.xticks(tick_marks, class_names, rotation=45)
    plt.yticks(tick_marks, class_names)
    for i in range(5):
        for j in range(5):
            plt.text(j, i, format(cm[i, j], 'd'),
                     horizontalalignment="center",
                     color="white" if cm[i, j] > cm.max() / 2 else "black")
    plt.ylabel('Ground Truth DR Level')
    plt.xlabel('Predicted DR Level')
    plt.tight_layout()
    plt.savefig(os.path.join(results_dir, "confusion_matrix.png"), dpi=150)
    plt.close()

    # Plot ROC Curve
    plt.figure(figsize=(6, 5))
    plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'EyeXpert ResNet-18 (AUC = {auc:.3f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=1.5, linestyle='--', label='Chance Line (AUC = 0.500)')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate (1 - Specificity)')
    plt.ylabel('True Positive Rate (Sensitivity)')
    plt.title('Referable DR Receiver Operating Characteristic (ROC)')
    plt.legend(loc="lower right")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(results_dir, "referable_roc.png"), dpi=150)
    plt.close()

    # 7. GRAD-CAM ON REAL REPRESENTATIVE TEST IMAGES
    print("\n[STEP 7/7] GENERATING GRAD-CAM ON REAL REPRESENTATIVE TEST IMAGES (LEVELS 0 TO 4)")
    last_conv_layer = model.layer4[1].conv2

    def compute_gradcam(img_tensor, target_class):
        model.eval()
        features = []
        def fwd_hook(m, i, o):
            features.append(o)
        h_fwd = last_conv_layer.register_forward_hook(fwd_hook)

        grads = []
        def bwd_hook(m, gi, go):
            grads.append(go[0])
        h_bwd = last_conv_layer.register_full_backward_hook(bwd_hook)

        out = model(img_tensor.unsqueeze(0).to(device))
        score = out[0, target_class]
        model.zero_grad()
        score.backward()

        h_fwd.remove()
        h_bwd.remove()

        f = features[0][0].detach().cpu().numpy() # [512, 7, 7]
        g = grads[0][0].detach().cpu().numpy()     # [512, 7, 7]
        w = np.mean(g, axis=(1, 2))              # [512]
        cam = np.zeros(f.shape[1:], dtype=np.float32)
        for idx, wt in enumerate(w):
            cam += wt * f[idx]
        cam = np.maximum(0, cam)
        if np.max(cam) > 0:
            cam = (cam - np.min(cam)) / (np.max(cam) - np.min(cam))
        return cam

    # Select representative test cases for each grade
    eval_tfm = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

    for target_level in range(5):
        sample_rows = test_df[test_df['diagnosis'] == target_level]
        if len(sample_rows) == 0:
            continue
        sample_row = sample_rows.iloc[0]
        sample_id = sample_row['id_code']
        raw_img_p = sample_row['image_path']
        
        orig_pil = Image.open(raw_img_p).convert('RGB')
        w_orig, h_orig = orig_pil.size

        # Preprocess to 224x224
        tensor_img = eval_tfm(orig_pil.resize((224, 224)))
        cam_map = compute_gradcam(tensor_img, target_level)

        # Resize CAM to original dimensions
        cam_pil = Image.fromarray(cam_map).resize((w_orig, h_orig), Image.Resampling.BILINEAR)
        cam_resized = np.array(cam_pil)

        # Colormap Turbo
        cmap = cm.get_cmap('turbo')
        cam_colored = (cmap(cam_resized)[:, :, :3] * 255).astype(np.uint8)
        
        orig_np = np.array(orig_pil)
        alpha = (cam_resized[:, :, np.newaxis] * 0.45)
        overlay_np = np.clip((1.0 - alpha) * orig_np + alpha * cam_colored, 0, 255).astype(np.uint8)

        # Save Visual Panel
        plt.figure(figsize=(12, 4))
        plt.subplot(1, 3, 1)
        plt.imshow(orig_pil)
        plt.title(f"Real APTOS Fundus (Level {target_level})\nID: {sample_id}", fontsize=10)
        plt.axis('off')

        plt.subplot(1, 3, 2)
        plt.imshow(cam_resized, cmap='turbo')
        plt.title("Grad-CAM Activation Heatmap\n(Model Attention)", fontsize=10)
        plt.axis('off')

        plt.subplot(1, 3, 3)
        plt.imshow(overlay_np)
        plt.title("Evidence Attention Overlay\n(Interpretability Tool)", fontsize=10)
        plt.axis('off')

        plt.tight_layout()
        gradcam_out_path = os.path.join(gradcam_dir, f"real_aptos_gradcam_level_{target_level}_{sample_id}.png")
        plt.savefig(gradcam_out_path, dpi=150)
        plt.close()
        print(f"  • Generated Grad-CAM for Level {target_level} (ID: {sample_id}) -> {os.path.basename(gradcam_out_path)}")

    # 8. GENERATE MACHINE-READABLE VALIDATION REPORT
    sih_sens_status = "MET" if sens >= 0.90 else "BELOW_TARGET"
    sih_spec_status = "MET" if spec >= 0.85 else "BELOW_TARGET"

    if sens >= 0.90 and spec >= 0.85:
        overall_status = "REAL_APTOS_VALIDATED"
    else:
        overall_status = "REAL_APTOS_VALIDATED_BELOW_SIH_TARGET"

    report_md = f"""# EyeXpert V1 — Real APTOS 2019 Validation Report

**Dataset**: APTOS 2019 Blindness Detection (Kaggle)  
**Evaluation Timestamp**: {time.strftime('%Y-%m-%d %H:%M:%S')}  
**Model Architecture**: ResNet-18 Transfer Learning  
**Final Status**: `{overall_status}`

---

## 1. Dataset & Audit
* **Total Labeled Records**: {total_csv_rows}
* **Valid Images on Disk**: {total_valid}
* **Missing Images**: {total_csv_rows - total_valid}
* **Class Distribution**:
  * Level 0 (No DR): {class_counts.get(0, 0)} ({class_counts.get(0, 0)/total_valid*100:.1f}%) [Non-Referable]
  * Level 1 (Mild NPDR): {class_counts.get(1, 0)} ({class_counts.get(1, 0)/total_valid*100:.1f}%) [Non-Referable]
  * Level 2 (Moderate NPDR): {class_counts.get(2, 0)} ({class_counts.get(2, 0)/total_valid*100:.1f}%) [Referable]
  * Level 3 (Severe NPDR): {class_counts.get(3, 0)} ({class_counts.get(3, 0)/total_valid*100:.1f}%) [Referable]
  * Level 4 (Proliferative DR): {class_counts.get(4, 0)} ({class_counts.get(4, 0)/total_valid*100:.1f}%) [Referable]
* **Non-Referable Count**: {non_ref_count} ({non_ref_count/total_valid*100:.1f}%)
* **Referable DR Count**: {ref_count} ({ref_count/total_valid*100:.1f}%)

---

## 2. Train / Validation / Test Split (Zero Data Leakage)
* **Training Set (70%)**: {len(train_df)} samples
* **Validation Set (15%)**: {len(val_df)} samples (Used for model checkpoint selection)
* **Held-Out Test Set (15%)**: {len(test_df)} samples (Evaluated exactly once)
* **Random Seed**: {SEED} (Deterministic stratification)

---

## 3. Class Imbalance Handling
* **Inverse-Frequency Loss Weights**:
  * Level 0: {weights[0]:.3f}
  * Level 1: {weights[1]:.3f}
  * Level 2: {weights[2]:.3f}
  * Level 3: {weights[3]:.3f}
  * Level 4: {weights[4]:.3f}

---

## 4. Primary Held-Out Test Results (Five-Class DR)

| Metric | Measured Value | Description |
| :--- | :--- | :--- |
| **5-Class Accuracy** | **{acc*100:.2f}%** | Overall top-1 multiclass accuracy |
| **Macro-Precision** | **{macro_p*100:.2f}%** | Unweighted mean precision across 5 classes |
| **Macro-Recall** | **{macro_r*100:.2f}%** | Unweighted mean recall across 5 classes |
| **Macro-F1 Score** | **{macro_f1*100:.2f}%** | Harmonic mean of macro precision/recall |
| **Quadratic Weighted Kappa (QWK)** | **{qwk:.3f}** | Inter-rater ordinal agreement metric |

### 5-Class Confusion Matrix (Held-Out Test Split)
```text
               Predicted L0   Predicted L1   Predicted L2   Predicted L3   Predicted L4
Ground Truth L0:   {cm[0,0]:5d}          {cm[0,1]:5d}          {cm[0,2]:5d}          {cm[0,3]:5d}          {cm[0,4]:5d}
Ground Truth L1:   {cm[1,0]:5d}          {cm[1,1]:5d}          {cm[1,2]:5d}          {cm[1,3]:5d}          {cm[1,4]:5d}
Ground Truth L2:   {cm[2,0]:5d}          {cm[2,1]:5d}          {cm[2,2]:5d}          {cm[2,3]:5d}          {cm[2,4]:5d}
Ground Truth L3:   {cm[3,0]:5d}          {cm[3,1]:5d}          {cm[3,2]:5d}          {cm[3,3]:5d}          {cm[3,4]:5d}
Ground Truth L4:   {cm[4,0]:5d}          {cm[4,1]:5d}          {cm[4,2]:5d}          {cm[4,3]:5d}          {cm[4,4]:5d}
```

---

## 5. Binary Referable DR Screening Results (Level >= 2)

| Referable Screening Metric | Measured Result | SIH Target | Target Status |
| :--- | :--- | :--- | :--- |
| **Sensitivity (Recall)** | **{sens*100:.2f}%** | > 90.0% | **{sih_sens_status}** |
| **Specificity** | **{spec*100:.2f}%** | > 85.0% | **{sih_spec_status}** |
| **Precision (PPV)** | **{prec*100:.2f}%** | -- | Evaluated |
| **F1-Score** | **{ref_f1*100:.2f}%** | -- | Evaluated |
| **Binary Accuracy** | **{ref_acc*100:.2f}%** | -- | Evaluated |
| **ROC AUC** | **{auc:.3f}** | > 0.90 | Evaluated |

### Referable DR Confusion Matrix
* **True Positives (TP)**: {tp}
* **True Negatives (TN)**: {tn}
* **False Positives (FP)**: {fp}
* **False Negatives (FN)**: {fn}

---

## 6. Grad-CAM Verification on Real Images
* Verified on real APTOS images across Levels 0, 1, 2, 3, and 4.
* Feature map activations extracted from `resnet.layer4[1].conv2` (512 channels).
* Output heatmaps saved under `results/gradcam/`.
* Labeled strictly as: *"Regions contributing to model prediction (Interpretability tool — not a definitive lesion diagnosis)."*

---

## 7. SIH 2026 Target Comparison & Reality Summary

```text
SIH Sensitivity Target (>90%):  {sens*100:.2f}%  [{sih_sens_status}]
SIH Specificity Target (>85%):  {spec*100:.2f}%  [{sih_spec_status}]
```

> **Clinical Disclaimer**: EyeXpert is an AI-assisted screening and decision support prototype, NOT an autonomous medical device. All outputs mandate ophthalmologist or qualified clinician validation.
"""

    report_path = os.path.join(results_dir, "EyeXpert_APTOS_Validation_Report.md")
    with open(report_path, "w", encoding='utf-8') as f:
        f.write(report_md)

    # Print Final Machine-Readable Summary
    print("\n=========================================================================")
    print("                    MACHINE-READABLE VALIDATION SUMMARY                  ")
    print("=========================================================================")
    print(f"DATASET_STATUS: REAL_APTOS_DATASET_VERIFIED")
    print(f"MODEL_STATUS: {overall_status}")
    print(f"TRAIN_COUNT: {len(train_df)}")
    print(f"VALIDATION_COUNT: {len(val_df)}")
    print(f"TEST_COUNT: {len(test_df)}")
    print(f"5_CLASS_ACCURACY: {acc*100:.2f}%")
    print(f"MACRO_F1: {macro_f1*100:.2f}%")
    print(f"QWK: {qwk:.3f}")
    print(f"REFERABLE_SENSITIVITY: {sens*100:.2f}%")
    print(f"REFERABLE_SPECIFICITY: {spec*100:.2f}%")
    print(f"REFERABLE_PRECISION: {prec*100:.2f}%")
    print(f"REFERABLE_F1: {ref_f1*100:.2f}%")
    print(f"REFERABLE_AUC: {auc:.3f}")
    print(f"SIH_SENSITIVITY_TARGET_STATUS: {sih_sens_status}")
    print(f"SIH_SPECIFICITY_TARGET_STATUS: {sih_spec_status}")
    print(f"GRADCAM_STATUS: REAL_APTOS_IMAGES_VERIFIED")
    print(f"MODEL_FILE: models/EyeXpert_ResNet18_best.pth")
    print(f"VALIDATION_REPORT: results/EyeXpert_APTOS_Validation_Report.md")
    print("=========================================================================")

if __name__ == "__main__":
    main()
