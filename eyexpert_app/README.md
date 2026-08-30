# Drishti Flutter Tele-Ophthalmology & Field Screening Applications
## SIH 2026 | Problem Statement 26038: Explainable AI for Diabetic Retinopathy Screening in Rural India

Drishti is a clinical tele-ophthalmology screening platform consisting of two specialized, role-dedicated Flutter applications communicating over a shared Supabase cloud and AI inference backend:

1. **Drishti PHC** (`lib/main_phc.dart`): Designed for Primary Health Centre (PHC) health workers for patient intake, fundus photo acquisition, automated image quality gating (CLAHE enhancement), deep learning DR classification (ResNet-18), and encrypted offline sync.
2. **Drishti Clinician** (`lib/main_clinician.dart`): Designed for district ophthalmologists for case triage, Grad-CAM layer-4 visual evidence inspection, diagnostic validation/override, and tele-ophthalmology reporting.

---

## 1. Key Architectural Capabilities

- **Two Role-Dedicated Applications**:
  - **Drishti PHC**: Pure field screening workflow (Intake → Capture → Quality Gate → ResNet-18 Inference → Grad-CAM Explainability → Screening Report → Rural Sync Queue).
  - **Drishti Clinician**: Specialist review workstation (Priority Review Queue → Side-by-side Fundus & Grad-CAM inspection → Diagnostic Validation/Override with mandatory clinical notes → System Status).
- **Production Supabase Authentication & PostgreSQL Profiles**:
  - Authentication against Supabase Auth (`auth.users`) with server-side role resolution from PostgreSQL `profiles` table.
  - Role-based access control (RBAC) preventing unauthorized access across PHC and Clinician workstations.
- **Strict Clinical Safety Gates**:
  - **Ungradable Gating**: Any ungradable retinal image (severe blur, sub-threshold FOV) strictly blocks AI prediction and directs the health worker to recapture.
  - **Borderline Enhancement**: Transparently notifies health workers when adaptive CLAHE preprocessing is applied prior to deep inference.
  - **AI vs Human Separation**: Clearly separates AI decision support findings from clinician final decisions on Result, Review, and Report screens.
  - **Interpretability Disclaimers**: Clarifies that Grad-CAM heatmaps highlight areas contributing to model predictions and do not represent confirmed lesion diagnoses.
- **Offline Rural Resilience**:
  - Encrypted local capture queue with idempotency keys (`Idempotency-Key` / `client_request_id`).
  - Distinguishes *local offline data capture* from *online AI inference*.

---

## 2. Running the Applications

### Prerequisites
- Flutter SDK `^3.44.0` / Dart `^3.12.0`
- Chrome / Edge (Web), Windows Desktop, or Android Studio Emulator / Physical Device

### Execution Commands

```bash
# Navigate to Flutter directory
cd eyexpert_app

# Get dependencies
flutter pub get

# Run all unit and widget tests
flutter test

# Run Drishti PHC Workstation (Field Health Worker)
flutter run -t lib/main_phc.dart -d chrome

# Run Drishti Clinician Workstation (Ophthalmologist Review)
flutter run -t lib/main_clinician.dart -d chrome

# Run Unified App Entrypoint
flutter run -t lib/main.dart -d chrome
```
