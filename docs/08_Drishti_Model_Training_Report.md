# Drishti (SIH 2026 PS-26038) — Deep Learning Model Training Report

## 1. Training Environment & Artifact Manifest

* **Training Script**: `train_aptos_real.py` / `model/train_pytorch_resnet.py`
* **Dataset**: APTOS 2019 Blindness Detection (Held in `data/aptos/`)
* **Total Labeled Samples**: 3,662 retinal fundus images
* **Model Checkpoint**: `models/EyeXpert_ResNet18_best.pth` (134.2 MB full model / 44.8 MB state dict)
* **MATLAB Deep Learning Import**: `model/drModel.mat` (44.7 MB imported DAGNetwork)
* **Random Seed**: `42` (Deterministic partition and initialization)

---

## 2. Dataset Partitioning (Strict Zero-Data-Leakage)

The dataset was split using stratified random sampling across all 5 clinical DR severity levels:

| Split Partition | Ratio | Sample Count | Percentage | Role in Training Pipeline |
| :--- | :---: | :---: | :---: | :--- |
| **Training Set** | 70% | 2,563 | 70.0% | Model parameter gradient optimization |
| **Validation Set** | 15% | 550 | 15.0% | Early stopping & best checkpoint selection on QWK |
| **Held-Out Test Set** | 15% | 549 | 15.0% | Final unbiased clinical metric evaluation |
| **Total** | 100% | 3,662 | 100.0% | Complete verified dataset |

Manifests are saved in: `splits/train.csv`, `splits/validation.csv`, and `splits/test.csv`.

---

## 3. Class Imbalance & Loss Weighting

Retinal disease distribution in real-world clinical datasets is heavily skewed towards healthy eyes (Level 0). To prevent model collapse towards majority classes, **Inverse Class Frequency Weighting** was applied:

$$\\text{Weight}_c = \\frac{N_{\\text{total}}}{5 \\times N_c}$$

Normalized weights applied to `nn.CrossEntropyLoss`:
* **Level 0 (No DR)**: $n = 1,263$ -> **Weight = 0.406**
* **Level 1 (Mild NPDR)**: $n = 259$ -> **Weight = 1.979**
* **Level 2 (Moderate NPDR)**: $n = 699$ -> **Weight = 0.733**
* **Level 3 (Severe NPDR)**: $n = 135$ -> **Weight = 3.797**
* **Level 4 (Proliferative DR)**: $n = 207$ -> **Weight = 2.476**

---

## 4. Hyperparameters & Optimization Strategy

| Parameter | Configuration | Engineering Justification |
| :--- | :--- | :--- |
| **Architecture** | ResNet-18 (Transfer Learning) | Pretrained on ImageNet-1k; fast inference on CPU/mobile edge devices |
| **Input Resolution** | 224 x 224 x 3 (RGB) | Standard convolutional receptor field; optimal balance of spatial detail and memory |
| **Optimizer** | AdamW | Decoupled weight decay prevents overfitting on limited medical samples |
| **Learning Rate** | 1e-4 | Initial backbone learning rate |
| **Weight Decay** | 1e-2 ($L_2$ Regularization) | Penalizes large network weights |
| **LR Scheduler** | `ReduceLROnPlateau(mode='max', factor=0.5, patience=2)` | Dynamically halves learning rate when validation QWK plateaus |
| **Data Augmentation** | RandomHorizontalFlip ($p=0.5$), RandomRotation ($\\pm 15^\\circ$), ColorJitter ($0.1$) | Simulates patient eye orientation and camera illumination differences |
| **Preprocessing** | Auto-cropping black borders + ImageNet Normalization | $\\mu = [0.485, 0.456, 0.406]$, $\\sigma = [0.229, 0.224, 0.225]$ |
| **Best Model Criterion**| Validation Quadratic Weighted Kappa (QWK) | Reflects ordinal clinical penalty between disease severity grades |
