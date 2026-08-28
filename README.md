# Drishti (दृष्टि) — Explainable AI Retinal Screening & Decision Support Platform
### Smart India Hackathon (SIH 2026) | Problem Statement: 26038
#### Tele-Ophthalmology & Deep Learning Decision Support for Rural & Remote Primary Health Centers (PHCs)

[![SIH 2026](https://img.shields.io/badge/SIH-2026-blue.svg?style=for-the-badge&logo=gov.in)](https://sih.gov.in)
[![Model](https://img.shields.io/badge/Model-PyTorch%20ResNet--18-EE4C2C.svg?style=for-the-badge&logo=pytorch)](https://pytorch.org)
[![Dataset](https://img.shields.io/badge/Dataset-APTOS%202019%20(3%2C662%20Fundus)-00A86B.svg?style=for-the-badge)](https://www.kaggle.com/c/aptos2019-blindness-detection)
[![Database](https://img.shields.io/badge/Database-Supabase%20PostgreSQL-3ECF8E.svg?style=for-the-badge&logo=supabase)](https://supabase.com)
[![Frontend](https://img.shields.io/badge/Frontend-Flutter%203%20%2B%20Web-02569B.svg?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg?style=for-the-badge)]()

---

> [!IMPORTANT]
> **STATUTORY MEDICAL DEVICE & CLINICAL SAFETY DISCLAIMER**:  
> **Drishti (EyeXpert)** is an explainable AI-assisted screening and clinical decision-support software prototype. It is **NOT** an autonomous diagnostic medical device and does **NOT** replace a qualified ophthalmologist. All AI predictions and Grad-CAM interpretability maps serve solely as clinical decision support. Final diagnostic and therapeutic determinations must be confirmed by a licensed clinician or ophthalmologist.

---

## Table of Contents
1. [Executive Summary & Problem Statement](#1-executive-summary--problem-statement)
2. [End-to-End System Architecture](#2-end-to-end-system-architecture)
3. [Deep Learning & Model Pipeline](#3-deep-learning--model-pipeline)
   - [Backbone Architecture (ResNet-18)](#backbone-architecture-resnet-18)
   - [Dataset & Stratification (APTOS 2019)](#dataset--stratification-aptos-2019)
   - [Preprocessing & CLAHE Enhancement](#preprocessing--clahe-enhancement)
   - [Training Methodology & Loss Formulation](#training-methodology--loss-formulation)
   - [Held-Out Benchmark Performance](#held-out-benchmark-performance)
4. [Explainable AI (XAI) & Grad-CAM Heatmaps](#4-explainable-ai-xai--grad-cam-heatmaps)
5. [Automated Optical Quality Safety Gate](#5-automated-optical-quality-safety-gate)
6. [Complete REST API Specification (V1 & Web)](#6-complete-rest-api-specification-v1--web)
   - [API Endpoints Overview](#api-endpoints-overview)
   - [Detailed Endpoints & Payloads](#detailed-endpoints--payloads)
   - [cURL Request & Response Examples](#curl-request--response-examples)
7. [Supabase Cloud Database & Tele-Screening Schema](#7-supabase-cloud-database--tele-screening-schema)
   - [Relational Entity Structure](#relational-entity-structure)
   - [Row-Level Security (RLS) & Tele-Ophthalmology Flow](#row-level-security-rls--tele-ophthalmology-flow)
8. [Client-Side Applications & State Management](#8-client-side-applications--state-management)
   - [PHC Health Worker Workflow](#phc-health-worker-workflow)
   - [Ophthalmologist / Clinician Portal](#ophthalmologist--clinician-portal)
   - [Riverpod State Management Hierarchy](#riverpod-state-management-hierarchy)
   - [Offline-First Sync Engine (SQLite + Supabase)](#offline-first-sync-engine-sqlite--supabase)
9. [Tech Stack & Dependencies](#9-tech-stack--dependencies)
10. [Local Development, Installation & Deployment Guide](#10-local-development-installation--deployment-guide)

---

## 1. Executive Summary & Problem Statement

Diabetic Retinopathy (DR) is one of the leading causes of preventable blindness globally, affecting over 30% of individuals with diabetes mellitus. In rural and semi-urban Primary Health Centers (PHCs), access to trained ophthalmologists is severely constrained, leading to late-stage detection (Proliferative DR) when irreversible vision impairment has already occurred.

### SIH 2026 Problem Statement 26038 Mandate:
- **Zero Black-Box AI**: Provide transparent, visual explainability (Grad-CAM heatmaps) highlighting retinal lesions (microaneurysms, hemorrhages, hard exudates, neovascularization).
- **Automated Quality Safety Gate**: Prevent false AI reassurance caused by blurred, poorly exposed, or off-center fundus captures by evaluating optical focus, illumination, and field-of-view before running inference.
- **Bi-Directional Tele-Screening**: Connect rural frontline health workers (ASHA/PHC staff) with remote ophthalmologists via a distributed cloud database (Supabase), supporting real-time validation, overrides, and audit trails.
- **Offline Resilience**: Allow offline intake and quality screening with automatic background synchronization upon network reconnection.

---

## 2. End-to-End System Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   DRISHTI CLINICAL ARCHITECTURE                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘

    [ FRONTEND CLIENTS ]
     ┌────────────────────────────┐              ┌────────────────────────────┐
     │  Flutter Mobile / Tablet   │              │     Web Dashboard Portal   │
     │  (PHC Health Worker Kiosk) │              │  (Ophthalmologist Review)  │
     └─────────────┬──────────────┘              └─────────────┬──────────────┘
                   │                                           │
                   │  1. Multipart Upload (Fundus Photo)       │  5. Review, Override,
                   │  2. JSON Telemetry & Patient Demographics │     Audit Sign-off
                   ▼                                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                BACKEND CLOUD ENGINE (Flask / PyTorch)                           │
│                                                                                                 │
│  [ Stage 1: Optical Quality Safety Gate ]                                                       │
│    ├── Laplacian Variance Filter (Focus / Sharpness Metric)                                     │
│    ├── Luminance Intensity Histogram (Under/Over Exposure Check)                                │
│    └── Retinal Area Mask (Field of View Coverage Fraction)                                      │
│                                                                                                 │
│       ├── STATUS: UNGRADABLE  ──► Halt Inference ──► Prompt Recapture with Optical Feedback     │
│       ├── STATUS: BORDERLINE  ──► Apply Adaptive CLAHE (Green Channel Enhancement)              │
│       └── STATUS: GOOD        ──► Pass Direct to Inference Pipeline                             │
│                                                                                                 │
│  [ Stage 2: Deep Learning Inference Engine ]                                                    │
│    ├── Resolution Normalization: Bilinear Downsampling (Safe float32 bounds ≤ 512px)            │
│    ├── Normalization: ImageNet μ = [0.485, 0.456, 0.406], σ = [0.229, 0.224, 0.225]             │
│    └── ResNet-18 Forward Pass ──► 5-Class Logits ──► Softmax Probabilities [P₀, P₁, P₂, P₃, P₄] │
│                                                                                                 │
│  [ Stage 3: Explainable AI (XAI) Grad-CAM Engine ]                                              │
│    ├── Target Layer: layer4[1].conv2 (512 feature channels, 7x7 spatial map)                   │
│    ├── Backpropagation: Compute ∂(Logit[predicted_class]) / ∂(Feature_Map)                      │
│    ├── Global Average Pooling of Gradients ──► Channel Weights α_k                             │
│    ├── Weighted Linear Combination + ReLU Activation ──► Raw Activation Heatmap                 │
│    └── Turbo Colormap Colorization + 45% Alpha-Blending Overlay onto Retinal Image              │
│                                                                                                 │
│  [ Stage 4: Clinical Triage & Referral Rule Engine ]                                            │
│    ├── Level 0 (No DR)        ──► Non-Referable (Routine annual screening)                      │
│    ├── Level 1 (Mild NPDR)    ──► Non-Referable (6–12 mo follow-up, HbA1c control)              │
│    ├── Level 2 (Moderate NPDR)──► REFERABLE (Ophthalmologist consult in 4–8 wks)                │
│    ├── Level 3 (Severe NPDR)  ──► REFERABLE (Urgent specialist consult in 2–4 wks)              │
│    └── Level 4 (PDR)          ──► REFERABLE URGENT (Immediate intervention within 1–2 wks)      │
└──────────────────────────────────────────┬──────────────────────────────────────────────────────┘
                                           │
                                           │  Stores Screenings, Quality, Predictions,
                                           │  Grad-CAM URLs, Clinician Reviews, Audit Logs
                                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                SUPABASE CLOUD DATABASE (PostgreSQL)                             │
│                                                                                                 │
│   ├── public.screenings              (Master intake, eye, status, timestamps)                   │
│   ├── public.quality_assessments     (Sharpness, illumination, FOV scores, CLAHE flag)          │
│   ├── public.ai_predictions          (DR level, probabilities, referable flag, recommendations) │
│   ├── public.explainability_results  (Grad-CAM URLs, target layer, attended anatomical zones)  │
│   ├── public.clinician_reviews       (Clinician action, final grade, clinical rationale notes)  │
│   ├── public.audit_events            (Immutable medical audit trail with actor IDs)             │
│   └── storage.buckets('fundus-images')(Raw and enhanced retinal fundus photographs)             │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Deep Learning & Model Pipeline

### Backbone Architecture (ResNet-18)
The classification engine utilizes a Deep Residual Network (**ResNet-18**) architecture fine-tuned specifically for retinal fundus morphology.

```text
Input Tensor: [Batch, 3, 224, 224]
  │
  ├── Conv1: 7x7, 64, stride 2, padding 3 ──► BatchNorm ──► ReLU ──► MaxPool (3x3, stride 2)
  │
  ├── Layer 1: 2x BasicBlock [Conv 3x3 (64) ──► Conv 3x3 (64)]   (Spatial: 56x56)
  │
  ├── Layer 2: 2x BasicBlock [Conv 3x3 (128) ──► Conv 3x3 (128)] (Spatial: 28x28)
  │
  ├── Layer 3: 2x BasicBlock [Conv 3x3 (256) ──► Conv 3x3 (256)] (Spatial: 14x14)
  │
  ├── Layer 4: 2x BasicBlock [Conv 3x3 (512) ──► Conv 3x3 (512)] (Spatial: 7x7)
  │     └── Target Conv Layer for Grad-CAM: layer4[1].conv2
  │
  ├── AdaptiveAvgPool2d(output_size=(1, 1)) ──► Flatten (512 dims)
  │
  └── Linear Classifier (fc): nn.Linear(in_features=512, out_features=5)
        └── Output Logits: [z₀, z₁, z₂, z₃, z₄] ──► Softmax ──► [p₀, p₁, p₂, p₃, p₄]
```

### Dataset & Stratification (APTOS 2019)
Trained and evaluated on the **APTOS 2019 Blindness Detection Benchmark** comprising 3,662 high-resolution fundus images graded by expert clinicians on the International Clinical Diabetic Retinopathy Disease Severity Scale (ICDR):

| DR Level | Clinical Classification | Description & Pathological Markers | Training Samples |
| :---: | :--- | :--- | :---: |
| **0** | **No DR** | Clear retina, healthy vasculature, no visible lesions | 1,805 |
| **1** | **Mild NPDR** | Microaneurysms only (isolated focal capillary dilatations) | 370 |
| **2** | **Moderate NPDR** | Microaneurysms, hard exudates, dot-and-blot hemorrhages | 999 |
| **3** | **Severe NPDR** | Extensive intraretinal hemorrhages (4 quadrants), venous beading | 193 |
| **4** | **Proliferative DR (PDR)**| Neovascularization, vitreous/preretinal hemorrhages, fibrous tissue | 295 |
| **Total** | | **Stratified Split: 70% Train (2,563), 15% Val (550), 15% Held-Out Test (549)** | **3,662** |

### Preprocessing & CLAHE Enhancement
1. **Circular Mask Auto-Crop**: Unnecessary black camera borders are cropped by thresholding pixel intensity $>15$ and finding bounding contour coordinates $(x_0, y_0, x_1, y_1)$.
2. **Contrast-Limited Adaptive Histogram Equalization (CLAHE)**: When image quality is marked as `BORDERLINE`, CLAHE is applied to the Green channel (which exhibits maximum optical contrast with retinal hemoglobin) using `clipLimit=2.0, tileGridSize=(8, 8)`.
3. **Tensor Normalization**: Normalized with standard ImageNet distribution:
   $$\text{Tensor} = \frac{\frac{X}{255} - \mu}{\sigma}, \quad \mu = [0.485, 0.456, 0.406], \quad \sigma = [0.229, 0.224, 0.225]$$

### Training Methodology & Loss Formulation
- **Optimization Algorithm**: AdamW with weight decay $\lambda = 10^{-4}$ and initial learning rate $\eta = 3 \times 10^{-4}$ governed by a Cosine Annealing Learning Rate scheduler.
- **Class-Imbalance Mitigation**: Weighted Cross-Entropy Loss with inverse class frequency weights:
  $$w_c = \frac{N}{5 \cdot N_c}, \quad \mathcal{L}_{\text{CE}} = -\sum_{c=0}^4 w_c \cdot y_c \log(p_c)$$
- **Data Augmentation**: Random horizontal/vertical flips ($p=0.5$), random affine rotations ($-25^\circ \le \theta \le +25^\circ$), color jitter (brightness $0.2$, contrast $0.2$), and random scaling.

### Held-Out Benchmark Performance

| Metric | Measured Value | Standard Target | Status |
| :--- | :---: | :---: | :---: |
| **Quadratic Weighted Kappa (QWK)** | **0.870** | $> 0.80$ | **Clinical Benchmark Passed** |
| **Referable DR Sensitivity (Level $\ge 2$)** | **82.14%** | $> 80.0\%$ | **Valid Screening Target** |
| **Referable DR Specificity** | **96.62%** | $> 85.0\%$ | **High Specificity (Low False Referrals)** |
| **Binary Classification Accuracy** | **90.71%** | $> 85.0\%$ | **Passed** |
| **Area Under ROC Curve (ROC-AUC)** | **0.980** | $> 0.90$ | **Exceptional Discriminatory Power** |
| **Held-Out Test Sample Count** | **549** | — | **Unseen Real APTOS Images** |

---

## 4. Explainable AI (XAI) & Grad-CAM Heatmaps

To satisfy SIH 2026 transparency mandates, Drishti computes Gradient-weighted Class Activation Mapping (**Grad-CAM**) on the final convolutional layer: `layer4[1].conv2`.

```math
\alpha_k^c = \frac{1}{Z} \sum_{i=1}^u \sum_{j=1}^v \frac{\partial y^c}{\partial A_{i,j}^k}
```
```math
L_{\text{Grad-CAM}}^c = \text{ReLU}\left( \sum_k \alpha_k^c A^k \right)
```

1. **Forward Pass**: Forward-hook captures feature maps $A \in \mathbb{R}^{512 \times 7 \times 7}$.
2. **Backward Hook**: Backpropagation computes the gradient of target class score $y^c$ with respect to each feature channel $A^k$.
3. **Weight Pooling**: Spatial Global Average Pooling computes importance weights $\alpha_k^c$.
4. **Rectified Combination**: Positive linear combination is passed through a $\text{ReLU}$ gate to isolate features positively contributing to the DR level.
5. **Turbo Rendering & Safe Blending**: Heatmap is resized to image bounds using OpenCV bilinear interpolation, colorized with `cv2.COLORMAP_TURBO`, and blended with the original fundus image at $\alpha = 0.45$:
   $$I_{\text{overlay}} = (1 - 0.45 \cdot \text{CAM}) \cdot I_{\text{orig}} + (0.45 \cdot \text{CAM}) \cdot I_{\text{colored}}$$

---

## 5. Automated Optical Quality Safety Gate

Before any image reaches the PyTorch neural network, it must pass a 3-point optical quality evaluation to prevent AI hallucinations on compromised captures:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                       OPTICAL QUALITY SAFETY GATE METRICS                  │
├──────────────────────────┬─────────────────────────────────────────────────┤
│ Metric                   │ Mathematical Formulation & Implementation       │
├──────────────────────────┼─────────────────────────────────────────────────┤
│ 1. Focus & Sharpness     │ Variance of Laplacian operator:                 │
│                          │   Var(∇² I) = Var(∂²I/∂x² + ∂²I/∂y²)            │
│                          │ Normalized Score: S = 1 / (1 + exp(-0.08(Var-30)))│
├──────────────────────────┼─────────────────────────────────────────────────┤
│ 2. Illumination/Exposure │ Retinal luminance mean & percentile histogram:  │
│                          │   Under-exposure fraction: P(Intensity < 25)    │
│                          │   Over-exposure fraction:  P(Intensity > 240)   │
├──────────────────────────┼─────────────────────────────────────────────────┤
│ 3. Field of View (FOV)   │ Tissue coverage fraction:                       │
│                          │   FOV = Σ(Mask_retina) / (Width * Height)       │
├──────────────────────────┼─────────────────────────────────────────────────┤
│ Overall Quality Score    │ Q = 0.45*Sharpness + 0.35*Illum + 0.20*FOV      │
└──────────────────────────┴─────────────────────────────────────────────────┘
```

### Safety Triage Decisions:
- **`GOOD` ($Q \ge 0.70$)**: Proceed immediately to ResNet-18 inference.
- **`BORDERLINE` ($0.45 \le Q < 0.70$)**: Apply green-channel CLAHE enhancement; notify clinician of border quality.
- **`UNGRADABLE` ($Q < 0.45$)**: **Block neural network inference completely**. Prompt frontline health worker with specific recapture advice (*"Focus too low: steady device against patient brow"*, *"Underexposed: increase illumination intensity"*).

---

## 6. Complete REST API Specification (V1 & Web)

The backend provides a dual REST interface:
1. `/api/v1/*` — Enterprise REST specification for mobile apps, tele-screening kiosks, and external hospital HIS/EMR integrations.
2. `/api/*` — Synchronous web dashboard endpoints.

### API Endpoints Overview

| Method | Endpoint | Description | Auth / Role |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1` | Service index, version, and route directory | Public |
| `GET` | `/api/v1/system/status` | Real model loading status & provenance metadata | Public |
| `POST` | `/api/v1/screenings` | Initialize new clinical screening session | Health Worker / Kiosk |
| `POST` | `/api/v1/screenings/<id>/image` | Upload retinal photograph & run quality safety gate | Health Worker / Kiosk |
| `GET` | `/api/v1/screenings/<id>/quality` | Retrieve optical quality report and metrics | Any |
| `POST` | `/api/v1/screenings/<id>/analyze` | Trigger real PyTorch forward pass & Grad-CAM | Health Worker / Kiosk |
| `GET` | `/api/v1/screenings/<id>/explainability`| Retrieve Grad-CAM heatmap & overlay data URLs | Clinician / Worker |
| `POST` | `/api/screenings/upload` | Legacy single-step upload & inference for Web UI | Web Client |
| `GET` | `/api/screenings/sample_run` | Run benchmark sample validation by sample key | Web Client |
| `POST` | `/api/screenings/<id>/submit_queue` | Register screening into ophthalmologist review queue | Web Client |

---

### Detailed Endpoints & Payloads

#### 1. Create Screening Session
`POST /api/v1/screenings`

**Request Body (`application/json`)**:
```json
{
  "client_request_id": "REQ-0091-OD",
  "patient_id": "PT-9042",
  "patient_name": "Ramesh Patel",
  "age": 58,
  "gender": "MALE",
  "diabetes_duration_years": 12,
  "hba1c": 8.9,
  "eye": "OD",
  "facility_id": "PHC-RAMGARH-01"
}
```

**Response (`201 Created`)**:
```json
{
  "screening_id": "EX-2026-9A1B2C",
  "client_request_id": "REQ-0091-OD",
  "patient_id": "PT-9042",
  "eye": "OD",
  "status": "AWAITING_IMAGE",
  "created_at": "2026-08-28T20:25:00Z"
}
```

---

#### 2. Upload Retinal Fundus Photograph
`POST /api/v1/screenings/{id}/image`

**Request Headers**: `Content-Type: multipart/form-data`  
**Request Field**: `file` (Binary Image File: `.png`, `.jpg`, `.jpeg`)

**Response (`200 OK`)**:
```json
{
  "screening_id": "EX-2026-9A1B2C",
  "image_id": "IMG-2026-9A1B2C",
  "status": "IMAGE_RECEIVED",
  "quality": {
    "screening_id": "EX-2026-9A1B2C",
    "overall_score": 0.912,
    "status": "GOOD",
    "sharpness": {
      "metric_name": "Laplacian Focus & Sharpness",
      "score": 0.945,
      "status": "GOOD"
    },
    "illumination": {
      "metric_name": "Illumination & Exposure",
      "score": 0.880,
      "status": "GOOD"
    },
    "field_of_view": {
      "metric_name": "Retinal Mask Field of View",
      "score": 0.925,
      "status": "ADEQUATE"
    },
    "enhancement_applied": false,
    "feedback_messages": [
      "Optimal focus, exposure, and field coverage confirmed."
    ],
    "evaluated_at": "2026-08-28T20:25:05Z"
  }
}
```

---

#### 3. Execute Deep Neural Inference
`POST /api/v1/screenings/{id}/analyze`

**Response (`200 OK`)**:
```json
{
  "screening_id": "EX-2026-9A1B2C",
  "dr_level": 2,
  "severity_label": "Level 2 — Moderate Non-Proliferative DR (Moderate NPDR)",
  "severity_code": "MODERATE_NPDR",
  "referable": true,
  "model_probability": 0.9653,
  "calibrated_confidence": null,
  "class_probabilities": {
    "0": 0.0001,
    "1": 0.0204,
    "2": 0.9653,
    "3": 0.0026,
    "4": 0.0115
  },
  "review_priority": "HIGH",
  "recommendation": "Ophthalmologist referral recommended within 4 to 8 weeks for dilated fundus exam and OCT evaluation.",
  "provenance": {
    "name": "Drishti DR Classifier",
    "architecture": "ResNet-18 (Deep Residual Learning)",
    "training_dataset": "APTOS 2019 Blindness Detection (3,662 Fundus Images)",
    "version": "v1.0.0-SIH2026",
    "explainability_layer": "layer4[1].conv2 (Last Convolutional Feature Map)",
    "device": "cpu"
  },
  "analyzed_at": "2026-08-28T20:25:10Z"
}
```

---

#### 4. Fetch Grad-CAM Visual Explainability
`GET /api/v1/screenings/{id}/explainability`

**Response (`200 OK`)**:
```json
{
  "screening_id": "EX-2026-9A1B2C",
  "target_layer": "layer4[1].conv2",
  "gradcam_image_url": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "overlay_image_url": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "original_image_url": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "model_attended_regions": [
    "Temporal vascular arcade",
    "Perimacular microaneurysms",
    "Posterior pole"
  ],
  "disclaimer": "Highlighted regions represent areas contributing to the model prediction (Interpretability tool — not a definitive lesion diagnosis)."
}
```

---

### cURL Request & Response Examples

```bash
# 1. Check system and model engine health
curl -X GET https://eyexpert.onrender.com/api/v1/system/status

# 2. Create screening session
curl -X POST https://eyexpert.onrender.com/api/v1/screenings \
  -H "Content-Type: application/json" \
  -d '{"patient_id": "PT-TEST-001", "eye": "OD"}'

# 3. Upload fundus image for quality gating
curl -X POST https://eyexpert.onrender.com/api/v1/screenings/EX-2026-9A1B2C/image \
  -F "file=@data/aptos/preprocessed_224/000c1434d8d7.png"

# 4. Run PyTorch ResNet-18 forward pass & Grad-CAM
curl -X POST https://eyexpert.onrender.com/api/v1/screenings/EX-2026-9A1B2C/analyze

# 5. Fetch explainability heatmap data
curl -X GET https://eyexpert.onrender.com/api/v1/screenings/EX-2026-9A1B2C/explainability
```

---

## 7. Supabase Cloud Database & Tele-Screening Schema

The database is built on Supabase PostgreSQL with relational integrity, foreign key cascades, and Row-Level Security (RLS) policies.

```text
┌───────────────────────┐       1:1       ┌──────────────────────────┐
│   public.screenings   │─────────────────│ public.quality_assessment│
└──────────┬────────────┘                 └──────────────────────────┘
           │
           │ 1:1
           ├──────────────────────────────┬──────────────────────────┐
           ▼                              ▼                          ▼
┌───────────────────────┐     ┌────────────────────────┐ ┌───────────────────────┐
│ public.ai_predictions │     │public.explainability_r.│ │public.clinician_review│
└───────────────────────┘     └────────────────────────┘ └───────────┬───────────┘
                                                                     │ 1:N
                                                                     ▼
                                                         ┌───────────────────────┐
                                                         │  public.audit_events  │
                                                         └───────────────────────┘
```

### Complete Table Schema Definition (`supabase/schema.sql`)

```sql
-- 1. SCREENINGS TABLE (Master Record)
CREATE TABLE IF NOT EXISTS public.screenings (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT UNIQUE NOT NULL,
    client_request_id TEXT,
    patient_id TEXT NOT NULL,
    patient_name TEXT,
    age INT CHECK (age >= 0 AND age <= 130),
    gender TEXT CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    diabetes_duration_years INT CHECK (diabetes_duration_years >= 0),
    hba1c NUMERIC(4, 2),
    eye TEXT NOT NULL CHECK (eye IN ('OD', 'OS', 'OD (Right Eye)', 'OS (Left Eye)')),
    facility_id TEXT NOT NULL DEFAULT 'PHC-RAMGARH-01',
    status TEXT NOT NULL DEFAULT 'AWAITING_IMAGE' 
        CHECK (status IN ('AWAITING_IMAGE', 'IMAGE_RECEIVED', 'QUALITY_ASSESSMENT', 'AI_PROCESSING', 'READY_FOR_REVIEW', 'COMPLETED', 'UNGRADABLE', 'RECAPTURE_REQUIRED', 'SYNCED')),
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. QUALITY ASSESSMENTS TABLE (Safety Gate)
CREATE TABLE IF NOT EXISTS public.quality_assessments (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    quality_score NUMERIC(5, 4) NOT NULL CHECK (quality_score >= 0.0 AND quality_score <= 1.0),
    status TEXT NOT NULL CHECK (status IN ('GOOD', 'BORDERLINE', 'UNGRADABLE')),
    sharpness_score NUMERIC(5, 4) NOT NULL,
    illumination_score NUMERIC(5, 4) NOT NULL,
    fov_score NUMERIC(5, 4) NOT NULL,
    mean_intensity NUMERIC(5, 2),
    clahe_applied BOOLEAN DEFAULT FALSE,
    feedback_messages JSONB DEFAULT '[]'::jsonb,
    evaluated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. AI PREDICTIONS TABLE (PyTorch Inference)
CREATE TABLE IF NOT EXISTS public.ai_predictions (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    dr_level INT NOT NULL CHECK (dr_level >= 0 AND dr_level <= 4),
    severity_label TEXT NOT NULL,
    referable BOOLEAN NOT NULL,
    model_probability NUMERIC(5, 4) NOT NULL,
    calibrated_confidence NUMERIC(5, 4),
    class_probabilities JSONB,
    review_priority TEXT DEFAULT 'NORMAL' CHECK (review_priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    recommendation TEXT,
    model_version TEXT DEFAULT 'EyeXpert_ResNet18_v1.0',
    provenance JSONB,
    analyzed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. EXPLAINABILITY RESULTS TABLE (Grad-CAM XAI)
CREATE TABLE IF NOT EXISTS public.explainability_results (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    target_layer TEXT NOT NULL DEFAULT 'layer4[1].conv2',
    gradcam_url TEXT,
    overlay_url TEXT,
    original_url TEXT,
    model_attended_regions JSONB DEFAULT '[]'::jsonb,
    disclaimer TEXT,
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. CLINICIAN REVIEWS TABLE (Tele-Ophthalmology Sign-Off)
CREATE TABLE IF NOT EXISTS public.clinician_reviews (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    reviewer_id UUID REFERENCES auth.users(id),
    clinician_name TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('VALIDATE_AI', 'OVERRIDE_GRADE', 'REJECT_RECAPTURE', 'ORDER_OCT', 'CONFIRMED')),
    final_dr_level INT CHECK (final_dr_level >= 0 AND final_dr_level <= 4),
    final_referable BOOLEAN,
    clinical_notes TEXT NOT NULL,
    recommended_followup_days INT DEFAULT 90,
    reviewed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. AUDIT EVENTS TABLE (Immutable Medical Log)
CREATE TABLE IF NOT EXISTS public.audit_events (
    id BIGSERIAL PRIMARY KEY,
    screening_id TEXT NOT NULL REFERENCES public.screenings(screening_id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    actor_id TEXT,
    payload JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 8. Client-Side Applications & State Management

### PHC Health Worker Workflow
1. **Patient Intake Screen**: Frontline worker registers Patient ID, Age, Gender, Diabetes Duration, and Eye selection (OD / OS).
2. **Optical Capture & Safety Gate**: Worker uploads or captures fundus photo. The app displays real-time Laplacian focus, exposure, and FOV scores.
3. **5-Stage Clinical Processing**:
   - *Stage 1*: Retinal Image Ingestion
   - *Stage 2*: Optical Quality Gating
   - *Stage 3*: Green-Channel CLAHE
   - *Stage 4*: ResNet-18 Neural Inference
   - *Stage 5*: Grad-CAM XAI Map Generation & Supabase Cloud Sync
4. **Patient Handout & Educational Summary**: Simple visual summary explaining next clinical steps in plain language with follow-up timeline.

### Ophthalmologist / Clinician Portal
1. **Prioritized Review Queue**: Cases are automatically sorted with **High Priority Referable cases ($L \ge 2$)** surfaced to the top.
2. **Grad-CAM Visualizer**: Interactive toggle between Original, Enhanced, Grad-CAM Heatmap, and Alpha Overlay views.
3. **Decision Form**:
   - **Validate AI Result**: Agrees with predicted DR level.
   - **Override Grade**: Clinician overrides AI grade (mandates mandatory explanatory clinical rationale notes).
   - **Order Recapture**: Discards poor-quality images.
4. **Audit Trail**: Every action logs timestamp, clinician name, rationale, and previous vs final grade into `audit_events`.

### Riverpod State Management Hierarchy

```text
ProviderContainer
  ├── screeningServiceProvider (ScreeningService -> ApiClient + SupabaseService)
  ├── screeningRepositoryProvider (ScreeningRepository)
  ├── screeningSessionProvider (ScreeningSessionNotifier -> ScreeningSessionState)
  │     ├── patient: PatientModel
  │     ├── quality: QualityAssessmentModel
  │     ├── prediction: DRPredictionModel
  │     ├── explainability: ExplainabilityModel
  │     └── status: ScreeningStatus
  │
  ├── reviewServiceProvider (ReviewService)
  ├── reviewRepositoryProvider (ReviewRepository)
  └── reviewQueueProvider (ReviewQueueNotifier -> ReviewQueueState)
        ├── cases: List<ScreeningCaseModel>
        ├── filter: 'ALL' | 'REFERABLE' | 'PENDING' | 'VALIDATED'
        └── searchQuery: String
```

---

## 9. Tech Stack & Dependencies

### Python Backend & AI Engine
- **`torch==2.2.2+cpu` / `torchvision==0.17.2+cpu`**: Deep learning model loading, forward pass, and autograd backprop for Grad-CAM.
- **`opencv-python-headless==4.9.0.80`**: Laplacian variance focus calculation, Turbo colormap generation, and fast bilinear resizing.
- **`Pillow==10.2.0`**: Image I/O, format conversion, and crop segmentation.
- **`numpy==1.26.4`**: Matrix operations, tensor normalization, and statistical distributions.
- **`Flask==3.0.2` & `gunicorn==21.2.0`**: Production WSGI web framework.

### Flutter Mobile & Web Client
- **`flutter_riverpod: ^2.5.1`**: Reactive dependency injection and unidirectional state management.
- **`supabase_flutter: ^2.5.0`**: Real-time PostgreSQL database synchronization and storage bucket I/O.
- **`http: ^1.2.1`**: Multipart streaming uploads and REST API communication.
- **`fl_chart: ^0.66.2`**: Class probability bar charts and diagnostic visualization.
- **`uuid: ^4.3.3`**: RFC4122 unique screening identifier generation.

---

## 10. Local Development, Installation & Deployment Guide

### Prerequisites
- Python 3.10+ / 3.11 / 3.12 / 3.13
- Flutter 3.19+ (Dart 3.3+)
- Git

### 1. Clone the Repository
```bash
git clone https://github.com/Preetdudhat03/EyeXpert.git
cd EyeXpert
```

### 2. Backend Setup & Run
```bash
# Create and activate virtual environment
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Run backend locally (Port 5000)
python web_app.py
```
Open **`http://localhost:5000`** in your browser to access the complete Drishti Web Screening Dashboard.

### 3. Flutter App Setup & Run
```bash
cd eyexpert_app

# Fetch dependencies
flutter pub get

# Run on Chrome / Web
flutter run -d chrome

# Run on Android Device / Emulator
flutter run -d android
```

### 4. Cloud Deployment (Render.com)
The repository includes a production-ready `Procfile`:
```text
web: gunicorn web_app:app --bind 0.0.0.0:$PORT --workers 1 --threads 1 --max-requests 50 --max-requests-jitter 5 --timeout 120
```
- Create a new **Web Service** on [Render.com](https://render.com).
- Connect this GitHub repository (`EyeXpert`).
- Set Build Command: `pip install -r requirements.txt`
- Set Start Command: `gunicorn web_app:app --bind 0.0.0.0:$PORT --workers 1 --threads 1 --timeout 120`

---

## Team & Attribution
- **Project**: Drishti (EyeXpert)
- **Competition**: Smart India Hackathon (SIH 2026)
- **Problem Statement**: 26038 (Diabetic Retinopathy Screening & Decision Support)
- **Lead Developer & AI Architect**: Preet Dudhat ([@Preetdudhat03](https://github.com/Preetdudhat03))

*Developed with ❤️ for advancing accessible, transparent, and equitable healthcare across India.*