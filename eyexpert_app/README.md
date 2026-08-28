# EyeXpert Flutter Field Screening & Decision Support Application
## SIH 2026 | Problem Statement 26038: Explainable AI for Diabetic Retinopathy Screening in Rural India

EyeXpert is a field-facing clinical screening and human-in-the-loop validation application designed for rural primary health centers (PHCs) and district hospital ophthalmologists.

---

## 1. Key Architectural Capabilities

- **Role-Based Experience**:
  - **Field Health Worker**: 1-click patient intake (OD/OS), fundus framing viewfinder, image quality verification, live progressive AI screening, explainability review, PDF report generation, and rural offline capture queue.
  - **Ophthalmologist / Clinician**: Rapid-review portal with priority queue (Level $\ge$ 2 Referable cases pinned to top), side-by-side original fundus vs Grad-CAM neural attention heatmaps, softmax probability distributions, and 1-click **Validate**, **Override** (with mandatory clinical notes), or **Mark Ungradable** actions.
- **Strict Clinical Safety Gates**:
  - **Ungradable Gating**: Any ungradable image (severe blur / sub-threshold FOV) strictly blocks AI prediction and directs the health worker to recapture.
  - **Borderline Enhancement**: Transparently notifies health workers when adaptive CLAHE preprocessing is applied prior to deep inference.
  - **AI vs Human Separation**: Clearly separates AI decision support findings from clinician final decisions on Result, Review, and Report screens.
  - **Interpretability Disclaimers**: Clarifies that Grad-CAM heatmaps highlight areas contributing to model predictions and do not represent confirmed lesion diagnoses.
- **Offline Rural Resilience**:
  - Encrypted local capture queue with idempotency keys (`Idempotency-Key` / `client_request_id`).
  - Distinguishes *local offline data capture* from *online AI inference*.
- **Frozen API Contract v1.0**:
  - Complete REST/JSON schema definitions in [EYEXPERT_API_CONTRACT_V1.md](../EYEXPERT_API_CONTRACT_V1.md).
  - Strongly-typed models for Auth, Screenings, Quality, DR Classification, Grad-CAM, Reviews, Sync, and System Status.
- **Dual Operational Modes**:
  - `DEMO MODE — SIMULATED WORKFLOW`: Interactive UI walkthrough with curated simulation scenarios.
  - `VALIDATION MODE — REAL APTOS TEST DATA`: Exploration of real held-out APTOS 2019 test cases, real ResNet-18 classifications, and verified Grad-CAM heatmaps.

---

## 2. Directory Structure

