# Drishti (SIH 2026 PS-26038) — SIH 2026 Technical Judge Question Bank & Defense Guide

This document provides answers to 100 anticipated technical, clinical, AI, and deployment questions from Smart India Hackathon (SIH 2026) judges.

---

## Category 1: Problem Statement & Clinical Relevance

### Q1: Why is Diabetic Retinopathy screening needed at the primary healthcare level in India?
* **30-Second Answer**: Over 77 million Indians live with diabetes. Diabetic Retinopathy (DR) is asymptomatic in its early treatable stages, leading to irreversible blindness if undetected. India has only ~20,000 ophthalmologists, mostly concentrated in urban centers, making annual physical screening for rural patients physically impossible without automated AI triage.
* **Deep Technical Defense**: The International Council of Ophthalmology mandates annual fundus examinations for all diabetic patients. With an ophthalmologist-to-population ratio of 1:100,000 in rural districts, the primary care system suffers from a severe throughput bottleneck. Drishti deploys deep learning to Primary Health Centres (PHCs), triaging ~72% of healthy/non-referable cases automatically while channeling high-risk patients to district specialists.

### Q2: What is the clinical difference between Non-Referable and Referable DR?
* **30-Second Answer**: Non-referable DR comprises Level 0 (No DR) and Level 1 (Mild NPDR with isolated microaneurysms only), requiring routine annual monitoring. Referable DR comprises Level 2 (Moderate NPDR), Level 3 (Severe NPDR), and Level 4 (Proliferative DR), requiring specialist intervention to prevent vision loss.
* **Deep Technical Defense**: In the ICDR 5-scale grading, Level 2 introduces hard exudates, cotton wool spots, and blot hemorrhages indicating vascular permeability; Level 3 follows the 4-2-1 rule with severe hemorrhages in 4 quadrants; Level 4 features neovascularization prone to vitreous hemorrhage and retinal detachment. Triage at Level >= 2 ensures patients with sight-threatening lesions receive priority laser photocoagulation or anti-VEGF therapy.

### Q3: Why is black-box AI unacceptable in clinical ophthalmology?
* **30-Second Answer**: Physicians cannot legally or ethically act on an uninterpretable probability number without verifying anatomical evidence. Black-box AI risks missing atypical lesions or hallucinations caused by camera artifacts.
* **Deep Technical Defense**: Deep learning classifiers can latch onto spurious imaging artifacts (e.g., lens dust, illumination gradients). Drishti couples ResNet-18 classifications with Grad-CAM neural attention heatmaps extracted from `layer4[1].conv2`, allowing the reviewing clinician to immediately verify whether the model is focusing on pathological lesions (e.g., macular exudates, hemorrhages) rather than background noise.

---

## Category 2: Image Quality Gating Engine

### Q4: How do you mathematically assess whether a fundus image is blurred?
* **30-Second Answer**: We calculate the variance of the discrete Laplacian operator on the segmented retinal foreground mask. Sharp images have rich high-frequency edges yielding high Laplacian variance, while blurred images smooth out gradients and produce low variance.
* **Deep Technical Defense**:
  $$\\nabla^2 I(x, y) = \\frac{\\partial^2 I}{\\partial x^2} + \\frac{\\partial^2 I}{\\partial y^2}$$
  Discretized using a $3 \\times 3$ kernel $[[0, 1, 0], [1, -4, 1], [0, 1, 0]]$. The variance $\\sigma^2_{\\nabla^2 I}$ is evaluated exclusively over pixels where the binary retinal mask $M(x,y) = 1$. The normalized score is computed via $S_{\\text{sharp}} = \\min(1.0, \\sigma^2 / 500.0)$.

### Q5: What happens when an image is marked UNGRADABLE?
* **30-Second Answer**: Drishti immediately blocks automated AI inference, prevents false reassurance, and displays actionable recapture instructions to the health worker (e.g., "Patient moved — steady camera and recapture under dark illumination").
* **Deep Technical Defense**: In standard clinical AI deployments, passing a blurred or dark image through a CNN causes the softmax head to output a low-confidence false negative (Level 0). Drishti enforces a hard quality gate (Composite Score $< 0.45$). The API rejects analysis with HTTP `422 Unprocessable Entity`, mandating physical recapture before any screening record is committed.

