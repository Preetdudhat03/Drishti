# Drishti (SIH 2026 PS-26038) — SIH 2026 Master Speaker Script & Defense Guide

## General Presentation Guidelines
* **Target Presentation Time**: 6 to 8 minutes (approx. 30–45 seconds per slide).
* **Tone**: Confident, clinical, technically precise, and transparent about real data.

---

### Slide 1: Title (30 Seconds)
* **What to Say**: "Respected judges, we are Team Drishti presenting our solution for Problem Statement 26038: an Explainable AI-Assisted Diabetic Retinopathy Screening and Clinical Decision Support System. Drishti is designed to bring specialist-level retinal triage directly to Primary Health Centres in rural India while maintaining total clinical safety and human oversight."
* **If Judge Interrupts**: "Is this a theoretical concept or a working platform?" $\rightarrow$ *"It is a fully functioning platform with fine-tuned PyTorch deep learning models, real APTOS 2019 validation, Flutter mobile and web clients, Supabase cloud sync, and MATLAB/Simulink district queuing models."*

---

### Slide 2: The Problem (45 Seconds)
* **What to Say**: "India has over 77 million diabetic patients, yet less than 20,000 ophthalmologists—most of whom practice in tier-1 cities. Diabetic retinopathy develops silently with zero early symptoms. By the time a rural farmer notices blurry vision, irreversible proliferative damage has already occurred. Rural patients cannot travel 100 kilometers for a routine annual screening that takes two minutes."
* **If Judge Interrupts**: "Why can't primary health workers just take photos and send them all to doctors?" $\rightarrow$ *"That creates a catastrophic bottleneck. Two district ophthalmologists cannot review 120,000 photos a year without their queues overflowing. We prove this mathematically in our Simulink simulation."*

---

### Slide 3: Why Existing AI Solutions Fail (45 Seconds)
* **What to Say**: "Existing AI research fails in rural healthcare for three reasons: First, black-box AI outputs a number without visual proof, so doctors don't trust it. Second, standard models are quality-blind—they accept blurred or underexposed photos and output false negatives. Third, they lack offline capabilities and rural workflow integration. Drishti solves all three."

---

### Slide 5: Quality Gate (45 Seconds)
* **What to Say**: "Our first line of defense is our Image Quality Gate. Before running deep learning, we compute discrete Laplacian variance for sharpness, analyze intensity percentiles for illumination, and apply Otsu thresholding for field-of-view coverage. If an image is ungradable, we block AI inference immediately and give actionable recapture advice to the frontline worker."
* **If Judge Interrupts**: "What if the image is slightly dark?" $\rightarrow$ *"Borderline images between 0.45 and 0.70 are automatically enhanced using Green-Channel CLAHE before entering the neural network."*

---

### Slide 7 & 8: Deep Learning & Training (60 Seconds)
* **What to Say**: "Our AI engine utilizes ResNet-18 fine-tuned on 3,662 real APTOS retinal images. To combat severe clinical class imbalance where healthy eyes outnumber severe cases 10-to-1, we implemented Inverse-Frequency Class Weighting in CrossEntropyLoss. We optimized using AdamW and selected our best model checkpoint based on Quadratic Weighted Kappa."

---

### Slide 9: Benchmark Validation & Real Data (60 Seconds)
* **What to Say**: "On our held-out test split of 549 images, Drishti achieved a 5-class Quadratic Weighted Kappa of 0.870 and an overall accuracy of 76.87%. For binary referable triage, our Specificity reached 96.62% with an ROC AUC of 0.980. Our measured Sensitivity is 82.14%. We report this with complete scientific honesty—most errors were adjacent Grade 1 versus Grade 2 distinctions, which our mandatory human-in-the-loop review safely captures."
* **If Judge Interrupts**: "Why is Sensitivity 82.14% when SIH asks for 90%?" $\rightarrow$ *"Because downsampling to 224x224 smooths subtle microaneurysms. We refuse to fabricate synthetic 95% numbers. Our V2 architecture introduces 512x512 patch cropping to bridge this gap, while our human review queue ensures no referable case is cleared without doctor oversight."*

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