```
eyexpert_app/
├── lib/
│   ├── main.dart                               # App entry point, Riverpod ProviderScope, Adaptive Shell
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart              # Endpoints, disclaimers, thresholds
│   │   │   └── dr_severity.dart                # Levels 0-4, ICDR severity, referable rules
│   │   ├── theme/
│   │   │   ├── app_colors.dart                 # Clinical semantic colors (Good, Borderline, Ungradable, Referable)
│   │   │   ├── app_typography.dart             # Accessible typography scale
│   │   │   └── app_theme.dart                  # Material 3 light/dark clinical themes
│   │   ├── errors/
│   │   │   └── app_exceptions.dart             # Typed errors (Ungradable, ModelUnavailable, Network, etc.)
│   │   ├── security/
│   │   │   └── secure_storage.dart             # Secure session & token manager
│   │   └── utils/
│   │       ├── formatters.dart                 # Dates, percentages, eye labels
│   │       └── responsive_layout.dart          # Breakpoints (Phone, Tablet, Desktop)
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart                 # Health Worker & Clinician profiles
│   │   │   ├── patient_model.dart              # Patient demographic & session metadata
│   │   │   ├── quality_assessment_model.dart   # Quality score, sharpness, exposure, FOV
│   │   │   ├── dr_prediction_model.dart        # Level 0-4, severity, model probability, provenance
│   │   │   ├── explainability_model.dart       # Grad-CAM URLs, overlay, attended regions
│   │   │   ├── clinician_review_model.dart     # Validate, Override, Ungradable, clinical notes
│   │   │   ├── screening_case_model.dart       # Aggregate case model & state machine
│   │   │   ├── sync_queue_item.dart            # Offline queue item & idempotency keys
│   │   │   └── system_status_model.dart        # Microservices health & telemetry
│   │   ├── api/
│   │   │   ├── api_client.dart                 # Resilient HTTP client with timeouts & headers
│   │   │   └── api_endpoints.dart              # Configurable endpoints
│   │   ├── services/
│   │   │   ├── auth_service.dart               # Auth & session management
│   │   │   ├── screening_service.dart          # Quality check, inference, explainability API calls
│   │   │   ├── review_service.dart             # Clinician validation & override submission
│   │   │   ├── sync_service.dart               # Offline background synchronization
│   │   │   ├── system_service.dart             # System health & provenance status
│   │   │   ├── report_service.dart             # PDF report generator & printing
│   │   │   └── mock_data_service.dart          # Curated real APTOS validation + demo cases
│   │   └── repositories/
│   │       ├── screening_repository.dart
│   │       └── review_repository.dart
│   ├── features/
│   │   ├── auth/                               # Login & demo account selector
│   │   ├── dashboard/                          # Health Worker & Clinician dashboards
│   │   ├── screening/                          # Patient intake & viewfinder capture guide
│   │   ├── quality/                            # Image quality review & gating
│   │   ├── processing/                         # 4-stage animated clinical inference progress
│   │   ├── results/                            # AI DR Level 0-4 result & referable alert
│   │   ├── explainability/                     # 3-tab interactive Grad-CAM viewer & opacity blend
│   │   ├── reports/                            # Polished screening report preview & PDF export
│   │   ├── review/                             # Rapid Clinician Review interface
│   │   ├── queue/                              # Searchable, filterable case list with priority badges
│   │   ├── offline/                            # Offline Sync Manager & network simulator toggle
│   │   ├── system_status/                      # Microservice telemetry & model provenance
│   │   └── profile/                            # User profile, role switch, workflow mode toggle
│   └── shared/
│       └── widgets/
│           ├── clinical_card.dart              # Card with subtle border and elevation
│           ├── status_badge.dart               # Semantic status badge (Icon + Text + Color)
│           ├── medical_disclaimer_banner.dart  # Regulatory & AI decision support disclaimer
│           ├── fundus_image_viewer.dart        # Zoomable, pannable, high-contrast fundus viewer
│           ├── probability_bar.dart            # Softmax class distribution visualizer
│           ├── model_provenance_card.dart      # Standardized provenance badge & metadata
│           ├── offline_status_bar.dart         # Offline / sync alert bar
│           ├── primary_button.dart             # Accessible high-contrast button
│           └── responsive_scaffold.dart        # Scaffold with BottomNav / NavigationRail / Sidebar
└── test/
    ├── unit/
    │   ├── dr_severity_test.dart               # Referable DR mapping & severity tests
    │   ├── quality_assessment_test.dart        # Quality status & blocking rules test
    │   ├── clinician_review_test.dart          # Clinician override & audit trail test
    │   └── sync_service_test.dart              # Offline queueing & sync state machine test
    └── widget/
        ├── ai_result_screen_test.dart          # DR result rendering & disclaimer test
        ├── image_quality_screen_test.dart      # Ungradable blocking & feedback test
        └── widget_test.dart                    # App smoke test
```

---

## 3. Getting Started & Running

### Prerequisites
- Flutter SDK `^3.44.0` / Dart `^3.12.0`
- Chrome / Edge (Web), Windows Desktop, or Android Studio Emulator / Physical Device

### Installation & Execution
```bash
# 1. Navigate to Flutter directory
cd eyexpert_app

# 2. Get dependencies
flutter pub get

# 3. Run all automated tests (16 Unit & Widget tests)
flutter test

# 4. Run on Chrome Web
flutter run -d chrome

# 5. Build production Web target
flutter build web
```

---

## 4. End-to-End User Demonstration Flow

1. **Launch EyeXpert**: Select Demo Profile (`DEMO HEALTH WORKER — Sunita Sharma (Demo PHC)`).
2. **Dashboard**: View KPI metrics (Today's Screenings: 28, Pending: 6, Recapture: 3, Referable: 5).
3. **Start Screening**: Tap `[START NEW SCREENING]`, autofill demo patient ID (`PT-2026-8819`), select Right Eye (`OD`).
4. **Viewfinder Capture**: Retinal framing reticle guide with live prompts ("Center optic disc & macula"). Select Moderate NPDR scenario.
5. **Quality Assessment**: Evaluates Focus, Exposure, and Retinal FOV (Overall Score: 88% — GOOD).
6. **Live Inference**: 4-stage animated pipeline (Quality -> Preprocessing -> ResNet-18 -> Grad-CAM).
7. **AI Result**: Level 2 Moderate NPDR, `REFERABLE DR — YES`, Model Probability 91.4%, Softmax distribution, Model Provenance.
8. **Explainability**: Open 3-tab interactive viewer (Original, Grad-CAM, Overlay blend with interactive opacity slider).
9. **Screening Report**: Generate and print/export PDF report.
10. **Role Switch to Clinician**: Switch to `DEMO CLINICIAN — Dr. Rajesh Kumar (Demo Ophthalmology Unit)`.
11. **Review Queue**: Open pending referable case `EX-2026-000124`.
12. **Clinician Rapid Review**: Side-by-side retinal view vs. Grad-CAM, validate finding or override with clinical notes, and finalize review.
