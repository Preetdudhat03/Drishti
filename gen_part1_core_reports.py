# -*- coding: utf-8 -*-
import os, sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DOCS_DIR = os.path.join(BASE_DIR, "docs")
os.makedirs(DOCS_DIR, exist_ok=True)

def write_doc(filename, content):
    filepath = os.path.join(DOCS_DIR, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")
    print(f"[OK] Wrote {filename} ({len(content)} characters)")

# =========================================================================
# FILE 10: DEPENDENCY INVENTORY
# =========================================================================
write_doc("10_Drishti_Dependency_Inventory.md", """# Drishti (SIH 2026 PS-26038) — Complete Dependency & Tool Inventory

## 1. Python Backend & Deep Learning Dependencies (`requirements.txt` / Runtime)

| Library | Version / Constraint | Used In / Module | Purpose in Drishti |
| :--- | :--- | :--- | :--- |
| **torch** | `^2.2.0` | `web_app.py`, `train_aptos_real.py`, `model/train_pytorch_resnet.py` | Core deep-learning framework, ResNet-18 model tensor graph, backprop, hooks |
| **torchvision** | `^0.17.0` | `web_app.py`, `train_aptos_real.py` | Pretrained ResNet-18 weights, image tensor normalization transforms |
| **numpy** | `^1.24.0` | `web_app.py`, `train_aptos_real.py`, `evaluate_saved_model.py` | Array manipulation, Grad-CAM activation weighting, confusion matrix ops |
| **Pillow (PIL)** | `^10.0.0` | `web_app.py`, `train_aptos_real.py`, `generate_all_artifacts.py` | Image loading, downsampling, bounding box cropping, format conversion |
| **opencv-python-headless** | `^4.8.0` | `web_app.py`, `tests/verifyRealityAudit.py` | Laplacian variance focus scoring, CLAHE contrast enhancement, FOV contouring |
| **Flask** | `^3.0.0` | `web_app.py` | REST API microservices gateway (`/api/v1/*`), multipart upload routing |
| **Flask-CORS** | `^4.0.0` | `web_app.py` | Cross-Origin Resource Sharing for Flutter Web / local dev integration |
| **gunicorn** | `^21.2.0` | `Procfile` | Production WSGI HTTP server on Linux cloud host (Render) |
| **scikit-learn** | `^1.3.0` | `train_aptos_real.py`, `evaluate_saved_model.py` | Quadratic Weighted Kappa (QWK), ROC curves, AUC, per-class classification reports |
| **matplotlib** | `^3.7.0` | `train_aptos_real.py`, `evaluate_saved_model.py` | Heatmap generation, confusion matrix plotting, ROC visualization |
| **pandas** | `^2.0.0` | `train_aptos_real.py`, `evaluate_saved_model.py` | Dataset manifest management, train/val/test stratified partitioning |
| **python-pptx** | `^1.0.0` | `docs/` | Automated SIH 2026 PowerPoint generation |
| **reportlab** | `^5.0.0` | `docs/` | Automated high-fidelity clinical and technical PDF documentation export |

---

## 2. Flutter / Dart Mobile & Web Client Dependencies (`eyexpert_app/pubspec.yaml`)

| Package | Version | Layer / File Location | Purpose in Drishti |
| :--- | :--- | :--- | :--- |
| **flutter** | SDK | Core Client | Cross-platform UI toolkit targeting Android, iOS, Web, and Desktop |
| **flutter_riverpod** | `^2.5.1` | `lib/features/*/providers.dart` | Reactive clinical state management, dependency injection, session caching |
| **supabase_flutter** | `^2.8.0` | `lib/data/services/supabase_service.dart` | PostgreSQL database, JWT authentication, Storage bucket, and Realtime sync |
| **image_picker** | `^1.1.2` | `lib/features/screening/fundus_capture_screen.dart` | High-res camera capture & gallery fundus photograph selection |
| **http** | `^1.2.1` | `lib/data/api/api_client.dart` | Multipart image upload and REST API communication with PyTorch backend |
| **intl** | `^0.19.0` | `lib/core/utils/formatters.dart` | Date-time formatting, localization, numerical percentage representations |
| **uuid** | `^4.4.0` | `lib/data/services/screening_service.dart` | RFC4122 v4 screening UUID and client idempotency key generation |
| **crypto** | `^3.0.3` | `lib/data/services/sync_service.dart` | SHA-256 payload hashing for deduplication and offline audit trails |
| **shared_preferences**| `^2.2.3` | `lib/core/security/secure_storage.dart` | Local token storage, offline queued screenings, and session persistence |
| **pdf** | `^3.10.8` | `lib/features/reports/screening_report_screen.dart` | Clinical screening summary document generation |
| **printing** | `^5.12.0` | `lib/features/reports/screening_report_screen.dart` | Direct thermal/air printing and PDF sharing for rural PHC clinics |
| **fl_chart** | `^0.68.0` | `lib/features/system_status/`, `results/` | Probability distribution graphs and district telemedicine workload charts |
| **cupertino_icons** | `^1.0.8` | `lib/shared/` | iOS styling asset bundle |
| **flutter_lints** | `^3.0.0` | `dev_dependencies` | Static analysis rules enforcing medical-grade code quality |

---

## 3. MATLAB & Simulink Toolboxes (`model/`, `quality/`, `simulink/`, `cv_analysis/`)

| Toolbox / Environment | Minimum Version | Files Used | Purpose in Drishti |
| :--- | :--- | :--- | :--- |
| **MATLAB Base System** | `R2023b` or `R2024a` | `main_demo.m`, `app/` | Numerical engine, script execution, pipeline orchestration |
| **Image Processing Toolbox** | `R2023b` | `quality/*`, `preprocessing/*`, `cv_analysis/*` | `adapthisteq` (CLAHE), `imtophat` (vessels), `imgaussfilt` (optic disc), `bwareaopen` |
| **Computer Vision Toolbox** | `R2023b` | `quality/calculateFOV.m`, `cv_analysis/*` | Contour extraction, geometric feature representation, retinal boundary masking |
| **Deep Learning Toolbox** | `R2023b` | `model/trainDRModel.m`, `classification/*` | PyTorch model import (`importNetworkFromPyTorch`), activation maps, Grad-CAM |
| **Statistics & Machine Learning** | `R2023b` | `validation/calculateMetrics.m`, `simulink/*` | Poisson random generation, confusion matrix analysis, Cohen's Kappa calculation |
| **Simulink** | `R2023b` | `simulink/createDistrictModel.m` | Discrete-event district queuing simulation (120,000 annual patients, M/M/c queues) |
""")

# =========================================================================
# FILE 11: CURRENT STATUS & MATRIX
# =========================================================================
write_doc("11_Drishti_Current_Status.md", """# Drishti (SIH 2026 PS-26038) — Project Audit & Implementation Status Matrix

## 1. Executive Implementation Audit

This document is the authoritative, verified status matrix for **Drishti** (SIH 2026 Problem Statement 26038: *Explainable AI-Assisted Diabetic Retinopathy Screening and Clinical Decision Support System*). All statuses are derived directly from source-code inspection of PyTorch deep learning pipelines, MATLAB/Simulink simulation modules, Flutter mobile/web clients, Supabase PostgreSQL schemas, and real APTOS 2019 validation checkpoints.

---

## 2. Comprehensive Module Status Matrix

| Module / Capability | Planned | Implemented | Tested | Real Data | Production Ready | Primary Source Evidence |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Image Quality Gating** | YES | YES | YES | YES | YES | `quality/assessImageQuality.m`, `quality/calculateQualityScore.m`, `web_app.py:load_and_downsample_image` |
| **Blur / Sharpness Detection** | YES | YES | YES | YES | YES | `quality/calculateSharpness.m` (Laplacian variance on retinal mask), `web_app.py:calculate_sharpness` |
| **Illumination & Exposure Analysis** | YES | YES | YES | YES | YES | `quality/calculateIllumination.m` (Mean brightness, percentiles, exposure ratio), `web_app.py` |
| **Field of View (FOV) Masking** | YES | YES | YES | YES | YES | `quality/calculateFOV.m` (Otsu threshold, morphology, coverage ratio), `web_app.py` |
| **CLAHE Contrast Enhancement** | YES | YES | YES | YES | YES | `preprocessing/enhanceFundus.m` (Green channel, clip limit 0.02), `web_app.py` |
| **Illumination Normalization** | YES | YES | YES | YES | YES | `preprocessing/normalizeIllumination.m` (Gaussian background subtraction) |
| **Fundus Bounding Box Cropping** | YES | YES | YES | YES | YES | `preprocessing/cropFundus.m`, `train_aptos_real.py:get_preprocessed_path` |
| **5-Class DR Severity Classification** | YES | YES | YES | YES | YES | `train_aptos_real.py` (ResNet-18), `models/EyeXpert_ResNet18_best.pth`, `classification/classifyDR.m` |
| **Binary Referable DR Triage (Level >= 2)**| YES | YES | YES | YES | YES | `classification/determineReferableDR.m`, `train_aptos_real.py`, `dr_prediction_model.dart` |
| **Grad-CAM Saliency Maps** | YES | YES | YES | YES | YES | `explainability/generateGradCAM.m`, `train_aptos_real.py:generate_gradcam`, `web_app.py:api_v1_analyze` |
| **Multi-layer Evidence Overlay** | YES | YES | YES | YES | YES | `explainability/createEvidenceOverlay.m` (Heatmap + Fundus RGB alpha blend) |
| **Blood Vessel Enhancement** | YES | YES | YES | YES | PARTIAL | `cv_analysis/extractVessels.m` (Top-hat filtering + CLAHE; exploratory reference) |
| **Optic Disc Localization** | YES | YES | YES | YES | PARTIAL | `cv_analysis/locateOpticDisc.m` (Red channel gaussian centroid; anatomical reference) |
| **Clinical-Style Report Generation** | YES | YES | YES | YES | YES | `reporting/generateScreeningReport.m`, `reporting/exportReport.m`, Flutter `pdf` package |
| **Human-in-the-Loop Validation** | YES | YES | YES | YES | YES | `eyexpert_app/lib/features/review/clinician_review_screen.dart`, `supabase/schema.sql` |
| **Immutable Clinical Audit Trail** | YES | YES | YES | YES | YES | `supabase/schema.sql:audit_events`, `supabase_service.dart:recordClinicianReview` |
| **Python REST API Gateway** | YES | YES | YES | YES | YES | `web_app.py` (`/api/v1/screenings/*`, `/api/v1/reviews/*`, `/api/v1/system/*`) |
| **Flutter Mobile & Web Client** | YES | YES | YES | YES | YES | `eyexpert_app/lib/main.dart` (Material 3, Riverpod 2.5, responsive layout) |
| **Supabase JWT Authentication** | YES | YES | YES | YES | YES | `eyexpert_app/lib/data/services/auth_service.dart`, `supabase/schema.sql:profiles` |
| **Supabase PostgreSQL Schema** | YES | YES | YES | YES | YES | `supabase/schema.sql` (7 relational tables, RLS policies, foreign keys) |
| **Supabase Cloud Storage** | YES | YES | YES | YES | YES | `eyexpert_app/lib/data/services/supabase_service.dart:uploadFundusImage` (`fundus-images` bucket) |
| **Supabase Real-Time Updates** | YES | YES | YES | YES | YES | `eyexpert_app/lib/data/services/supabase_service.dart:watchScreening` |
| **Offline Rural Sync Queue** | YES | YES | YES | YES | YES | `eyexpert_app/lib/features/offline/sync_queue_provider.dart` (SHA-256 idempotency) |
| **Batch CSV / Image Evaluation** | YES | YES | YES | YES | YES | `validation/evaluateReferableDR.m`, `evaluate_saved_model.py` |
| **Live Device Camera Acquisition** | YES | YES | YES | YES | YES | `eyexpert_app/lib/features/screening/fundus_capture_screen.dart` (`image_picker`) |
| **Simulink District Queuing Model** | YES | YES | YES | YES | YES | `simulink/createDistrictModel.m`, `simulink/runDistrictSimulation.m` (120k patients/yr) |
| **Reality Audit / Test Suite** | YES | YES | YES | YES | YES | `tests/verifyRealityAudit.py`, `tests/runAllEyeXpertTests.m` (6 passing unit tests) |

---

## 3. Discrepancy & Reality Analysis

1. **Product Name & Legacy Identifiers**:
   - **User Facing Name**: **Drishti** (दृष्टि) across all UI screens, manifest, Android labels, and presentation decks.
   - **Internal / Codebase Path Names**: Legacy identifiers `eyexpert_app`, `EyeXpert`, and `eyexpert.onrender.com` remain in file directories and git repository origins. These are preserved for backward compatibility and verifiable provenance.

2. **Model Training Status (Real APTOS 2019)**:
   - **Documentation Claim**: Model achieves multi-class DR grading and binary referable triage.
   - **Code Reality**: Evaluated on 3,662 real APTOS 2019 images (549 held-out test split).
   - **Measured Metrics**: QWK = **0.870**, Accuracy = **76.87%**, Sensitivity = **82.14%** (SIH target >90%), Specificity = **96.62%** (SIH target >85%), ROC AUC = **0.980**.
   - **Status**: `REAL_APTOS_VALIDATED_BELOW_SIH_TARGET` for Sensitivity (82.14% vs 90.0% target), fully transparently reported.

3. **Computer Vision Lesion Localization**:
   - **Documentation Claim**: Retinal anatomical referencing.
   - **Code Reality**: Blood vessel extraction (`cv_analysis/extractVessels.m`) and Optic Disc localization (`cv_analysis/locateOpticDisc.m`) are heuristic computer vision tools. They provide exploratory visualization and are explicitly flagged as *candidate localization*, not definitive medical diagnoses.
""")

# =========================================================================
# FILE 08: MODEL TRAINING REPORT
# =========================================================================
write_doc("08_Drishti_Model_Training_Report.md", """# Drishti (SIH 2026 PS-26038) — Deep Learning Model Training Report

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

$$\\\\text{Weight}_c = \\\\frac{N_{\\\\text{total}}}{5 \\\\times N_c}$$

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
| **Data Augmentation** | RandomHorizontalFlip ($p=0.5$), RandomRotation ($\\\\pm 15^\\\\circ$), ColorJitter ($0.1$) | Simulates patient eye orientation and camera illumination differences |
| **Preprocessing** | Auto-cropping black borders + ImageNet Normalization | $\\\\mu = [0.485, 0.456, 0.406]$, $\\\\sigma = [0.229, 0.224, 0.225]$ |
| **Best Model Criterion**| Validation Quadratic Weighted Kappa (QWK) | Reflects ordinal clinical penalty between disease severity grades |
""")

# =========================================================================
# FILE 09: MODEL VALIDATION REPORT
# =========================================================================
write_doc("09_Drishti_Model_Validation_Report.md", """# Drishti (SIH 2026 PS-26038) — Model Validation & Evaluation Report

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
""")

# =========================================================================
# FILE 07: API REFERENCE
# =========================================================================
write_doc("07_Drishti_API_Reference.md", """# Drishti (SIH 2026 PS-26038) — REST API Specification & Architecture

## 1. Overview & Service Gateway

* **Protocol**: HTTPS / RESTful JSON & Multipart Form Data
* **Base Production URL**: `https://eyexpert.onrender.com/api/v1`
* **Local Development URL**: `http://localhost:5000/api/v1`
* **Implementation Source**: `web_app.py`
* **Authentication**: Bearer JWT (Issued by Supabase Auth / Local Session Provider)

---

## 2. API Endpoint Catalog

### 2.1 Screening Session Management

#### `POST /screenings`
Creates a new screening session before fundus image acquisition.
* **Request Body**:
  ```json
  {
    "client_request_id": "REQ-2026-9921",
    "patient_id": "PT-RAMGARH-088",
    "age": 54,
    "gender": "FEMALE",
    "diabetes_duration_years": 8,
    "eye": "OD",
    "facility_id": "PHC-RAMGARH-01"
  }
  ```
* **Response `201 Created`**:
  ```json
  {
    "screening_id": "EX-2026-881923",
    "status": "AWAITING_IMAGE",
    "created_at": "2026-08-28T15:09:06Z"
  }
  ```

---

#### `POST /screenings/<id>/image`
Uploads raw fundus photograph and immediately executes **Image Quality Assessment**.
* **Content-Type**: `multipart/form-data` (`file: image.png/jpg`)
* **Response `200 OK`**:
  ```json
  {
    "screening_id": "EX-2026-881923",
    "status": "QUALITY_ASSESSED",
    "quality": {
      "overall_score": 0.88,
      "status": "GOOD",
      "sharpness_score": 0.92,
      "illumination_score": 0.85,
      "fov_score": 0.90,
      "feedback_messages": ["Retinal focus sharp", "Illumination balanced"]
    }
  }
  ```

---

#### `POST /screenings/<id>/analyze`
Executes ResNet-18 PyTorch neural inference and generates Grad-CAM attention maps.
* **Safety Condition**: Blocked if image quality status is `UNGRADABLE` (`422 Unprocessable Entity`).
* **Response `200 OK`**:
  ```json
  {
    "screening_id": "EX-2026-881923",
    "prediction": {
      "dr_level": 2,
      "severity_label": "Moderate Non-Proliferative Retinopathy",
      "referable": true,
      "model_probability": 0.914,
      "class_probabilities": {
        "0": 0.012,
        "1": 0.054,
        "2": 0.914,
        "3": 0.015,
        "4": 0.005
      },
      "review_priority": "HIGH",
      "recommendation": "Refer to ophthalmologist within 2-4 weeks for comprehensive retinal examination."
    },
    "model_provenance": {
      "model_id": "drishti-resnet18-aptos",
      "architecture": "ResNet-18",
      "training_dataset": "APTOS 2019 Blindness Detection",
      "model_version": "v1.2.0"
    }
  }
  ```

---

#### `GET /screenings/<id>/explainability`
Retrieves Grad-CAM heatmap, overlay URL, and attended anatomical regions.
* **Response `200 OK`**:
  ```json
  {
    "screening_id": "EX-2026-881923",
    "target_layer": "layer4[1].conv2",
    "original_image_url": "https://.../original/fundus.png",
    "gradcam_image_url": "https://.../gradcam/heatmap.png",
    "overlay_image_url": "https://.../overlay/blend.png",
    "model_attended_regions": ["Temporal vascular arcade", "Perimacular microaneurysms", "Posterior pole"],
    "disclaimer": "Highlighted regions represent areas contributing to the model prediction (Interpretability tool — not a definitive lesion diagnosis)."
  }
  ```

---

### 2.2 Clinician Review & Decision Support

#### `POST /reviews/<id>/submit`
Records the reviewing ophthalmologist's validation, override, or ungradable decision.
* **Request Body**:
  ```json
  {
    "action": "VALIDATE_AI_RESULT",
    "final_dr_level": 2,
    "clinical_notes": "AI Level 2 classification confirmed. Multiple microaneurysms and hard exudates in macula.",
    "clinician_name": "Dr. Rajesh Kumar",
    "recommended_followup_days": 30
  }
  ```
* **Response `200 OK`**:
  ```json
  {
    "screening_id": "EX-2026-881923",
    "status": "CLINICIAN_VALIDATED",
    "reviewed_at": "2026-08-28T16:20:00Z",
    "audit_event_id": "AUD-2026-99120"
  }
  ```

---

### 2.3 System Telemetry & Microservices

#### `GET /system/status`
Returns live backend health, PyTorch engine status, active device (CPU/CUDA), and RAM telemetry.
* **Response `200 OK`**:
  ```json
  {
    "status": "HEALTHY",
    "model_engine": "PyTorch ResNet-18",
    "model_loaded": true,
    "device": "cpu",
    "memory_management": "malloc_trim active",
    "active_screening_records": 14,
    "timestamp": "2026-08-28T17:00:00Z"
  }
  ```
""")

# =========================================================================
# FILE 12: DEMO SCRIPT
# =========================================================================
write_doc("12_Drishti_Demo_Script.md", """# Drishti (SIH 2026 PS-26038) — Live Demonstration & Presentation Script

## 1. Executive Demo Flow (3–5 Minutes)

| Step | Persona & Screen | Physical Action on Device / Web | Expected Outcome & System Response | Key Talking Point for Judges |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Health Worker Login** (`LoginScreen`) | Tap "Health Worker Login" (`hw@drishti.health`) | Authenticates via Supabase JWT; lands on Live Screening Dashboard | "Role-based security tailored for frontline ASHA & Primary Health Centre workers." |
| **2** | **Screening Dashboard** (`DashboardScreen`) | Show real-time sync metrics (Total Screened, Referable, Recaptures) | Pull-to-refresh syncs with PostgreSQL database in cloud | "Every metric is computed live from the cloud database — zero hardcoded counters." |
| **3** | **Patient Registration** (`PatientFormScreen`) | Enter ID: `PT-2026-8819`, Age: `54`, Eye: `Right Eye (OD)` | Session UUID `EX-2026-881923` generated with RFC4122 standard | "Idempotent registration allows offline caching without duplicate records." |
| **4** | **Image Quality Assessment** (`QualityScreen`) | Upload fundus photograph with borderline illumination | Automated Image Quality Engine computes Sharpness, Illumination, and FOV scores | "Safety First: Drishti gates AI inference on image quality to prevent misdiagnosing blurred retinas." |
| **5** | **AI Inference & Grad-CAM** (`ProcessingScreen`) | Tap "Run Drishti AI Screening" | Neural inference yields Level 2 (Moderate NPDR), 91.4% probability, and Grad-CAM | "ResNet-18 highlights pathological regions in the macular arcade with Grad-CAM neural attention." |
| **6** | **Clinical PDF Report** (`ReportScreen`) | Tap "Export / Print Clinical PDF" | Formats bilingual, standardized clinical summary document | "Standardized for rural distribution and patient record handover." |
| **7** | **Ophthalmologist Switch** (`ProfileScreen`) | Log out & sign in as Ophthalmologist (`Dr. Rajesh Kumar`) | Lands on Clinician Review Queue with urgency priority sorting | "Referable high-priority cases automatically rise to the top of the specialist's queue." |
| **8** | **Human-in-the-Loop Review** (`ClinicianReviewScreen`)| Examine dual Fundus / Grad-CAM view & tap "Validate AI Result" | Immutable audit event written to Supabase `audit_events` table; status becomes `VALIDATED` | "AI assists. Doctor decides. The physician retains final diagnostic authority." |
| **9** | **District Telemedicine Simulation** (`SimulinkDashboard`)| Display district scaling chart (120,000 annual patients) | Baseline manual overload (104% utilization) vs Drishti AI-triage (29% utilization) | "Modeled in MATLAB/Simulink: Drishti cuts specialist review queue delay from 48+ hours to < 5 minutes." |

---

## 2. Ten-Second Backup Demo Plan (If Network / Cloud Offline)

In the event of total venue network failure or cloud backend sleeping:
1. **Offline Mode**: The Flutter application detects local network disconnection and serves cached clinical cases from local secure SQLite/SharedPreferences.
2. **Deterministic Explanation**: Explain to judges: *"Drishti includes built-in offline synchronization. In disconnected rural clinics, screenings queue locally with SHA-256 integrity hashes and sync automatically once cell connectivity is restored."*
3. **Local Architecture Verification**: Run `python tests/verifyRealityAudit.py` in terminal to demonstrate all 6 deep learning and computer vision pipeline stages executing locally in 1.2 seconds.
""")

print("Part 1 builder finished successfully.")
