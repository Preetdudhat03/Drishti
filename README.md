# EyeXpert — SIH 2026 (MVP V1)
## Explainable AI-Based Diabetic Retinopathy Screening & Clinical Decision Support Prototype

[![SIH 2026](https://img.shields.io/badge/SIH-2026-blue.svg)](https://sih.gov.in)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2022b%2B-orange.svg)](https://mathworks.com/products/matlab.html)
[![Safety First](https://img.shields.io/badge/Clinical%20Safety-Gated%20Triage-success.svg)]()

> [!IMPORTANT]
> **Clinical Safety & Medical Device Disclaimer**: EyeXpert is an AI-assisted screening and decision-support prototype, **NOT** an autonomous diagnostic medical device. It does not replace an ophthalmologist. All screening recommendations mandate qualified clinician review.

---

## 1. System Architecture

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
                    (ResNet-18 Transfer)
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

## 2. Directory Structure

```text
EyeXpert/
├── quality/               # Image Quality Assessment Module
│   ├── calculateSharpness.m      # Laplacian variance & focus metrics
│   ├── calculateIllumination.m   # Exposure, histogram & quadrant uniformity
│   ├── calculateFOV.m            # Retinal mask coverage & border truncation
│   ├── calculateQualityScore.m   # Weighted fusion & state decision
│   └── assessImageQuality.m      # Master quality gate & recapture feedback
│
├── preprocessing/         # Retinal Preprocessing & Adaptive Enhancement
│   ├── cropFundus.m              # Bounding box retinal disc isolation
│   ├── normalizeIllumination.m   # Graham's Gaussian background subtraction
│   ├── enhanceFundus.m           # Adaptive CLAHE in Lab space
│   └── preprocessFundus.m        # Standardized resizing & normalization
│
├── classification/        # DR Inference & Referable Decision Engine
│   ├── determineReferableDR.m    # Clinical mapping (Level >= 2 -> Referable)
│   ├── calculateConfidence.m     # Temperature-scaled calibrated confidence
│   └── classifyDR.m              # End-to-end inference gatekeeper
│
├── explainability/        # Explainable AI & Evidence Modules
│   ├── generateGradCAM.m         # Deep convolutional activation mapping
│   └── createEvidenceOverlay.m   # Alpha blending & candidate region bounding
│
├── cv_analysis/           # Computer Vision Exploratory Modules
│   ├── extractVessels.m          # Morphological retinal vessel enhancement
│   └── locateOpticDisc.m         # Candidate optic disc localization
│
├── model/                 # Model Architecture, Training & Preparation
│   ├── prepareDataset.m          # Stratified 70/15/15 split generator
│   ├── trainDRModel.m            # Transfer learning with class-weighted loss
│   ├── evaluateDRModel.m         # Held-out test evaluation suite
│   └── loadDRModel.m             # Model loader & architecture validator
│
├── reporting/             # Clinical Screening Report Generation & Export
│   ├── generateScreeningReport.m # Structured clinical decision report
│   └── exportReport.m            # Export to TXT and HTML format
│
├── validation/            # Performance Metrics & Visualizations
│   ├── calculateMetrics.m        # 5-class confusion matrix, Macro-F1, QWK
│   ├── evaluateReferableDR.m     # Sensitivity, Specificity, Precision, ROC/AUC
│   ├── plotConfusionMatrix.m     # High-resolution matrix plot
│   └── plotROC.m                 # ROC curve plot with AUC
│
├── simulink/              # District-Scale Telemedicine Simulation
│   ├── runDistrictSimulation.m   # Discrete-event telemedicine queuing engine
│   ├── compareScenarios.m        # Baseline (Manual) vs EyeXpert (AI-Triaged)
│   └── createDistrictModel.m     # Programmatic Simulink block diagram generator
│
├── app/                   # MATLAB App Designer GUI Application
│   ├── EyeXpertApp.m             # Reactive App Designer interface class
│   └── launchEyeXpert.m          # Desktop application launcher
│
├── data/                  # Dataset utilities & benchmark images
│   ├── auditDataset.m            # APTOS integrity & class balance auditor
│   ├── auditExternalDataset.m    # Friend's dataset leakage/compatibility auditor
│   ├── generateSampleFundusData.m# Deterministic benchmark image generator
│   └── sample_demo/              # Self-contained test fundus images
│
├── tests/                 # Comprehensive Automated Test Suite
│   ├── test_quality_assessment.m
│   ├── test_preprocessing.m
│   ├── test_classification_pipeline.m
│   ├── test_explainability.m
│   ├── test_end_to_end_screening.m
│   └── runAllEyeXpertTests.m
│
├── main_demo.m            # Complete CLI / Script Demonstration
└── README.md
```

---

## 3. Quick Start Guide

### Launching the Graphical User Interface
In MATLAB Command Window:
```matlab
launchEyeXpert
```

### Running the End-to-End CLI Demo
```matlab
main_demo
```

### Running the Automated Test Suite
```matlab
runAllEyeXpertTests
```

### Auditing a Dataset (e.g. APTOS)
```matlab
auditReport = auditDataset('path/to/aptos/images', 'path/to/train.csv');
```

### Performing Stratified 70/15/15 Split
```matlab
splitData = prepareDataset('path/to/aptos/images', 'path/to/train.csv');
```

---

## 4. Key Clinical & Technical Features

### 1. Image Quality Gate
- **Laplacian Focus Metric**: Rejects out-of-focus and motion-blurred captures.
- **Illumination Uniformity**: Identifies extreme underexposure ($I < 25$) and overexposure ($I > 240$).
- **Retinal FOV**: Checks circular disc coverage and boundary truncation.
- **Actionable Recapture Feedback**: Provides clear instructions (e.g., *"Adjust flash intensity"*, *"Stabilize camera focus"*).

### 2. Explainable AI (Grad-CAM)
- Displays visual attention heatmaps over the preprocessed fundus image.
- Strictly labeled as: *"Regions contributing to model prediction (Interpretability tool — not a definitive lesion diagnosis)"*.

### 3. Human-in-the-Loop Review
- State-driven review buttons: `[ Validate Result ]`, `[ Override Result ]`, `[ Mark Ungradable ]`.
- Logs timestamped clinician notes and audit trails.

### 4. District-Scale Telemedicine Simulation
- Evaluates operational feasibility for **120,000 patients/year**.
- Demonstrates how EyeXpert AI-assisted triage eliminates doctor backlogs and reduces turnaround time from **hours/days** to **minutes**.

---

## 5. Team Engineering Principles
1. **Safety before accuracy claims**.
2. **Reject ungradable images rather than forcing predictions**.
3. **No fabricated validation or clinical evidence**.
4. **Explainability before black-box deployment**.
5. **Zero data leakage between train/val/test splits**.
6. **Ophthalmologist-in-the-loop for all screening outcomes**.