# EyeXpert API Contract Specification (v1.0 — Production Ready)
**SIH 2026 Problem Statement 26038 | Explainable AI for Diabetic Retinopathy Screening**

This document specifies the standard REST/JSON interface between the **EyeXpert Flutter Client** (Field Screening & Clinician Review app) and the **EyeXpert AI Backend** (Python/PyTorch/MATLAB Engine).

---

## 1. Global Standard Conventions & Security

- **Base URLs**:
  - Development: `http://localhost:5000/api/v1`
  - Production: `https://<production-api-domain>/v1`
- **Authentication**: `Authorization: Bearer <jwt_token>` (Identity and roles derived server-side from claims).
- **Idempotency**: All mutating operations support `Idempotency-Key: <client_request_id>` header.
- **Data Minimization & Privacy**: Logs, analytics, and crash reports strictly use `screening_id` and `image_id`. Personal identifiers are never logged.
- **Time Format**: ISO 8601 UTC (`YYYY-MM-DDTHH:mm:ssZ`).

---

## 2. Standard Error Schema

All endpoints return uniform error structures:

```json
{
  "error": {
    "code": "IMAGE_UNGRADABLE",
    "message": "The submitted image does not meet clinical diagnostic quality thresholds. Automated screening is blocked.",
    "request_id": "REQ-20260828-00123",
    "retryable": false,
    "details": {
      "focus": "POOR",
      "sharpness_score": 0.18,
      "recommended_action": "RECAPTURE_REQUIRED"
    }
  }
}
```

### Standard Error Codes
- `IMAGE_UNGRADABLE`: Quality gate failed; `/analyze` rejected server-side.
- `MODEL_UNAVAILABLE`: AI engine offline or unreachable.
- `INVALID_CREDENTIALS`: Authentication failure.
- `UNAUTHORIZED`: Insufficient role permissions.
- `INVALID_IMAGE_PAYLOAD`: Malformed or corrupted image file.
- `RESOURCE_NOT_FOUND`: Screening ID or Case ID not found.
- `IDEMPOTENCY_CONFLICT`: Concurrent request with same idempotency key in progress.

---

## 3. Screening State Lifecycle Machine

```text
       CREATED
          │
          ▼
   AWAITING_IMAGE
          │
          ▼
    IMAGE_RECEIVED
          │
          ▼
  QUALITY_ASSESSMENT ───────────► UNGRADABLE ──► RECAPTURE_REQUIRED
          │
    ┌─────┴────────────────┐
    ▼                      ▼
  GOOD                BORDERLINE
    │                      │
    │             BORDERLINE_ENHANCEMENT (Adaptive CLAHE)
    │                      │
    └──────────┬───────────┘
               ▼
         AI_PROCESSING (ResNet-18 Inference + Grad-CAM)
               │
               ▼
        READY_FOR_REVIEW
               │
               ▼
   PENDING_CLINICIAN_REVIEW
               │
    ┌──────────┴───────────┐
    ▼                      ▼
CLINICIAN_VALIDATED   CLINICIAN_OVERRIDDEN
    │                      │
    └──────────┬───────────┘
               ▼
           COMPLETED
```

---

## 4. Endpoints & Schemas

### 4.1. Authentication & Session

#### `POST /auth/login`
**Request**:
```json
{
  "username": "demo-healthworker",
  "password": "<provided securely>",
  "role_requested": "HEALTH_WORKER"
}
```

**Response (200 OK)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2026-08-29T12:00:00Z",
  "user": {
    "id": "HW-DEMO-001",
    "name": "Sunita Sharma",
    "role": "HEALTH_WORKER",
    "organization": "Demo Primary Health Centre",
    "is_demo_account": true
  }
}
```

---

### 4.2. Screening Session Lifecycle

#### `POST /screenings`
Creates a new screening session.

**Headers**:
- `Idempotency-Key`: `LOCAL-REQ-20260828-001`

**Request**:
```json
{
  "client_request_id": "LOCAL-REQ-20260828-001",
  "patient_id": "PT-2026-8819",
  "age": 54,
  "gender": "FEMALE",
  "diabetes_duration_years": 8,
  "eye": "OD",
  "facility_id": "PHC-DEMO-01",
  "created_at": "2026-08-28T10:30:00Z"
}
```

**Response (201 Created)**:
```json
{
  "screening_id": "EX-2026-000124",
  "client_request_id": "LOCAL-REQ-20260828-001",
  "patient_id": "PT-2026-8819",
  "eye": "OD",
  "status": "AWAITING_IMAGE",
  "created_at": "2026-08-28T10:30:00Z"
}
```

---

### 4.3. Fundus Image Upload & Quality Assessment

#### `POST /screenings/{screening_id}/image`
Multipart form upload of fundus photograph with client SHA-256 checksum for integrity.

**Headers**:
- `Idempotency-Key`: `IMG-REQ-20260828-001`

**Form-Data Request**:
- `image`: Binary image file (JPEG/PNG)
- `sha256`: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- `capture_device_model`: `Portable Handheld Fundus Camera v2`

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "image_id": "IMG-2026-0828-0912",
  "image_url": "/api/v1/images/IMG-2026-0828-0912.jpg",
  "thumbnail_url": "/api/v1/images/IMG-2026-0828-0912_thumb.jpg",
  "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "status": "IMAGE_RECEIVED",
  "uploaded_at": "2026-08-28T10:31:12Z"
}
```

