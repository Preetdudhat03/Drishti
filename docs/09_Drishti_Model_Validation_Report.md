# Drishti (SIH 2026 PS-26038) — Model Validation & Evaluation Report

## 1. Executive Summary & Status

* **Model**: ResNet-18 Fine-Tuned (`models/EyeXpert_ResNet18_best.pth`)
* **Test Dataset**: 549 held-out APTOS 2019 images (Never seen during training/tuning)
* **5-Class Quadratic Weighted Kappa (QWK)**: **0.870** (Excellent clinical agreement)
* **Binary Referable DR Sensitivity**: **82.14%** (40 False Negatives / 224 Referable Cases)
* **Binary Referable DR Specificity**: **96.62%** (11 False Positives / 325 Non-Referable Cases)
* **Binary Referable DR ROC AUC**: **0.980**
* **Verification Status**: `REAL_APTOS_VALIDATED_BELOW_SIH_TARGET` (Transparently reported)

---

## 2. Five-Class Ordinal Severity Metrics (Held-Out Test Set)

| Metric | Measured Value | Medical / Clinical Interpretation |
| :--- | :---: | :--- |
| **Overall 5-Class Accuracy** | **76.87%** | Proportion of exact DR grade predictions across all 5 categories |
| **Quadratic Weighted Kappa (QWK)** | **0.870** | Inter-rater agreement standard penalizing distant classification errors |
| **Macro-Averaged Precision** | **60.91%** | Unweighted mean positive predictive value across classes |
| **Macro-Averaged Recall** | **62.85%** | Unweighted mean sensitivity across all classes |
| **Macro-Averaged F1-Score** | **60.85%** | Harmonic balance of precision and recall |

### Per-Class Detailed Performance Breakdown

| Clinical DR Grade | Test Support ($N$) | Precision | Recall | F1-Score | Clinical Finding Characteristics |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Level 0 (No DR)** | 270 | **98.8%** | **94.8%** | **96.8%** | Clean retina, intact macula, sharp optic disc |
| **Level 1 (Mild NPDR)** | 55 | **45.3%** | **78.2%** | **57.3%** | Microaneurysms only |
| **Level 2 (Moderate NPDR)**| 150 | **71.9%** | **61.3%** | **66.2%** | Dot/blot hemorrhages, hard exudates, cotton wool spots |
| **Level 3 (Severe NPDR)** | 29 | **32.1%** | **31.0%** | **31.6%** | 4-2-1 rule: severe hemorrhages in 4 quadrants |
| **Level 4 (Proliferative DR)**| 45 | **56.4%** | **48.9%** | **52.4%** | Neovascularization, vitreous/preretinal hemorrhage |

---

## 3. Five-Class Confusion Matrix (549 Test Samples)

```text
                     Predicted L0   Predicted L1   Predicted L2   Predicted L3   Predicted L4
Ground Truth L0 (270):    256            12              2              0              0
Ground Truth L1  (55):      3            43              9              0              0
Ground Truth L2 (150):      0            36             92             13              9
Ground Truth L3  (29):      0             0             12              9              8
Ground Truth L4  (45):      0             4             13              6             22
```

### Analysis of Off-Diagonal Errors:
* **Adjacent Class Confusion**: The vast majority of errors occur between adjacent severity levels (e.g., Level 2 vs Level 1 or Level 2 vs Level 3). In retinal clinical grading, even expert ophthalmologists exhibit inter-observer variance between Levels 1 and 2.
* **Extreme Class Preservation**: Zero Level 0 cases were classified as Level 3 or 4, and zero Level 3/4 cases were classified as Level 0.

---

## 4. Binary Referable DR Screening Metrics (Level >= 2)

In rural community screening, the primary triage decision is separating **Non-Referable** (Levels 0–1) from **Referable** (Levels 2–4):

| Referable Screening Metric | Measured Result | SIH Target | Target Status | Clinical Impact |
| :--- | :---: | :---: | :---: | :--- |
| **Sensitivity (Recall)** | **82.14%** | > 90.0% | **BELOW_TARGET** | Identifies 184 of 224 true positive referable cases |
| **Specificity** | **96.62%** | > 85.0% | **MET** | Correctly clears 314 of 325 healthy/mild patients |
| **Precision (PPV)** | **94.36%** | -- | Evaluated | 94.4% of flagged referable cases truly have DR |
| **Negative Predictive Value (NPV)**| **88.70%** | -- | Evaluated | High safety clearing routine annual follow-ups |
| **Binary F1-Score** | **87.83%** | -- | Evaluated | Harmonic mean of referable triage |
| **ROC AUC** | **0.980** | > 0.90 | **EXCEEDED** | Near-perfect discriminative capability |

### Binary Confusion Matrix:
* **True Positives (TP)**: 184 (Referable cases correctly flagged for doctor review)
* **True Negatives (TN)**: 314 (Non-referable cases cleared for routine annual check)
* **False Positives (FP)**: 11 (Non-referable cases sent for unnecessary doctor review)
* **False Negatives (FN)**: 40 (Referable cases missed by AI — mitigates by mandatory Human-in-the-Loop)
