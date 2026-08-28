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
# FILE 01: MASTER TECHNICAL REPORT (COMPLETE REVERSE ENGINEERING)
# =========================================================================
write_doc("01_Drishti_Master_Technical_Report.md", """# DRISHTI (दृष्टि) — Master Technical Report & Architecture Documentation

## Explainable AI-Assisted Diabetic Retinopathy Screening & Clinical Decision Support System
**Smart India Hackathon 2026 | Problem Statement: PS-26038 | MathWorks**

---

# 1. Executive Summary & Project Identity

### 1.1 Product Identity & Vision
* **Product Name**: **DRISHTI** (दृष्टि)
* **Tagline**: *Clinical Intelligence + Human Care*
* **Full Title**: *Explainable AI-Assisted Diabetic Retinopathy Screening and Clinical Decision Support System*
* **Problem Statement**: SIH 2026 PS-26038 (MathWorks / MedTech)
* **Primary Objective**: Bridge the rural ophthalmology deficit across India by deploying a safety-gated, explainable, deep-learning screening platform to Primary Health Centres (PHCs), triaging routine cases and empowering district ophthalmologists with AI-assisted decision support.

---

# 2. Problem Statement Breakdown (PS-26038)

| Requirement in PS-26038 | Clinical & Engineering Rationale | Drishti Implementation | Source File Evidence | Implementation Status |
| :--- | :--- | :--- | :--- | :---: |
| **Image Quality Assessment** | Prevent misdiagnosis caused by blur, poor illumination, or occlusion. | Laplacian variance, percentile brightness, and Otsu FOV masking. | `quality/assessImageQuality.m`, `web_app.py` | **IMPLEMENTED** |
| **Adaptive Image Enhancement** | Improve subtle microaneurysm contrast on borderline fundus photos. | Green channel CLAHE (ClipLimit=0.02, 8x8 tiles) + auto-cropping. | `preprocessing/enhanceFundus.m`, `train_aptos_real.py` | **IMPLEMENTED** |
| **Retinal Structure Analysis** | Anatomical referencing for clinical review. | Blood vessel top-hat filtering & Optic disc Gaussian centroid detection. | `cv_analysis/extractVessels.m`, `cv_analysis/locateOpticDisc.m` | **IMPLEMENTED (EXPLORATORY)**|
| **5-Class DR Severity Grading** | Standardized ICDR staging (Levels 0–4). | Fine-tuned ResNet-18 with 5-class linear head. | `models/EyeXpert_ResNet18_best.pth`, `classification/classifyDR.m` | **IMPLEMENTED** |
| **Referable DR Binary Triage** | Separate non-referable (0-1) from referable (2-4). | Level >= 2 thresholding logic. | `classification/determineReferableDR.m`, `web_app.py` | **IMPLEMENTED** |
| **Explainable AI (Grad-CAM)** | Visual verification of neural attention for clinicians. | Gradient backprop on `layer4[1].conv2` feature maps. | `explainability/generateGradCAM.m`, `train_aptos_real.py` | **IMPLEMENTED** |
| **Clinical-Style Report** | Standardized bilingual summary for patient referral. | PDF export engine with thermal print support. | `reporting/generateScreeningReport.m`, Flutter `pdf` | **IMPLEMENTED** |
| **Human-in-the-Loop Telemedicine**| AI assists; licensed ophthalmologist makes final decision. | Dedicated review queue with Validate/Override actions and audit logging. | `eyexpert_app/lib/features/review/`, `supabase/schema.sql` | **IMPLEMENTED** |
| **District Telemedicine Simulation**| Validate annual scaling for 100,000+ patients. | M/M/c discrete-event queuing simulation in MATLAB/Simulink. | `simulink/runDistrictSimulation.m`, `simulink/createDistrictModel.m` | **IMPLEMENTED** |

---

# 3. End-to-End System Workflow

```text
[Raw Fundus Capture] (PHC Health Worker via Camera/Gallery)
       │
       ▼
[Image Quality Gate] (Laplacian Sharpness, Exposure, FOV)
       │
   ┌───┴───────────────────────────────┐
   │ Score < 0.45                      │ Score >= 0.45
   ▼                                   ▼
[UNGRADABLE] (Block AI & Recapture)  [Preprocessing & CLAHE]
                                       │
                                       ▼
                                [ResNet-18 Forward Pass]
                                       │
                                ┌──────┴────────────────────────┐
                                ▼                               ▼
                         [5-Class Softmax]            [Grad-CAM on Layer4]
                                │                               │
                                ▼                               ▼
                         [Referable Triage]           [Multi-Layer Heatmap Overlay]
                                │                               │
                                └───────┬───────────────────────┘
                                        │
                                        ▼
                                [Supabase Cloud Sync]
                                        │
                                        ▼
                         [Clinician Telemedicine Queue]
                                        │
                                        ▼
                         [Doctor Validate / Override]
                                        │
                                        ▼
                         [Immutable PostgreSQL Audit Trail]
```

---

# 4. Image Quality Gating & Preprocessing Engine

### 4.1 Sharpness / Focus Detection via Laplacian Variance
Blur detection computes the second spatial derivative of the grayscale retinal image:
$$\nabla^2 I(x, y) = \frac{\partial^2 I}{\partial x^2} + \frac{\partial^2 I}{\partial y^2}$$
Variance $\sigma^2_{\nabla^2 I}$ is evaluated exclusively on the retinal foreground mask. Sharp images yield high variance ($\sigma^2 > 350$), while blurred images produce low variance ($\sigma^2 < 100$). Normalized score:
$$S_{\text{sharp}} = \min\left(1.0, \frac{\sigma^2_{\nabla^2 I}}{500.0}\right)$$

### 4.2 Illumination & Exposure Analysis
* Evaluates mean luminance $Y$, 5th percentile ($P_5$), and 95th percentile ($P_{95}$).
* Penalizes severe underexposure ($Y < 25$) and saturation overexposure ($P_{95} > 240$).

### 4.3 Field of View (FOV) Masking
* Otsu thresholding creates binary retinal mask $M(x,y)$.
* Evaluates foreground area over bounding box area: $\text{Coverage} \ge 65\%$.

### 4.4 Composite Quality Score Formula
$$\text{Quality Score} = 0.45 \times S_{\text{sharp}} + 0.35 \times S_{\text{illum}} + 0.20 \times S_{\text{FOV}}$$
* **GOOD** ($\ge 0.70$): Direct AI processing.
* **BORDERLINE** ($0.45 - 0.69$): Automated Green-Channel CLAHE enhancement applied before AI.
* **UNGRADABLE** ($< 0.45$): AI blocked; physical recapture instructions displayed.

---

# 5. Deep Learning Architecture & Training Pipeline

### 5.1 Model Architecture (ResNet-18 Transfer Learning)
* **Backbone**: Pretrained ImageNet-1k ResNet-18 (11.2M parameters).
* **Residual Connections**: Skip connections $y = F(x, \{W_i\}) + x$ eliminate vanishing gradients during fine-tuning.
* **Feature Extraction**: 4 residual layer stages producing 512-dimensional semantic vectors.
* **Classification Head**: `nn.Linear(512, 5)` mapping to logits $[z_0, z_1, z_2, z_3, z_4]$.
* **Softmax Output**:
  $$P(\text{Class } i) = \frac{\exp(z_i)}{\sum_{j=0}^4 \exp(z_j)}$$

### 5.2 Dataset Partitioning & Class Imbalance Strategy
* **Dataset**: APTOS 2019 Blindness Detection (3,662 labeled images).
* **Stratified Split**: 70% Train ($n=2563$), 15% Validation ($n=550$), 15% Held-Out Test ($n=549$) with seed 42.
* **Inverse-Frequency Loss Weights**:
  $$W_c = \frac{N_{\text{total}}}{5 \times N_c} \implies W = [0.41, 1.98, 0.73, 3.80, 2.48]$$
* **Optimizer**: AdamW ($LR=10^{-4}$, Weight Decay=$10^{-2}$).
* **LR Scheduler**: `ReduceLROnPlateau(mode='max', factor=0.5, patience=2)` on validation QWK.

---

# 6. Real Model Validation Results (Held-Out Test Split)

| Metric | Measured Result | SIH PS-26038 Target | Evaluation Status |
| :--- | :---: | :---: | :--- |
| **5-Class Multiclass Accuracy** | **76.87%** | -- | Evaluated |
| **Quadratic Weighted Kappa (QWK)** | **0.870** | > 0.80 | **EXCEEDED** |
| **Binary Referable Specificity** | **96.62%** | > 85.0% | **MET** |
| **Binary Referable Sensitivity** | **82.14%** | > 90.0% | **BELOW_TARGET** (Analyzed & Reported) |
| **Referable Precision (PPV)** | **94.36%** | -- | Evaluated |
| **Referable ROC AUC** | **0.980** | > 0.90 | **EXCEEDED** |

### 6.1 Honest Error Analysis
* **Adjacent Grade Boundary**: 36 of 40 false negative cases were Grade 2 cases classified as Grade 1 due to subtle microaneurysms smoothed during $224 \times 224$ downsampling.
* **Safety Net**: Drishti mandates Human-in-the-Loop review for all borderline and clinical cases.

---

# 7. Explainable AI (Grad-CAM)

* **Target Layer**: `layer4[1].conv2` (512 feature maps of size $7 \times 7$).
* **Gradients**: Backpropagated class score gradients $\frac{\partial y^c}{\partial A^k}$.
* **Global Pooling**: Neuron importance weights $\alpha_k^c = \frac{1}{Z} \sum_{i,j} \frac{\partial y^c}{\partial A_{i,j}^k}$.
* **Heatmap Fusion**: $L^c = \text{ReLU}\left(\sum_k \alpha_k^c A^k\right)$, upsampled to $224 \times 224$ and blended over RGB fundus at $\alpha=0.45$.

---

# 8. District-Scale Telemedicine Simulation (MATLAB / Simulink)

* **Annual Workload**: 120,000 diabetic patients in a representative rural district.
* **Arrival Rate**: $\lambda = 50$ patients/hour across 300 working days.
* **Baseline (100% Manual Doctor Review)**:
  * 2 District Ophthalmologists ($\mu = 48$ cases/hr total capacity).
  * System Utilization: $\rho = \frac{50}{48} = 104.2\%$ (**Overloaded $\rightarrow$ Unbounded queue growth, $>48$ hr delays**).
* **Optimized (Drishti Automated AI Triage)**:
  * ~72% Non-Referable cases cleared automatically for routine annual recall.
  * Specialist Arrival Rate: $\lambda_{\text{doc}} = 14$ cases/hr.
  * System Utilization: $\rho = \frac{14}{48} = 29.2\%$ (**Stable $\rightarrow$ Clinician queue delay $< 4.2$ minutes**).

---

# 9. Cloud, Mobile & Security Infrastructure

* **Mobile/Web Client**: Flutter Material 3 with Riverpod 2.5 reactive state management.
* **Database & Auth**: Supabase PostgreSQL with Row Level Security (RLS) policies and JWT authentication.
* **Offline Sync Queue**: Encrypted SQLite storage with SHA-256 integrity hashes for rural connectivity loss.
* **Audit Trail**: Every clinician review, override reason, and timestamp is appended immutably to `audit_events`.

---

# 10. Conclusion & Future Roadmap

Drishti provides a complete, safety-first, explainable medical screening system engineered specifically for rural India's healthcare realities. By combining multi-factor image quality gating, deep learning classification, Grad-CAM neural attention, and district-scale queuing optimization, Drishti empowers frontline health workers while preserving specialist clinical authority.
""")

print("Master Technical Report generated successfully.")