#### `GET /screenings/{screening_id}/quality`
Evaluates focus, exposure, and field of view before executing deep neural screening.

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "overall_score": 0.88,
  "status": "GOOD",
  "sharpness": {
    "score": 0.89,
    "status": "GOOD",
    "metric": "Laplacian variance"
  },
  "illumination": {
    "score": 0.86,
    "status": "GOOD",
    "metric": "Histogram distribution"
  },
  "field_of_view": {
    "score": 0.90,
    "status": "ADEQUATE",
    "metric": "Retinal mask coverage"
  },
  "enhancement_applied": false,
  "feedback_messages": [
    "Image quality is optimal for automated DR screening."
  ],
  "evaluated_at": "2026-08-28T10:31:15Z"
}
```

*Server Authoritative Quality Enforcement*:
- If status is `UNGRADABLE`, any subsequent call to `/analyze` returns `400 Bad Request` with `IMAGE_UNGRADABLE`.

---

### 4.4. AI Screening & DR Classification

#### `POST /screenings/{screening_id}/analyze`
Triggers server-side AI inference on the preprocessed/enhanced fundus image.

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "status": "READY_FOR_REVIEW",
  "prediction": {
    "dr_level": 2,
    "severity_label": "Moderate Non-Proliferative Diabetic Retinopathy",
    "severity_code": "MODERATE_NPDR",
    "referable": true,
    "referable_threshold": "Level >= 2",
    "model_probability": 0.914,
    "calibrated_confidence": null,
    "class_probabilities": {
      "0": 0.021,
      "1": 0.037,
      "2": 0.892,
      "3": 0.041,
      "4": 0.009
    },
    "review_priority": "HIGH",
    "recommendation": "Ophthalmologist review and dilated fundus examination recommended."
  },
  "model_provenance": {
    "model_id": "eyexpert-dr-resnet18",
    "model_name": "EyeXpert DR Classifier",
    "architecture": "ResNet-18 (Transfer Learning)",
    "training_dataset": "APTOS 2019 Blindness Detection",
    "model_version": "v1.2.0",
    "preprocessing_version": "preprocess-v1.1",
    "calibration_version": null,
    "validation_benchmark": {
      "dataset": "APTOS 2019",
      "evaluation_type": "Held-out Stratified Test Set",
      "qwk": null,
      "auc_referable_dr": null,
      "sensitivity_referable_dr": null,
      "specificity_referable_dr": null,
      "status": "PENDING_BENCHMARK_EVALUATION"
    }
  },
  "analyzed_at": "2026-08-28T10:31:22Z"
}
```

---

### 4.5. Explainability (Grad-CAM & AI Evidence)

#### `GET /screenings/{screening_id}/explainability`
Returns the interpretability heatmap and attended anatomical regions.

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "target_layer": "layer4[1].conv2",
  "gradcam_image_url": "/api/v1/images/gradcam_EX-2026-000124.png",
  "overlay_image_url": "/api/v1/images/overlay_EX-2026-000124.png",
  "original_image_url": "/api/v1/images/IMG-2026-0828-0912.jpg",
  "model_attended_regions": [
    "Posterior retinal pole",
    "Superior temporal vascular arcade",
    "Perimacular region"
  ],
  "disclaimer": "Highlighted regions represent areas contributing to the model prediction (Interpretability tool — not a definitive lesion diagnosis)."
}
```

---

### 4.6. Composite Case Detail Endpoint

#### `GET /screenings/{screening_id}`
Returns complete aggregate status for single-round trip fetching.

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "status": "READY_FOR_REVIEW",
  "patient_id": "PT-2026-8819",
  "eye": "OD",
  "image": {
    "image_id": "IMG-2026-0828-0912",
    "image_url": "/api/v1/images/IMG-2026-0828-0912.jpg",
    "sha256": "e3b0c442..."
  },
  "quality": {
    "overall_score": 0.88,
    "status": "GOOD",
    "enhancement_applied": false
  },
  "prediction": {
    "dr_level": 2,
    "severity_label": "Moderate Non-Proliferative Diabetic Retinopathy",
    "referable": true,
    "model_probability": 0.914,
    "calibrated_confidence": null,
    "review_priority": "HIGH"
  },
  "explainability": {
    "gradcam_image_url": "/api/v1/images/gradcam_EX-2026-000124.png",
    "overlay_image_url": "/api/v1/images/overlay_EX-2026-000124.png",
    "model_attended_regions": ["Posterior retinal pole"]
  },
  "review": null,
  "created_at": "2026-08-28T10:30:00Z"
}
```

