# EyeXpert — SIH 2026 (Real APTOS 2019 Validated)
## Explainable AI-Based Diabetic Retinopathy Screening & Clinical Decision Support Prototype

[![SIH 2026](https://img.shields.io/badge/SIH-2026-blue.svg)](https://sih.gov.in)
[![APTOS 2019](https://img.shields.io/badge/Dataset-APTOS%202019%20Validated-success.svg)]()
[![Model](https://img.shields.io/badge/Model-ResNet--18%20Transfer%20Learning-blue.svg)]()
[![Status](https://img.shields.io/badge/Status-REAL__APTOS__VALIDATED-brightgreen.svg)]()

> [!IMPORTANT]
> **Clinical Safety & Medical Device Disclaimer**: EyeXpert is an AI-assisted screening and decision-support prototype, **NOT** an autonomous diagnostic medical device. It does not replace an ophthalmologist. All screening recommendations mandate qualified clinician review.

---

## 1. Verified Held-Out Test Results (APTOS 2019 Dataset)

The model was fine-tuned on the real **APTOS 2019 Blindness Detection dataset** (3,662 retinal images) using a stratified 70/15/15 split (Train: 2,563, Val: 550, Held-Out Test: 549) with inverse-frequency class weighting.

### Primary Multiclass Results (5-Class DR)

| Metric | Measured Value | Description |
| :--- | :--- | :--- |
| **5-Class Top-1 Accuracy** | **76.87%** | Exact multiclass prediction accuracy |
| **Macro-Precision** | **63.50%** | Unweighted mean precision across all 5 classes |
| **Macro-Recall** | **60.10%** | Unweighted mean recall across all 5 classes |
| **Macro-F1 Score** | **60.85%** | Harmonic mean of macro precision/recall |
| **Quadratic Weighted Kappa (QWK)** | **0.870** | Inter-rater agreement standard for ordinal DR |

---

### Binary Referable DR Screening Results (Level $\ge$ 2)

| Referable Screening Metric | Measured Result | SIH Target | Status |
| :--- | :--- | :--- | :--- |
| **Sensitivity (Recall)** | **82.14%** | > 90.0% | *Observed baseline at default threshold* |
| **Specificity** | **96.62%** | > 85.0% | **MET (Exceeds Target)** |
| **Precision (PPV)** | **94.36%** | -- | Evaluated |
| **F1-Score** | **87.83%** | -- | Evaluated |
| **ROC AUC** | **0.980** | > 0.90 | **High Discriminatory Capacity** |

---

## 2. Real Grad-CAM Explainability Verification

Grad-CAM was extracted directly from the deepest convolutional layer of the trained ResNet-18 model (`layer4[1].conv2`, 512 channels) on real patient fundus images across Levels 0, 1, 2, 3, and 4.
All verification heatmaps are stored in:
`results/gradcam/real_aptos_gradcam_level_*.png`

Strict interpretability tag:
> *"Regions contributing to the model prediction (Interpretability tool — not a definitive lesion diagnosis)."*

---

## 3. System Architecture & Screening Workflow

```text
                               EYEXPERT
                                  │
                                  ▼
                          FUNDUS PHOTOGRAPH
                                  │
                                  ▼
                        IMAGE QUALITY ENGINE
             (Laplacian Blur, Exposure, Retinal FOV)
                                  │
                       ┌──────────┼──────────┐
                       ▼          ▼          ▼
                     GOOD     BORDERLINE   UNGRADABLE
                       │          │          │
                       │       ENHANCE       │
                       │       (CLAHE)       │
                       │          │          ▼
                       └────┬─────┘      RECAPTURE
                            │            FEEDBACK
                            ▼
                  RETINAL PREPROCESSING
                  (Auto-Crop, 224x224x3)
                            │
                            ▼
                    DR CLASSIFICATION
               (Trained ResNet-18 Backbone)
                            │
                       LEVEL 0 – 4
                            │
                            ▼
                   REFERABLE DR ENGINE
                  (Level >= 2 -> REFER)
                            │
                      EXPLAINABILITY
                    ┌───────┼────────┐
                    ▼       ▼        ▼
                 Grad-CAM Evidence Softmax
                 Heatmap  Overlay  Probs
                    └───────┼────────┘
                            ▼
                     SCREENING REPORT
                  (Formatted Text & HTML)
                            │
                            ▼
                     HUMAN VALIDATION
                (Validate / Override / Reject)
                            │
                            ▼
                  DISTRICT SCALE SIMULATION
                (120,000 pts/yr Telemedicine)
```

---

## 4. How to Run

### Interactive Web Application (Live in Browser)
1. Double-click [`run_web_app.bat`](file:///p:/pro/EyeXpert/run_web_app.bat) (or run `python web_app.py`).
2. Open `http://localhost:5000` in Google Chrome / Edge.
3. Upload any fundus image or pick benchmark test cases to view live ResNet-18 predictions, Grad-CAM overlays, and generate clinical screening reports.

### MATLAB Desktop / MATLAB Online
1. In MATLAB Command Window:
   ```matlab
   cd EyeXpert
   addpath(genpath(pwd))
   launchEyeXpert
   ```
2. Run unit & integration tests:
   ```matlab
   runAllEyeXpertTests
   ```
3. Run district telemedicine simulation:
   ```matlab
   compareScenarios
   ```