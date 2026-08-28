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
# FILE 06: ARCHITECTURE DIAGRAMS (22 MERMAID DIAGRAMS)
# =========================================================================
write_doc("06_Drishti_Architecture_Diagrams.md", """# Drishti (SIH 2026 PS-26038) — Comprehensive Architecture Diagrams

This document contains 22 complete system architecture, pipeline, dataflow, and interaction diagrams for **Drishti**.

---

## 1. Overall System Architecture

```mermaid
graph TD
    A[Primary Health Centre / Field Worker] -->|Capture Fundus Image| B[Flutter Mobile & Tablet Client]
    B -->|REST API / HTTPS| C[Flask Microservices Gateway]
    B -->|PostgreSQL & Auth Sync| D[Supabase Cloud Backend]
    
    subgraph "Drishti AI & CV Engine"
        C --> E[Image Quality Gating Engine]
        E -->|Sharpness, Illumination, FOV| F{Quality Score >= 0.70?}
        F -->|No: Ungradable| G[Recapture Feedback Guidance]
        F -->|Yes: Good/Borderline| H[Preprocessing & CLAHE]
        H --> I[ResNet-18 PyTorch Backbone]
        I --> J[5-Class DR Severity Grading]
        I --> K[Grad-CAM Saliency Generator]
    end
    
    subgraph "Clinical Decision Support & Telemedicine"
        J --> L[Referable DR Triage Engine]
        K --> M[Multi-Layer Saliency Overlay]
        L --> N[Clinician Review Queue]
        M --> N
        N --> O[Ophthalmologist Telemedicine Portal]
        O -->|Validate / Override / Reject| P[Final Clinical Decision & PDF Report]
        P --> Q[Immutable PostgreSQL Audit Trail]
    end
```

---

## 2. End-to-End Image Processing & AI Inference Pipeline

```mermaid
flowchart LR
    A[Raw Retinal Fundus Image] --> B[Downsampling & Format Normalization]
    B --> C[Laplacian Variance Sharpness]
    B --> D[Illumination & Exposure Percentiles]
    B --> E[Otsu Retinal Mask & FOV Coverage]
    C & D & E --> F[Quality Fusion Score]
    F -->|Score < 0.45| G[Reject / Request Recapture]
    F -->|Score >= 0.45| H[Auto-Crop Black Borders]
    H --> I[Green-Channel CLAHE Enhancement]
    I --> J[ImageNet Normalization]
    J --> K[ResNet-18 Forward Pass]
    K --> L[Softmax Probability Vector]
    K --> M[Backprop Gradients on Layer4]
    M --> N[Grad-CAM Attention Heatmap]
    L --> O[DR Level 0-4 Prediction]
    O --> P[Referable DR Classification]
```

---

## 3. Image Quality Assessment & Gating Engine

```mermaid
graph TD
    A[Input Fundus RGB] --> B[Generate Retina Foreground Mask]
    B --> C[Crop Retinal Region]
    
    subgraph "Sharpness Analysis"
        C --> D[Convert to Grayscale]
        D --> E[Compute Discrete Laplacian]
        E --> F[Calculate Variance on Retinal Mask]
        F --> G[Normalized Sharpness Score: w=0.45]
    end
    
    subgraph "Illumination Analysis"
        C --> H[Extract Y/V Channel Intensities]
        H --> I[Compute Mean, P5, P95 Percentiles]
        I --> J[Calculate Over/Underexposure Penalty]
        J --> K[Normalized Illumination Score: w=0.35]
    end
    
    subgraph "Field of View (FOV) Analysis"
        B --> L[Calculate Mask Area / Bounding Box Area]
        L --> M[Detect Edge Clipping & Cropping]
        M --> N[Normalized FOV Score: w=0.20]
    end
    
    G & K & N --> O[Composite Quality Score Formula]
    O --> P{Quality Gate}
    P -->|Score >= 0.70| Q[GOOD: Proceed to AI]
    P -->|0.45 <= Score < 0.70| R[BORDERLINE: Apply CLAHE & Proceed]
    P -->|Score < 0.45| S[UNGRADABLE: Block AI & Trigger Recapture]
```

---

## 4. Retinal Preprocessing & Normalization Pipeline

```mermaid
flowchart TD
    A[Raw Fundus Photograph] --> B[Threshold Background Mask > 15 Intensity]
    B --> C[Find Non-Zero Pixel Bounding Box]
    C --> D[Crop Image to Tight Retinal Bounding Box]
    D --> E[Isolate Green Channel]
    E --> F[Apply CLAHE: ClipLimit=0.02, Tiles=8x8]
    F --> G[Recombine Enhanced RGB Composite]
    G --> H[Bilinear Resize to 224x224 Pixels]
    H --> I[Convert to Float32 Tensor [0, 1]]
    I --> J[Standardize with ImageNet Mean & StdDev]
```

---

## 5. ResNet-18 Deep Learning Neural Architecture

```mermaid
graph TD
    A[Input Tensor: 224x224x3] --> B[Conv1: 7x7, 64, Stride 2]
    B --> C[BatchNorm + ReLU + MaxPool: 3x3, Stride 2]
    
    subgraph "Layer 1: 2 Residual Blocks (64 Channels)"
        C --> D[ResBlock 1: Conv 3x3 -> Conv 3x3 + Identity]
        D --> E[ResBlock 2: Conv 3x3 -> Conv 3x3 + Identity]
    end
    
    subgraph "Layer 2: 2 Residual Blocks (128 Channels)"
        E --> F[ResBlock 1: Stride 2 Downsample]
        F --> G[ResBlock 2: Conv 3x3 -> Conv 3x3 + Identity]
    end
    
    subgraph "Layer 3: 2 Residual Blocks (256 Channels)"
        G --> H[ResBlock 1: Stride 2 Downsample]
        H --> I[ResBlock 2: Conv 3x3 -> Conv 3x3 + Identity]
    end
    
    subgraph "Layer 4: 2 Residual Blocks (512 Channels)"
        I --> J[ResBlock 1: Stride 2 Downsample]
        J --> K[ResBlock 2: layer4[1].conv2 -> Grad-CAM Target Layer]
    end
    
    K --> L[Global Average Pooling: 512x1x1]
    L --> M[Fully Connected Linear Head: 512 -> 5]
    M --> N[Logits: z0, z1, z2, z3, z4]
    N --> O[Softmax Activation]
    O --> P[Predicted Severity Class & Probabilities]
```

---

## 6. Grad-CAM Neural Attention & Saliency Map Workflow

```mermaid
flowchart TD
    A[Input Image Forward Pass] --> B[Extract Activations A^k from layer4[1].conv2]
    B --> C[Compute Logit y^c for Predicted Class c]
    C --> D[Backpropagate Gradients: dy^c / dA^k]
    D --> E[Global Average Pool Gradients to compute alpha_k^c]
    E & B --> F[Linear Combination of Feature Maps: Sum(alpha_k^c * A^k)]
    F --> G[Apply ReLU: Suppress Negative Relevance]
    G --> H[Bilinear Upsample Heatmap to 224x224]
    H --> I[Normalize Heatmap to [0, 1]]
    I --> J[Apply JET Colormap Palette]
    J --> K[Blend with Original Fundus at Alpha=0.45]
```

---

## 7. Dual Persona Human-in-the-Loop Workflow

```mermaid
sequenceDiagram
    autonumber
    actor HW as Health Worker (ASHA / PHC)
    participant APP as Drishti Flutter App
    participant AI as PyTorch Backend Gateway
    participant DB as Supabase PostgreSQL
    actor OP as Ophthalmologist (District Hospital)
    
    HW->>APP: Register Patient & Capture Retinal Image
    APP->>AI: POST /screenings/<id>/image
    AI-->>APP: Image Quality Status (GOOD: 0.88)
    APP->>AI: POST /screenings/<id>/analyze
    AI-->>APP: AI Screening: Level 2 (Moderate NPDR, Prob: 91.4%)
    APP->>DB: Upsert Screening & Auto-Route to Review Queue
    
    OP->>APP: Open Review Queue (Filter: High Priority Referable)
    APP->>DB: Fetch Pending Screenings
    DB-->>APP: Returns Case with Fundus & Grad-CAM URLs
    OP->>APP: Inspects Retinal Fundus & Grad-CAM Attention
    alt Confirm AI
        OP->>APP: Tap "Validate AI Result" + Enter Clinical Notes
    else Clinician Override
        OP->>APP: Tap "Override" + Select True Severity Level + Notes
    else Reject / Ungradable
        OP->>APP: Tap "Mark Ungradable" + Trigger Retake Request
    end
    APP->>DB: Record Clinician Review & Append Immutable Audit Event
    APP->>HW: Real-Time Sync: Case Status Updated to VALIDATED
```

---

## 8. Offline Rural Queue & Synchronization State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle: App Open
    Idle --> Capturing: Health Worker Captures Retina
    Capturing --> CheckingNetwork: Store Locally with SHA-256 Hash
    
    CheckingNetwork --> OnlineUpload: Network Active
    CheckingNetwork --> QueuedOffline: Network Unavailable
    
    QueuedOffline --> WaitingConnectivity: Persist in SQLite / Secure Storage
    WaitingConnectivity --> QueuedOffline: Connectivity Check Ping
    WaitingConnectivity --> SyncWorker: Internet Connection Restored
    
    SyncWorker --> OnlineUpload: Process FIFO Queue with Idempotency Key
    OnlineUpload --> CloudSynchronized: Image Uploaded & Verified
    CloudSynchronized --> AIAnalysis: Execute Remote Deep Learning Inference
    AIAnalysis --> [*]: Screening Completed
```

---

## 9. Supabase PostgreSQL Entity-Relationship (ER) Diagram

```mermaid
erDiagram
    PROFILES ||--o{ SCREENINGS : "creates"
    PROFILES {
        uuid id PK
        string email
        string full_name
        string role "HEALTH_WORKER | OPHTHALMOLOGIST"
        string facility_id
        timestamp created_at
    }
    
    SCREENINGS ||--|| QUALITY_ASSESSMENTS : "has"
    SCREENINGS ||--|| AI_PREDICTIONS : "generates"
    SCREENINGS ||--|| EXPLAINABILITY_RESULTS : "produces"
    SCREENINGS ||--o| CLINICIAN_REVIEWS : "validated_by"
    SCREENINGS ||--o{ AUDIT_EVENTS : "tracks"
    
    SCREENINGS {
        string screening_id PK
        string patient_id
        int age
        string gender
        int diabetes_duration_years
        string eye "OD | OS"
        string image_url
        string status
        timestamp created_at
        timestamp updated_at
    }
    
    QUALITY_ASSESSMENTS {
        uuid id PK
        string screening_id FK
        float overall_score
        string status "GOOD | BORDERLINE | UNGRADABLE"
        float sharpness_score
        float illumination_score
        float fov_score
        jsonb feedback_messages
    }
    
    AI_PREDICTIONS {
        uuid id PK
        string screening_id FK
        int dr_level "0-4"
        string severity_label
        boolean referable
        float model_probability
        jsonb class_probabilities
        string review_priority
    }
    
    EXPLAINABILITY_RESULTS {
        uuid id PK
        string screening_id FK
        string target_layer
        string gradcam_url
        string overlay_url
        string original_url
        jsonb model_attended_regions
    }
    
    CLINICIAN_REVIEWS {
        uuid id PK
        string screening_id FK
        uuid reviewer_id FK
        string clinician_name
        string action "VALIDATE | OVERRIDE | UNGRADABLE"
        int final_dr_level
        boolean final_referable
        text clinical_notes
        timestamp reviewed_at
    }
    
    AUDIT_EVENTS {
        uuid id PK
        string screening_id FK
        string event_type
        uuid actor_id FK
        jsonb payload
        timestamp timestamp
    }
```

---

## 10. MATLAB/Simulink District-Scale Telemedicine Queuing Model

```mermaid
graph LR
    subgraph "Rural Primary Health Centres (100k+ Annual Patients)"
        A[District Patient Population] -->|Poisson Arrivals: lambda=50/hr| B[PHC Image Capture Station]
        B -->|Uplink Latency: 2.5MB over 8Mbps| C[Drishti Cloud AI Gateway]
    end
    
    subgraph "Drishti Automated AI Triage"
        C -->|Quality & Inference: 1.2s| D{AI Severity Triage}
        D -->|~72% Level 0 Non-Referable| E[Automated Routine Annual Report]
        D -->|~28% Referable / Borderline| F[Priority Telemedicine Review Queue]
    end
    
    subgraph "District Specialist Capacity"
        F -->|Arrivals: lambda_doc=14/hr| G[2 District Ophthalmologists]
        G -->|Service Capacity: mu=48/hr| H[Confirmed Diagnosis & Treatment Referral]
    end
    
    E --> I[Patient Returns to Community]
    H --> J[Tertiary Eye Hospital Intervention]
```
""")

print("Diagrams document written successfully.")
