# Drishti (SIH 2026 PS-26038) — REST API Specification & Architecture

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
