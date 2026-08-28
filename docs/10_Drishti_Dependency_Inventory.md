# Drishti (SIH 2026 PS-26038) — Complete Dependency & Tool Inventory

## 1. Python Backend & Deep Learning Dependencies (`requirements.txt` / Runtime)

| Library | Version / Constraint | Used In / Module | Purpose in Drishti |
| :--- | :--- | :--- | :--- |
| **torch** | `^2.2.0` | `web_app.py`, `train_aptos_real.py`, `model/train_pytorch_resnet.py` | Core deep-learning framework, ResNet-18 model tensor graph, backprop, hooks |
| **torchvision** | `^0.17.0` | `web_app.py`, `train_aptos_real.py` | Pretrained ResNet-18 weights, image tensor normalization transforms |
| **numpy** | `^1.24.0` | `web_app.py`, `train_aptos_real.py`, `evaluate_saved_model.py` | Array manipulation, Grad-CAM activation weighting, confusion matrix ops |
| **Pillow (PIL)** | `^10.0.0` | `web_app.py`, `train_aptos_real.py`, `generate_all_artifacts.py` | Image loading, downsampling, bounding box cropping, format conversion |
| **opencv-python-headless** | `^4.8.0` | `web_app.py`, `tests/verifyRealityAudit.py` | Laplacian variance focus scoring, CLAHE contrast enhancement, FOV contouring |
| **Flask** | `^3.0.0` | `web_app.py` | REST API microservices gateway (`/api/v1/*`), multipart upload routing |
| **Flask-CORS** | `^4.0.0` | `web_app.py` | Cross-Origin Resource Sharing for Flutter Web / local dev integration |
| **gunicorn** | `^21.2.0` | `Procfile` | Production WSGI HTTP server on Linux cloud host (Render) |
| **scikit-learn** | `^1.3.0` | `train_aptos_real.py`, `evaluate_saved_model.py` | Quadratic Weighted Kappa (QWK), ROC curves, AUC, per-class classification reports |
| **matplotlib** | `^3.7.0` | `train_aptos_real.py`, `evaluate_saved_model.py` | Heatmap generation, confusion matrix plotting, ROC visualization |
| **pandas** | `^2.0.0` | `train_aptos_real.py`, `evaluate_saved_model.py` | Dataset manifest management, train/val/test stratified partitioning |
| **python-pptx** | `^1.0.0` | `docs/` | Automated SIH 2026 PowerPoint generation |
| **reportlab** | `^5.0.0` | `docs/` | Automated high-fidelity clinical and technical PDF documentation export |

---

## 2. Flutter / Dart Mobile & Web Client Dependencies (`eyexpert_app/pubspec.yaml`)

| Package | Version | Layer / File Location | Purpose in Drishti |
| :--- | :--- | :--- | :--- |
| **flutter** | SDK | Core Client | Cross-platform UI toolkit targeting Android, iOS, Web, and Desktop |
| **flutter_riverpod** | `^2.5.1` | `lib/features/*/providers.dart` | Reactive clinical state management, dependency injection, session caching |
| **supabase_flutter** | `^2.8.0` | `lib/data/services/supabase_service.dart` | PostgreSQL database, JWT authentication, Storage bucket, and Realtime sync |
| **image_picker** | `^1.1.2` | `lib/features/screening/fundus_capture_screen.dart` | High-res camera capture & gallery fundus photograph selection |
| **http** | `^1.2.1` | `lib/data/api/api_client.dart` | Multipart image upload and REST API communication with PyTorch backend |
| **intl** | `^0.19.0` | `lib/core/utils/formatters.dart` | Date-time formatting, localization, numerical percentage representations |
| **uuid** | `^4.4.0` | `lib/data/services/screening_service.dart` | RFC4122 v4 screening UUID and client idempotency key generation |
| **crypto** | `^3.0.3` | `lib/data/services/sync_service.dart` | SHA-256 payload hashing for deduplication and offline audit trails |
| **shared_preferences**| `^2.2.3` | `lib/core/security/secure_storage.dart` | Local token storage, offline queued screenings, and session persistence |
| **pdf** | `^3.10.8` | `lib/features/reports/screening_report_screen.dart` | Clinical screening summary document generation |
| **printing** | `^5.12.0` | `lib/features/reports/screening_report_screen.dart` | Direct thermal/air printing and PDF sharing for rural PHC clinics |
| **fl_chart** | `^0.68.0` | `lib/features/system_status/`, `results/` | Probability distribution graphs and district telemedicine workload charts |
| **cupertino_icons** | `^1.0.8` | `lib/shared/` | iOS styling asset bundle |
| **flutter_lints** | `^3.0.0` | `dev_dependencies` | Static analysis rules enforcing medical-grade code quality |

---

## 3. MATLAB & Simulink Toolboxes (`model/`, `quality/`, `simulink/`, `cv_analysis/`)

| Toolbox / Environment | Minimum Version | Files Used | Purpose in Drishti |
| :--- | :--- | :--- | :--- |
| **MATLAB Base System** | `R2023b` or `R2024a` | `main_demo.m`, `app/` | Numerical engine, script execution, pipeline orchestration |
| **Image Processing Toolbox** | `R2023b` | `quality/*`, `preprocessing/*`, `cv_analysis/*` | `adapthisteq` (CLAHE), `imtophat` (vessels), `imgaussfilt` (optic disc), `bwareaopen` |
| **Computer Vision Toolbox** | `R2023b` | `quality/calculateFOV.m`, `cv_analysis/*` | Contour extraction, geometric feature representation, retinal boundary masking |
| **Deep Learning Toolbox** | `R2023b` | `model/trainDRModel.m`, `classification/*` | PyTorch model import (`importNetworkFromPyTorch`), activation maps, Grad-CAM |
| **Statistics & Machine Learning** | `R2023b` | `validation/calculateMetrics.m`, `simulink/*` | Poisson random generation, confusion matrix analysis, Cohen's Kappa calculation |
| **Simulink** | `R2023b` | `simulink/createDistrictModel.m` | Discrete-event district queuing simulation (120,000 annual patients, M/M/c queues) |
