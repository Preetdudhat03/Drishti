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
# FILE 03: SIH PRESENTATION CONTENT (15 SLIDES)
# =========================================================================
write_doc("03_Drishti_SIH_Presentation_Content.md", """# Drishti (SIH 2026 PS-26038) — SIH 2026 Selection Round Presentation Content

## Slide Deck Overview: 15 Master Slides
* **Theme Palette**: Deep Navy (`#090E17`, `#0F172A`), Clinical Cyan/Teal (`#0EA5E9`, `#0D9488`), Emerald (`#10B981`), Amber (`#F59E0B`), Crimson (`#EF4444`), White (`#FFFFFF`).
* **Design Philosophy**: Clinical intelligence, mathematical rigor, transparent validation, clean visual hierarchy.

---

### SLIDE 1: Title & Project Identity
* **Header**: DRISHTI (दृष्टि)
* **Tagline**: Clinical Intelligence + Human Care
* **Sub-Header**: Explainable AI-Assisted Diabetic Retinopathy Screening & Clinical Decision Support System
* **SIH Context**: Smart India Hackathon 2026 | Problem Statement: PS-26038 | MathWorks
* **Key Visual**: Drishti Geometric Eye Logo + ResNet Feature Map + Primary Health Centre Telemedicine Flow
* **Team**: Preet Dudhat & Team

---

### SLIDE 2: The Healthcare Crisis & Rural Bottleneck
* **Title**: The Diabetic Blindness Crisis in Rural India
* **Core Problem**:
  * **77+ Million Diabetic Patients** in India require annual retinal examinations.
  * **Severe Specialist Deficit**: ~20,000 ophthalmologists nationwide; ratio in rural districts is < 1:100,000.
  * **Silent Disease Progression**: Early stages (NPDR) are completely asymptomatic; by the time patients notice vision loss, damage is irreversible.
  * **Diagnostic Delay**: Rural patients travel 50–100 km only to wait weeks for routine screening.
* **Key Visual**: Map of India showing rural specialist deficit vs rural diabetic density.

---

### SLIDE 3: Why Existing AI Solutions Fail in the Field
* **Title**: The Triad of Failure in Traditional Medical AI
* **1. Black-Box Opacity**: Traditional CNNs output a single number ("91% DR") without anatomical evidence, causing physicians to reject automated decisions.
* **2. Quality Blindness**: Models attempt inference on blurred or dark images, generating catastrophic false negatives.
* **3. Telemedicine Disconnection**: Standalone AI scripts fail to integrate into real-world rural clinic workflows and offline constraints.
* **Key Visual**: Broken workflow comparison: Black-box classifier vs Drishti Safe Triad.

---

### SLIDE 4: Our Solution — Drishti Architecture
* **Title**: Drishti: End-to-End Explainable Clinical AI Platform
* **3 Core Pillars**:
  1. **Image Quality Gate**: Automated sharpness, illumination, and FOV scoring prevents garbage-in, garbage-out.
  2. **Explainable Deep Learning**: ResNet-18 5-class grading paired with Grad-CAM neural attention heatmaps.
  3. **Human-in-the-Loop Telemedicine**: Dual-persona portal empowering frontline workers while preserving specialist diagnostic authority.
* **Key Visual**: End-to-End architecture flowchart from PHC capture to cloud telemedicine.

---

### SLIDE 5: Safety Gate — Retinal Image Quality Engine
* **Title**: Multi-Factor Image Quality Gating
* **Mathematical Foundations**:
  * **Focus / Blur**: Discrete Laplacian Variance on segmented retinal foreground mask.
  * **Illumination**: Mean intensity, 5th/95th percentiles, and over/underexposure penalty.
  * **Field of View (FOV)**: Otsu contour thresholding to ensure >= 65% retinal coverage.
* **Composite Quality Score**:
  $$\\text{Score} = 0.45 \\times \\text{Sharpness} + 0.35 \\times \\text{Illumination} + 0.20 \\times \\text{FOV}$$
* **Thresholds**: $\\ge 0.70$ (GOOD), $0.45 - 0.69$ (BORDERLINE $\\rightarrow$ CLAHE), $< 0.45$ (UNGRADABLE $\\rightarrow$ Recapture Feedback).
* **Key Visual**: Tri-panel comparison: Sharp Retina (0.88), Blurred Retina (0.32), and Dark Retina (0.24).

---

### SLIDE 6: Computer Vision & Enhancement Pipeline
* **Title**: Adaptive Retinal Preprocessing & Structure Analysis
* **Techniques Implemented**:
  * **Auto-Cropping**: Bounding box extraction removes black background margins.
  * **Green Channel CLAHE**: Contrast Limited Adaptive Histogram Equalization (ClipLimit=0.02, 8x8 tiles) highlights microaneurysms.
  * **Blood Vessel Segmentation**: Inverted green channel morphological top-hat filtering with disc structuring element ($r=8$).
  * **Optic Disc Localization**: Red channel Gaussian centroid estimation ($r=h/14$).
* **Key Visual**: Multi-stage image strip: Raw $\\rightarrow$ Auto-Crop $\\rightarrow$ CLAHE $\\rightarrow$ Vessel Mask $\\rightarrow$ Optic Disc.

---

### SLIDE 7: Deep Learning Architecture — ResNet-18
* **Title**: Deep Learning Backbone & Transfer Learning
* **Architecture Details**:
  * **Backbone**: ResNet-18 fine-tuned on 3,662 APTOS retinal photographs.
  * **Residual Learning**: Skip connections ($F(x) + x$) prevent vanishing gradients.
  * **Classification Head**: Global Average Pooling (512) $\\rightarrow$ Linear Head (5 Logits).
  * **Lightweight Footprint**: 11.2M parameters, 44.8 MB state dict, sub-50ms CPU inference.
* **Key Visual**: ResNet-18 computational graph with residual blocks and target `layer4[1].conv2` highlighted.

---

### SLIDE 8: Model Training & Class Imbalance Strategy
* **Title**: Real APTOS 2019 Training Methodology
* **Optimization Setup**:
  * **Loss Function**: `CrossEntropyLoss` with Inverse-Frequency Class Weights ($W_0=0.41, W_1=1.98, W_2=0.73, W_3=3.80, W_4=2.48$).
  * **Optimizer**: AdamW ($LR=10^{-4}$, Weight Decay=$10^{-2}$).
  * **Scheduler**: `ReduceLROnPlateau` monitoring validation Quadratic Weighted Kappa (QWK).
  * **Augmentation**: RandomHorizontalFlip, RandomRotation ($\pm 15^\circ$), ColorJitter.
* **Key Visual**: Training loss curve & validation QWK trajectory across epochs.

---

### SLIDE 9: Verified Model Performance & Metrics
* **Title**: Rigorous Benchmark Validation (Held-Out Test Set: 549 Images)
* **Measured Results**:
  * **5-Class Accuracy**: **76.87%**
  * **Quadratic Weighted Kappa (QWK)**: **0.870** (Substantial clinical agreement)
  * **Binary Referable Specificity**: **96.62%** (SIH Target: >85% | MET)
  * **Binary Referable Sensitivity**: **82.14%** (SIH Target: >90% | Fully reported & analyzed)
  * **ROC Area Under Curve (AUC)**: **0.980**
* **Key Visual**: Five-class confusion matrix + Referable DR ROC Curve ($AUC = 0.980$).

---

### SLIDE 10: Explainable AI — Grad-CAM Saliency Maps
* **Title**: Explainable AI: Making Deep Learning Clinically Verifiable
* **Mathematical Workflow**:
  $$\\alpha_k^c = \\frac{1}{Z} \\sum_i \\sum_j \\frac{\\partial y^c}{\\partial A_{i,j}^k}, \\quad L_{\\text{Grad-CAM}}^c = \\text{ReLU}\\left(\\sum_k \\alpha_k^c A^k\\right)$$
* **Clinical Utility**:
  * Visualizes whether the neural network focused on perimacular exudates, dot hemorrhages, or vascular arcades.
  * Protects against spurious correlations and builds physician trust.
* **Key Visual**: Side-by-side: Original Fundus vs JET Heatmap vs Dual-Layer Alpha Blend Overlay.

---

### SLIDE 11: Human-in-the-Loop & Clinician Review Queue
* **Title**: Dual-Persona Workflow: AI Assists, Doctor Decides
* **Workflow**:
  1. **Health Worker Mode**: Patient registration, image quality assessment, AI screening, instant bilingual patient report.
  2. **Ophthalmologist Portal**: Priority-sorted review queue, dual-image fundus/Grad-CAM inspection, one-tap validation or override.
  3. **Immutable Audit Trail**: Every clinician action, override note, and timestamp logged to PostgreSQL.
* **Key Visual**: Mobile screenshot of Review Queue + Clinician Validation Screen.

---

### SLIDE 12: Flutter, Supabase & Offline Field Engineering
* **Title**: Field-Ready Rural Mobile & Cloud Infrastructure
* **Technical Stack**:
  * **Frontend**: Flutter Material 3, Riverpod 2.5 reactive state architecture.
  * **Backend & Auth**: Supabase PostgreSQL with Row Level Security (RLS) & JWT authentication.
  * **Storage & Realtime**: Secure fundus image buckets & live WebSocket queue sync.
  * **Offline Sync Queue**: SHA-256 integrity hash verification for disconnected rural clinics.
* **Key Visual**: Flutter reactive state machine + Supabase ER relational diagram.

---

### SLIDE 13: MATLAB & Simulink District-Scale Simulation
* **Title**: District Telemedicine Simulation (120,000 Annual Patients)
* **Discrete-Event Queuing Model**:
  * **Baseline (100% Manual Review)**: Arrival rate $\\lambda = 50$/hr vs capacity $\\mu = 48$/hr $\\rightarrow$ Utilization $\\rho = 104.2\\%$, queue collapse, $>48$ hr wait times.
  * **Drishti AI Triage**: ~72% cleared as routine; specialist review demand drops to $\\lambda = 14$/hr $\\rightarrow$ Utilization $\\rho = 29.2\\%$, wait time $<4.2$ minutes.
* **Key Visual**: Simulink queuing block diagram + Comparative backlog trajectory chart.

---

### SLIDE 14: Innovation, Differentiation & Competitive Edge
* **Title**: Drishti vs Traditional Approaches
* **Comparison Table**:
  | Feature | Basic CNN | Tele-Ophthalmology | **Drishti Platform** |
  | :--- | :---: | :---: | :---: |
  | **Quality Gating** | None | Manual | **Automated Multi-Factor Gate** |
  | **Explainability** | Black Box | Subjective | **Grad-CAM Attention Heatmaps** |
  | **Workflow** | Code Script | Slow / Manual | **Integrated Dual-Persona Mobile App** |
  | **Offline Rural Queue**| None | None | **SHA-256 Idempotent Sync** |
  | **District Modeling**| None | None | **MATLAB/Simulink M/M/c Queuing** |

---

### SLIDE 15: Roadmap, Impact & Conclusion
* **Title**: Scaling Vision: From Hackathon to Healthcare Impact
* **Roadmap**:
  * **V1 (Current)**: 5-Class ResNet-18, Quality Gate, Grad-CAM, Flutter/Supabase, Simulink Model.
  * **V2 (Q4 2026)**: High-resolution patch cropping ($512\\times 512$) to surpass 92% sensitivity; edge-TFLite on-device inference.
  * **V3 (2027)**: Multi-centric clinical trial across 10 rural district Primary Health Centres.
* **Closing Statement**: *"Drishti bridges India's rural healthcare gap by combining clinical intelligence with compassionate human care."*
""")

