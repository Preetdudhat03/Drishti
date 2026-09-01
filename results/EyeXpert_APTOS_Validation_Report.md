# Drishti (EyeXpert) — Real APTOS 2019 Validation Report

**Dataset**: APTOS 2019 Blindness Detection (Kaggle)  
**Evaluation Timestamp**: 2026-09-01 20:20:18  
**Model Architecture**: ResNet-18 Transfer Learning  
**Final Status**: `REAL_APTOS_VALIDATED_SIH_TARGETS_MET`

---

## 1. Dataset & Audit
* **Total Labeled Records**: 3662
* **Valid Images on Disk**: 3662
* **Missing Images**: 0
* **Class Distribution (Full Dataset)**:
  * Level 0 (No DR): 1805 (49.3%) [Non-Referable]
  * Level 1 (Mild NPDR): 370 (10.1%) [Non-Referable]
  * Level 2 (Moderate NPDR): 999 (27.3%) [Referable]
  * Level 3 (Severe NPDR): 193 (5.3%) [Referable]
  * Level 4 (Proliferative DR): 295 (8.1%) [Referable]

---

## 2. Train / Validation / Test Split (Zero Data Leakage)
* **Training Set (70%)**: 2563 samples
* **Validation Set (15%)**: 550 samples (Used for model checkpoint selection)
* **Held-Out Test Set (15%)**: 549 samples (Evaluated exactly once)
* **Random Seed**: 42 (Deterministic stratification)

---

## 3. Five-Class Results (Held-Out Test Split)

| Metric | Measured Value | Description |
| :--- | :--- | :--- |
| **5-Class Accuracy** | **76.87%** | Top-1 multiclass accuracy |
| **Macro-Precision** | **60.91%** | Unweighted mean precision |
| **Macro-Recall** | **62.85%** | Unweighted mean recall |
| **Macro-F1 Score** | **60.85%** | Harmonic mean of precision/recall |
| **Quadratic Weighted Kappa (QWK)** | **0.870** | Inter-rater agreement standard in DR |

### Per-Class Performance
* **Level 0 (No DR)**: Precision = 98.8%, Recall = 94.8%, F1 = 96.8%
* **Level 1 (Mild NPDR)**: Precision = 45.3%, Recall = 78.2%, F1 = 57.3%
* **Level 2 (Moderate NPDR)**: Precision = 71.9%, Recall = 61.3%, F1 = 66.2%
* **Level 3 (Severe NPDR)**: Precision = 32.1%, Recall = 31.0%, F1 = 31.6%
* **Level 4 (Proliferative DR)**: Precision = 56.4%, Recall = 48.9%, F1 = 52.4%

### 5-Class Confusion Matrix
```text
               Predicted L0   Predicted L1   Predicted L2   Predicted L3   Predicted L4
Ground Truth L0:     256             12              2              0              0
Ground Truth L1:       3             43              9              0              0
Ground Truth L2:       0             36             92             13              9
Ground Truth L3:       0              0             12              9              8
Ground Truth L4:       0              4             13              6             22
```

---

## 4. Binary Referable DR Screening Results (Level >= 2)

### (A) Calibrated High-Sensitivity Screening Gate (tau = 0.30) — DEPLOYED

| Calibrated Metric (tau = 0.30) | Measured Result | SIH Target | Target Status |
| :--- | :--- | :--- | :--- |
| **Sensitivity (Recall)** | **91.07%** | > 90.0% | **MET (MET)** |
| **Specificity** | **94.77%** | > 85.0% | **MET (MET)** |
| **Precision (PPV)** | **92.31%** | -- | Evaluated |
| **F1-Score** | **91.69%** | -- | Evaluated |
| **Binary Accuracy** | **93.26%** | -- | Evaluated |
| **ROC AUC** | **0.980** | > 0.90 | **EXCEEDED** |

* **True Positives (TP)**: 204 (Referable patients correctly flagged)
* **True Negatives (TN)**: 308 (Healthy/Mild patients correctly cleared)
* **False Positives (FP)**: 17
* **False Negatives (FN)**: 20 *(Reduced from 40 down to 20)*

### (B) Raw Argmax Benchmark (tau = 0.50 equivalent)

| Raw Argmax Metric | Measured Result | SIH Target | Target Status |
| :--- | :--- | :--- | :--- |
| **Sensitivity (Recall)** | **82.14%** | > 90.0% | **BELOW_TARGET** |
| **Specificity** | **96.62%** | > 85.0% | **MET** |
| **Binary Accuracy** | **90.71%** | -- | Evaluated |

---

## 5. SIH Target Verification Summary
```text
Calibrated Sensitivity (tau=0.30):  91.07%  [MET - Target >90%]
Calibrated Specificity (tau=0.30):  94.77%  [MET - Target >85%]
ROC-AUC:                            0.980   [EXCEEDED - Target >0.90]
```

> **Clinical Safety Notice**: Drishti is an AI-assisted screening and decision support system. All outputs provide clinical decision support and mandate qualified ophthalmologist review.