### Q6: What are the weights in the Composite Quality Score formula?
* **30-Second Answer**: $45\\%$ Sharpness (Focus), $35\\%$ Illumination (Exposure & Uniformity), and $20\\%$ Field of View (Retinal Coverage).
* **Deep Technical Defense**: Focus is weighted highest ($w_1 = 0.45$) because microaneurysms ($< 50 \\mu m$) vanish under blur. Illumination is weighted $w_2 = 0.35$ to penalize underexposure ($< 15$ mean gray level) and overexposure saturation. FOV is weighted $w_3 = 0.20$ to ensure at least $65\\%$ of the sensor area contains retinal tissue without severe edge clipping.

---

## Category 3: Deep Learning Architecture & Training

### Q7: Why did you choose ResNet-18 over larger models like ResNet-50 or ViT?
* **30-Second Answer**: ResNet-18 has 11.2M parameters and executes inference in under 45ms on edge CPUs without requiring expensive GPUs, making it ideal for rural PHC tablets and low-power clinics.
* **Deep Technical Defense**: Larger architectures like Vision Transformers (ViT) or ResNet-152 require massive training datasets to avoid overfitting and suffer high inference latency ($> 500$ms on CPU). ResNet-18 provides residual skip connections ($F(x) + x$) that eliminate vanishing gradients while maintaining a compact memory footprint (44.8 MB state dict) suitable for on-device and edge microservice deployments.

### Q8: How did you address extreme class imbalance in the APTOS dataset?
* **30-Second Answer**: We implemented Normalized Inverse-Frequency Class Weighting in our PyTorch `CrossEntropyLoss` function, heavily penalizing misclassifications on rare severe stages (Levels 3 and 4).
* **Deep Technical Defense**: In the 3,662-image APTOS dataset, Level 0 represents $49.3\\%$ ($n=1805$) while Level 3 represents only $5.3\\%$ ($n=193$). Without weighting, a CNN maximizes naive accuracy by predicting majority classes. We computed weights $W_c = N_{\\text{total}} / (5 \\times N_c)$, giving Level 3 a normalized loss weight of $3.797$ compared to $0.406$ for Level 0, forcing the gradient optimizer to prioritize minority pathological features.

### Q9: What is your primary checkpoint selection metric during training?
* **30-Second Answer**: Quadratic Weighted Kappa (QWK) on the validation set, not raw accuracy.
* **Deep Technical Defense**: In medical ordinal grading, misclassifying a Level 4 (Proliferative DR) as Level 0 is a catastrophic clinical failure, whereas misclassifying Level 1 as Level 2 is an adjacent-grade ambiguity. QWK squares the penalty distance $|i - j|^2$ between true class $i$ and predicted class $j$:
  $$\\kappa = 1 - \\frac{\\sum_{i,j} w_{i,j} O_{i,j}}{\\sum_{i,j} w_{i,j} E_{i,j}}, \\quad w_{i,j} = \\frac{(i - j)^2}{(K - 1)^2}$$
  Our model achieved a verified test QWK of **0.870**, demonstrating substantial inter-rater clinical alignment.

---

## Category 4: Validation Results & Honest Metrics

### Q10: What are your actual measured test results on the APTOS dataset?
* **30-Second Answer**: On our held-out test split of 549 images, Drishti achieved 5-Class Accuracy of **76.87%**, QWK of **0.870**, Referable DR Specificity of **96.62%**, Referable DR Sensitivity of **82.14%**, and an ROC AUC of **0.980**.
* **Deep Technical Defense**: We evaluated the model exactly once on a 15% held-out test partition (549 samples) with zero data leakage. While Specificity exceeded the SIH target ($96.62\\%$ vs $>85\\%$), Sensitivity was $82.14\\%$ (SIH target $>90\\%$), resulting in 40 false negatives out of 224 referable cases. We report this transparently as `REAL_APTOS_VALIDATED_BELOW_SIH_TARGET` and mitigate it through our mandatory Human-in-the-Loop review protocol.

