# Drishti AI: Full Held-Out Test Set Evaluation Report
**Dataset**: APTOS 2019 Blind Held-Out Split  
**Total Test Samples**: 549  
**Model Architecture**: PyTorch ResNet-18 with Transfer Learning  
**Canonical Preprocessing**: `fundus-v1` (Retinal Bounding-Box Background Crop $\rightarrow$ $224 \times 224$ Bilinear $\rightarrow$ ImageNet Normalization)  
**Evaluation Date**: 2026-09-13 05:30:21 UTC

---

## 1. Multi-Class Classification Performance (5-Class)

| Metric | Score | Clinical Standard Target |
| :--- | :---: | :---: |
| **Quadratic Weighted Kappa (QWK)** | **0.8663** | $\ge 0.80$ (Substantial Agreement) |
| **Overall Accuracy** | **77.05%** | $\ge 75\%$ |
| **Macro Precision** | **61.47%** | Balanced across classes |
| **Macro Recall** | **63.60%** | Balanced across classes |
| **Macro F1-Score** | **61.60%** | Robust to class imbalance |

### 5x5 Confusion Matrix
```
               Predicted Level
           0      1      2      3      4
True 0:   255     12      3      0      0
True 1:     3     43      9      0      0
True 2:     0     34     93     12     11
True 3:     0      0     12     10      7
True 4:     0      4     13      6     22
```

### Per-Class Detailed Breakdown
| DR Level & Severity | Test Support (n) | Precision | Recall (Sensitivity) | F1-Score |
| :--- | :---: | :---: | :---: | :---: |
| **Level 0 — No DR** | 270 | 98.84% | 94.44% | 96.59% |
| **Level 1 — Mild NPDR** | 55 | 46.24% | 78.18% | 58.11% |
| **Level 2 — Moderate NPDR** | 150 | 71.54% | 62.00% | 66.43% |
| **Level 3 — Severe NPDR** | 29 | 35.71% | 34.48% | 35.09% |
| **Level 4 — Proliferative DR** | 45 | 55.00% | 48.89% | 51.76% |

---

## 2. Binary Referable DR Performance (DR $\ge$ 2)

Tele-ophthalmology screening safety hinges on distinguishing **Non-Referable** (Levels 0, 1) from **Referable** (Levels 2, 3, 4) cases requiring ophthalmologist evaluation.

| Screening Metric | Standard Threshold ($\tau = 0.50$) | Calibrated Screening Threshold ($\tau = 0.31$) | Clinical Guideline |
| :--- | :---: | :---: | :---: |
| **ROC-AUC** | **0.9808** | **0.9808** | $\ge 0.90$ (High Discriminative Power) |
| **Sensitivity (Recall)** | **83.93%** | **90.62%** | $\ge 85\%$ (Prevents Missed Pathologies) |
| **Specificity** | **96.92%** | **95.38%** | $\ge 80\%$ (Prevents Over-Referral) |
| **Binary Accuracy** | **91.62%** | **93.44%** | $\ge 85\%$ |
| **Precision (PPV)** | **94.95%** | — | — |

---

## 3. Scientific Terminology Adherence

In accordance with clinical trial and medical device standards:
1. **Ground Truth Label**: The human-verified grading from the APTOS 2019 expert multi-reader consensus.
2. **AI Preliminary Assessment**: The automated ResNet-18 statistical inference (logits, class probabilities, referable triage).
3. **Ophthalmologist Final Clinical Assessment**: The authoritative human-in-the-loop medical diagnosis recorded by the registered clinician after reviewing fundus photography and Grad-CAM neural attention overlays.