# =========================================================================
# FILE 04: SPEAKER NOTES & INTERRUPTION DEFENSE
# =========================================================================
write_doc("04_Drishti_SIH_Speaker_Notes.md", """# Drishti (SIH 2026 PS-26038) — SIH 2026 Master Speaker Script & Defense Guide

## General Presentation Guidelines
* **Target Presentation Time**: 6 to 8 minutes (approx. 30–45 seconds per slide).
* **Tone**: Confident, clinical, technically precise, and transparent about real data.

---

### Slide 1: Title (30 Seconds)
* **What to Say**: "Respected judges, we are Team Drishti presenting our solution for Problem Statement 26038: an Explainable AI-Assisted Diabetic Retinopathy Screening and Clinical Decision Support System. Drishti is designed to bring specialist-level retinal triage directly to Primary Health Centres in rural India while maintaining total clinical safety and human oversight."
* **If Judge Interrupts**: "Is this a theoretical concept or a working platform?" $\\rightarrow$ *"It is a fully functioning platform with fine-tuned PyTorch deep learning models, real APTOS 2019 validation, Flutter mobile and web clients, Supabase cloud sync, and MATLAB/Simulink district queuing models."*

---

### Slide 2: The Problem (45 Seconds)
* **What to Say**: "India has over 77 million diabetic patients, yet less than 20,000 ophthalmologists—most of whom practice in tier-1 cities. Diabetic retinopathy develops silently with zero early symptoms. By the time a rural farmer notices blurry vision, irreversible proliferative damage has already occurred. Rural patients cannot travel 100 kilometers for a routine annual screening that takes two minutes."
* **If Judge Interrupts**: "Why can't primary health workers just take photos and send them all to doctors?" $\\rightarrow$ *"That creates a catastrophic bottleneck. Two district ophthalmologists cannot review 120,000 photos a year without their queues overflowing. We prove this mathematically in our Simulink simulation."*

---

### Slide 3: Why Existing AI Solutions Fail (45 Seconds)
* **What to Say**: "Existing AI research fails in rural healthcare for three reasons: First, black-box AI outputs a number without visual proof, so doctors don't trust it. Second, standard models are quality-blind—they accept blurred or underexposed photos and output false negatives. Third, they lack offline capabilities and rural workflow integration. Drishti solves all three."

---

### Slide 5: Quality Gate (45 Seconds)
* **What to Say**: "Our first line of defense is our Image Quality Gate. Before running deep learning, we compute discrete Laplacian variance for sharpness, analyze intensity percentiles for illumination, and apply Otsu thresholding for field-of-view coverage. If an image is ungradable, we block AI inference immediately and give actionable recapture advice to the frontline worker."
* **If Judge Interrupts**: "What if the image is slightly dark?" $\\rightarrow$ *"Borderline images between 0.45 and 0.70 are automatically enhanced using Green-Channel CLAHE before entering the neural network."*

---

### Slide 7 & 8: Deep Learning & Training (60 Seconds)
* **What to Say**: "Our AI engine utilizes ResNet-18 fine-tuned on 3,662 real APTOS retinal images. To combat severe clinical class imbalance where healthy eyes outnumber severe cases 10-to-1, we implemented Inverse-Frequency Class Weighting in CrossEntropyLoss. We optimized using AdamW and selected our best model checkpoint based on Quadratic Weighted Kappa."

---

### Slide 9: Benchmark Validation & Real Data (60 Seconds)
* **What to Say**: "On our held-out test split of 549 images, Drishti achieved a 5-class Quadratic Weighted Kappa of 0.870 and an overall accuracy of 76.87%. For binary referable triage, our Specificity reached 96.62% with an ROC AUC of 0.980. Our measured Sensitivity is 82.14%. We report this with complete scientific honesty—most errors were adjacent Grade 1 versus Grade 2 distinctions, which our mandatory human-in-the-loop review safely captures."
* **If Judge Interrupts**: "Why is Sensitivity 82.14% when SIH asks for 90%?" $\\rightarrow$ *"Because downsampling to 224x224 smooths subtle microaneurysms. We refuse to fabricate synthetic 95% numbers. Our V2 architecture introduces 512x512 patch cropping to bridge this gap, while our human review queue ensures no referable case is cleared without doctor oversight."*

---

### Slide 10: Explainable AI & Grad-CAM (45 Seconds)
* **What to Say**: "Drishti incorporates Grad-CAM from layer4 of ResNet-18. It computes the gradients of the predicted class score with respect to convolutional feature maps, creating a multi-layer attention overlay. The ophthalmologist can visually verify that the model triggered on perimacular exudates and hemorrhages rather than background artifacts."

---

### Slide 11 & 12: Dual Persona & Cloud Architecture (45 Seconds)
* **What to Say**: "Our Flutter application provides role-based interfaces for Health Workers and Ophthalmologists. Data synchronizes in real time with Supabase PostgreSQL and secure storage. For disconnected clinics, an offline queue caches encrypted screenings with SHA-256 integrity hashes, auto-syncing when cell network returns."

---

### Slide 13: Simulink District Queuing (45 Seconds)
* **What to Say**: "In MATLAB and Simulink, we modeled an annual district workload of 120,000 patients. In a baseline manual system, doctor utilization hits 104%, causing infinite queue backlog. Drishti's automated triage clears 72% of healthy patients, dropping specialist utilization to 29.2% and reducing review delays from 48 hours to under 5 minutes."

---

### Slide 15: Conclusion (30 Seconds)
* **What to Say**: "Drishti is not just another CNN classifier—it is a complete, explainable, safety-gated, and district-scalable clinical decision support system ready for rural deployment. Thank you, and we welcome your questions."
""")

print("Presentation content and speaker notes generated successfully.")