---

### 4.7. Clinician Review (Human-in-the-Loop Validation)

#### `GET /reviews/pending`
Fetches cases awaiting ophthalmologist review with priority ordering (`HIGH` referable cases first).

**Response (200 OK)**:
```json
{
  "total_pending": 6,
  "cases": [
    {
      "screening_id": "EX-2026-000124",
      "patient_id": "PT-2026-8819",
      "eye": "OD",
      "ai_dr_level": 2,
      "ai_referable": true,
      "model_probability": 0.914,
      "image_quality_status": "GOOD",
      "priority": "HIGH",
      "created_at": "2026-08-28T10:30:00Z",
      "status": "READY_FOR_REVIEW"
    }
  ]
}
```

#### `POST /reviews/{screening_id}/submit`
Submits human validation or clinician override. Identity is derived server-side from the authenticated session JWT.

**Business Rules Enforced on Backend**:
1. `VALIDATE_AI_RESULT`: `final_dr_level` MUST match `ai_dr_level`.
2. `OVERRIDE`: `final_dr_level` MUST differ from `ai_dr_level`, and `clinical_notes` is MANDATORY.
3. `MARK_UNGRADABLE`: `final_dr_level` set to null; marked for clinical recapture.

**Request**:
```json
{
  "action": "OVERRIDE",
  "final_dr_level": 3,
  "final_referable": true,
  "clinical_notes": "Multiple blot hemorrhages in all 4 quadrants and venous beading observed. Reclassifying to Severe NPDR.",
  "recommended_followup_days": 30,
  "reviewed_at": "2026-08-28T11:15:00Z"
}
```

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "status": "COMPLETED",
  "review": {
    "action": "CLINICIAN_OVERRIDDEN",
    "clinician_id": "DOC-DEMO-002",
    "clinician_name": "Dr. Rajesh Kumar",
    "clinician_role": "OPHTHALMOLOGIST",
    "final_dr_level": 3,
    "final_dr_label": "Severe Non-Proliferative Diabetic Retinopathy",
    "final_referable": true,
    "clinical_notes": "Multiple blot hemorrhages in all 4 quadrants and venous beading observed. Reclassifying to Severe NPDR.",
    "reviewed_at": "2026-08-28T11:15:00Z"
  }
}
```

---

### 4.8. Offline Synchronization & Idempotency

#### `POST /sync/batch`
Synchronizes locally captured screening metadata collected while disconnected in rural settings. Image binaries are uploaded via standard multipart endpoints using `screening_id`.

**Request**:
```json
{
  "batch_id": "BATCH-20260828-HW001",
  "device_timestamp": "2026-08-28T12:00:00Z",
  "records": [
    {
      "client_request_id": "LOCAL-20260828-001",
      "patient_id": "PT-2026-9901",
      "age": 48,
      "gender": "MALE",
      "diabetes_duration_years": 4,
      "eye": "OS",
      "image_sha256": "8f481c4e9...",
      "captured_at": "2026-08-28T09:15:00Z"
    }
  ]
}
```

**Response (200 OK)**:
```json
{
  "batch_id": "BATCH-20260828-HW001",
  "synced_count": 1,
  "failed_count": 0,
  "synced_records": [
    {
      "client_request_id": "LOCAL-20260828-001",
      "server_screening_id": "EX-2026-000125",
      "status": "AWAITING_IMAGE_UPLOAD"
    }
  ]
}
```

---

### 4.9. System Status & Health

#### `GET /system/status`
Returns real-time health of backend services.

**Response (200 OK)**:
```json
{
  "status": "HEALTHY",
  "timestamp": "2026-08-28T12:05:00Z",
  "services": {
    "ai_engine": {"status": "ONLINE", "latency_ms": 142},
    "image_quality_gate": {"status": "ONLINE", "latency_ms": 38},
    "gradcam_engine": {"status": "ONLINE", "latency_ms": 210},
    "report_generator": {"status": "ONLINE", "latency_ms": 65},
    "database": {"status": "ONLINE", "latency_ms": 12}
  },
  "model_provenance": {
    "model_id": "eyexpert-dr-resnet18",
    "model_name": "EyeXpert DR Classifier",
    "model_version": "v1.2.0",
    "architecture": "ResNet-18",
    "preprocessing_version": "preprocess-v1.1",
    "last_updated": "2026-08-25"
  }
}
```
