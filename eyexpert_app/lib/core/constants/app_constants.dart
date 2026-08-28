class AppConstants {
  static const String appName = 'EyeXpert';
  static const String appTagline = 'Explainable AI for Diabetic Retinopathy Screening';
  static const String sihProblemStatement = 'SIH 2026 | Problem Statement 26038';
  static const String appVersion = '1.0.0 (SIH 2026 Production Build)';

  // Modes
  static const String demoModeTitle = 'DEMO MODE — SIMULATED WORKFLOW';
  static const String validationModeTitle = 'VALIDATION MODE — REAL APTOS TEST DATA';

  // Medical Disclaimers
  static const String standardDisclaimer =
      'EyeXpert is an AI-assisted diabetic retinopathy screening and clinical decision-support application. '
      'It does not constitute an autonomous medical diagnosis. Final clinical interpretation must be performed by a qualified ophthalmologist or clinician.';

  static const String xaiDisclaimer =
      'Highlighted regions represent areas contributing to the model prediction (Interpretability tool — not a definitive lesion diagnosis).';

  static const String offlineNotice =
      'Offline — screening data will be stored securely and synchronized when network connectivity is restored.';

  // Default API configuration
  static const String defaultDevBaseUrl = 'http://localhost:5000/api/v1';
  static const String defaultProdBaseUrl = 'https://api.eyexpert.org/v1';
  static const int apiTimeoutSeconds = 30;

  // Image Quality Thresholds
  static const double qualityGoodMin = 0.70;
  static const double qualityBorderlineMin = 0.45;
}
