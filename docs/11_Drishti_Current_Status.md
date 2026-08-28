# Drishti (SIH 2026 PS-26038) — Project Audit & Implementation Status Matrix

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
