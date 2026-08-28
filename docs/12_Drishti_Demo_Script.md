# Drishti (SIH 2026 PS-26038) — Live Demonstration & Presentation Script

## 1. Executive Demo Flow (3–5 Minutes)

| Step | Persona & Screen | Physical Action on Device / Web | Expected Outcome & System Response | Key Talking Point for Judges |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Health Worker Login** (`LoginScreen`) | Tap "Health Worker Login" (`hw@drishti.health`) | Authenticates via Supabase JWT; lands on Live Screening Dashboard | "Role-based security tailored for frontline ASHA & Primary Health Centre workers." |
| **2** | **Screening Dashboard** (`DashboardScreen`) | Show real-time sync metrics (Total Screened, Referable, Recaptures) | Pull-to-refresh syncs with PostgreSQL database in cloud | "Every metric is computed live from the cloud database — zero hardcoded counters." |
| **3** | **Patient Registration** (`PatientFormScreen`) | Enter ID: `PT-2026-8819`, Age: `54`, Eye: `Right Eye (OD)` | Session UUID `EX-2026-881923` generated with RFC4122 standard | "Idempotent registration allows offline caching without duplicate records." |
| **4** | **Image Quality Assessment** (`QualityScreen`) | Upload fundus photograph with borderline illumination | Automated Image Quality Engine computes Sharpness, Illumination, and FOV scores | "Safety First: Drishti gates AI inference on image quality to prevent misdiagnosing blurred retinas." |
| **5** | **AI Inference & Grad-CAM** (`ProcessingScreen`) | Tap "Run Drishti AI Screening" | Neural inference yields Level 2 (Moderate NPDR), 91.4% probability, and Grad-CAM | "ResNet-18 highlights pathological regions in the macular arcade with Grad-CAM neural attention." |
| **6** | **Clinical PDF Report** (`ReportScreen`) | Tap "Export / Print Clinical PDF" | Formats bilingual, standardized clinical summary document | "Standardized for rural distribution and patient record handover." |
| **7** | **Ophthalmologist Switch** (`ProfileScreen`) | Log out & sign in as Ophthalmologist (`Dr. Rajesh Kumar`) | Lands on Clinician Review Queue with urgency priority sorting | "Referable high-priority cases automatically rise to the top of the specialist's queue." |
| **8** | **Human-in-the-Loop Review** (`ClinicianReviewScreen`)| Examine dual Fundus / Grad-CAM view & tap "Validate AI Result" | Immutable audit event written to Supabase `audit_events` table; status becomes `VALIDATED` | "AI assists. Doctor decides. The physician retains final diagnostic authority." |
| **9** | **District Telemedicine Simulation** (`SimulinkDashboard`)| Display district scaling chart (120,000 annual patients) | Baseline manual overload (104% utilization) vs Drishti AI-triage (29% utilization) | "Modeled in MATLAB/Simulink: Drishti cuts specialist review queue delay from 48+ hours to < 5 minutes." |

---

## 2. Ten-Second Backup Demo Plan (If Network / Cloud Offline)

In the event of total venue network failure or cloud backend sleeping:
1. **Offline Mode**: The Flutter application detects local network disconnection and serves cached clinical cases from local secure SQLite/SharedPreferences.
2. **Deterministic Explanation**: Explain to judges: *"Drishti includes built-in offline synchronization. In disconnected rural clinics, screenings queue locally with SHA-256 integrity hashes and sync automatically once cell connectivity is restored."*
3. **Local Architecture Verification**: Run `python tests/verifyRealityAudit.py` in terminal to demonstrate all 6 deep learning and computer vision pipeline stages executing locally in 1.2 seconds.