### Q11: Why did Sensitivity fall below the SIH 90% target?
* **30-Second Answer**: Subtle microaneurysms in early Level 2 cases can be missed at 224x224 input resolution, occasionally causing borderline Level 2 cases to be graded as Level 1.
* **Deep Technical Defense**: 36 of the 40 false negatives were Level 2 cases predicted as Level 1. In retinal fundus imaging, the boundary between Mild (Level 1) and Moderate (Level 2) NPDR often hinges on detecting single isolated blot hemorrhages that get smoothed out during $224 \\times 224$ downsampling. Future iterations (V2) will incorporate high-resolution patch-based cropping ($512 \\times 512$) to achieve $>92\\%$ sensitivity.

---

## Category 5: Explainability & Grad-CAM

### Q12: How does Grad-CAM compute attention heatmaps?
* **30-Second Answer**: It computes the gradients of the predicted class score with respect to the final convolutional feature maps (`layer4[1].conv2`), global-average-pools them into importance weights, and performs a weighted sum filtered by ReLU.
* **Deep Technical Defense**:
  $$\\alpha_k^c = \\frac{1}{Z} \\sum_{i} \\sum_{j} \\frac{\\partial y^c}{\\partial A_{i,j}^k}$$
  $$L_{\\text{Grad-CAM}}^c = \\text{ReLU}\\left(\\sum_k \\alpha_k^c A^k\\right)$$
  The resulting $7 \\times 7$ activation map is upsampled via bilinear interpolation to $224 \\times 224$, normalized $[0, 1]$, color-mapped with JET palette, and alpha-blended over the fundus photo at $\\alpha = 0.45$.

### Q13: Can Grad-CAM replace an ophthalmologist's lesion diagnosis?
* **30-Second Answer**: No. Grad-CAM is an interpretability tool showing neural attention, not a verified segmentation of microaneurysms or neovascularization.
* **Deep Technical Defense**: Grad-CAM visualizes coarse receptive fields ($32 \\times 32$ effective pixel patches) that contributed most to the tensor score. It provides spatial verification to assist clinicians in spotting pathological sectors (e.g., superior temporal arcade vs fovea), but diagnostic confirmation remains the sole prerogative of the licensed medical practitioner.

---

## Category 6: Full System & District Scaling

### Q14: How does MATLAB/Simulink prove scalability for 100,000+ annual patients?
* **30-Second Answer**: We built an M/M/c discrete-event queuing simulation modeling a district with 120,000 annual diabetic screenings across 300 working days.
* **Deep Technical Defense**: At 50 patient arrivals per hour ($\\lambda = 50$), a baseline manual system with 2 district ophthalmologists ($\\mu = 48$ cases/hr) suffers a utilization $\\rho = 104.2\\%$, causing an infinite backlog and $>48$-hour waiting queues. With Drishti, automated AI triage clears $\\sim 72\\%$ non-referable cases, reducing clinician arrival rate to $\\lambda_{\\text{doc}} = 14$ cases/hr ($\\rho = 29.2\\%$). Average review wait times drop to under $4.2$ minutes.

### Q15: What prevents data loss in remote rural areas without internet?
* **30-Second Answer**: Drishti's Flutter client includes an offline synchronization queue that stores encrypted screening payloads with SHA-256 integrity hashes locally in SQLite, automatically syncing with Supabase when connectivity returns.
* **Deep Technical Defense**: The app generates deterministic client UUIDs (`EX-YYYY-XXXXXX`) using RFC4122 v4. When network pings fail, screenings are saved to local persistent storage. Upon reconnection, an asynchronous background sync worker pushes payloads sequentially with idempotency headers, preventing duplicate cloud records even across intermittent cellular drops.
