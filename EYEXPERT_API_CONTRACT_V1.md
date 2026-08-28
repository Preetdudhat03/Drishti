# EyeXpert API Contract Specification (v1.0)
**SIH 2026 Problem Statement 26038 | Explainable AI for Diabetic Retinopathy Screening**

This document specifies the standard REST/JSON interface between the **EyeXpert Flutter Client** (Field Screening & Clinician Review app) and the **EyeXpert AI Backend** (Python/PyTorch/MATLAB Engine).

---

## 1. Global Standard Headers & Conventions

- **Base URL**: Configurable, default `https://api.eyexpert.org/v1` or `http://localhost:5000/api/v1`
- **Authentication**: `Authorization: Bearer <jwt_token>`
- **Content-Type**: `application/json` (or `multipart/form-data` for raw image uploads)
- **Time Format**: ISO 8601 UTC (`YYYY-MM-DDTHH:mm:ssZ`)

---

## 2. Endpoints & Schemas

### 2.1. Authentication & Session

#### `POST /auth/login`
**Request**:
```json
{
  "username": "healthworker1@demo.eyexpert",
  "password": "SecurePassword123",
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

### 2.2. Screening Session Lifecycle

#### `POST /screenings`
Creates a new screening session record for a patient.

**Request**:
```json
{
  "patient_id": "PT-2026-8819",
  "age": 54,
  "gender": "FEMALE",
  "diabetes_duration_years": 8,
  "eye": "OD",
  "facility_id": "PHC-RAMGARH-01",
  "created_at": "2026-08-28T10:30:00Z"
}
```
*Note: `eye` must be `"OD"` (Right Eye) or `"OS"` (Left Eye).*

**Response (201 Created)**:
```json
{
  "screening_id": "EX-2026-000124",
  "patient_id": "PT-2026-8819",
  "eye": "OD",
  "status": "AWAITING_IMAGE",
  "created_at": "2026-08-28T10:30:00Z"
}
```

---

### 2.3. Fundus Image Upload & Quality Assessment

#### `POST /screenings/{screening_id}/image`
Multipart form upload of fundus photograph.

**Request**:
- `image`: Binary image file (JPEG/PNG)
- `capture_device_model`: string (optional, e.g. "Portable Fundus Camera v2")

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "image_id": "IMG-2026-0828-0912",
  "image_url": "/api/v1/images/IMG-2026-0828-0912.jpg",
  "thumbnail_url": "/api/v1/images/IMG-2026-0828-0912_thumb.jpg",
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

*Status Enumerations*:
- `GOOD`: Direct progression to AI classification.
- `BORDERLINE`: Client notifies health worker that Adaptive CLAHE enhancement is applied.
- `UNGRADABLE`: Client **strictly blocks** DR prediction and prompts mandatory recapture.

---

### 2.4. AI Screening & DR Classification

#### `POST /screenings/{screening_id}/analyze`
Triggers AI inference on the preprocessed/enhanced fundus image.

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "status": "ANALYZED",
  "prediction": {
    "dr_level": 2,
    "severity_label": "Moderate Non-Proliferative Diabetic Retinopathy",
    "severity_code": "MODERATE_NPDR",
    "referable": true,
    "referable_threshold": "Level >= 2",
    "model_probability": 0.914,
    "calibrated_confidence": 0.882,
    "class_probabilities": {
      "0": 0.021,
      "1": 0.037,
      "2": 0.892,
      "3": 0.041,
      "4": 0.009
    },
    "recommendation": "Ophthalmologist review and dilated fundus examination recommended."
  },
  "model_provenance": {
    "model_name": "EyeXpert DR Classifier",
    "architecture": "ResNet-18 (Transfer Learning)",
    "training_dataset": "APTOS 2019 Blindness Detection",
    "model_version": "v1.2.0",
    "validation_benchmark": "Held-out Stratified Test Set (QWK: 0.870, AUC: 0.980)"
  },
  "analyzed_at": "2026-08-28T10:31:22Z"
}
```

---

### 2.5. Explainability (Grad-CAM & AI Evidence)

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

### 2.6. Clinician Review (Human-in-the-Loop Validation)

#### `GET /reviews/pending`
Fetches cases awaiting ophthalmologist review with priority ordering.

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
      "image_quality_status": "GOOD",
      "priority": "HIGH",
      "created_at": "2026-08-28T10:30:00Z",
      "review_status": "PENDING"
    }
  ]
}
```

#### `POST /reviews/{screening_id}/submit`
Submits human validation or clinician override.

**Request**:
```json
{
  "action": "OVERRIDE",
  "clinician_id": "DOC-DEMO-002",
  "clinician_name": "Dr. Rajesh Kumar",
  "final_dr_level": 2,
  "final_referable": true,
  "clinical_notes": "Microaneurysms and hard exudates confirmed in superior temporal quadrant. Agrees with Level 2 classification.",
  "recommended_followup_days": 90,
  "reviewed_at": "2026-08-28T11:15:00Z"
}
```
*Actions*:
- `VALIDATE_AI_RESULT`: Clinician confirms AI prediction is accurate.
- `OVERRIDE`: Clinician assigns alternative DR level (0-4) with mandatory clinical notes.
- `MARK_UNGRADABLE`: Clinician rejects image as uninterpretable.

**Response (200 OK)**:
```json
{
  "screening_id": "EX-2026-000124",
  "status": "COMPLETED",
  "review": {
    "action": "OVERRIDE",
    "clinician_name": "Dr. Rajesh Kumar",
    "final_dr_level": 2,
    "final_dr_label": "Moderate NPDR",
    "reviewed_at": "2026-08-28T11:15:00Z"
  }
}
```

---

### 2.7. Offline Synchronization

#### `POST /sync/batch`
Synchronizes locally captured cases collected while disconnected in rural settings.

**Request**:
```json
{
  "batch_id": "BATCH-20260828-HW001",
  "device_timestamp": "2026-08-28T12:00:00Z",
  "records": [
    {
      "local_id": "LOCAL-001",
      "patient_id": "PT-2026-9901",
      "age": 48,
      "gender": "MALE",
      "diabetes_duration_years": 4,
      "eye": "OS",
      "captured_at": "2026-08-28T09:15:00Z",
      "image_base64": "..."
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
      "local_id": "LOCAL-001",
      "server_screening_id": "EX-2026-000125",
      "status": "UPLOADED_QUEUED_FOR_AI"
    }
  ]
}
```

---

### 2.8. System Status & Health

#### `GET /system/status`
Returns real-time health of backend micro-services.

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
    "model_name": "EyeXpert DR Classifier",
    "version": "v1.2.0",
    "architecture": "ResNet-18",
    "last_updated": "2026-08-25"
  }
}
```
