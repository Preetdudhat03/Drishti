class AppConstants {
  // Product Identity
  static const String appName = 'Drishti';
  static const String appHindiName = 'दृष्टि';
  static const String appSubtitle = 'Clinical Intelligence + Human Care';
  static const String appTagline = 'Explainable AI-Assisted Diabetic Retinopathy Screening';
  static const String sihProblemStatement = 'SIH 2026 | Problem Statement 26038';
  static const String sihTheme = 'Smart Healthcare — AI for Rural Retinal Screening';
  static const String appVersion = '1.0.0-rc1';

  // Environment & Supabase Configuration
  // Note: Anon key is public client credential protected by RLS; never embed service-role secrets.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://matnyxemkowspnvxntmj.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdG55eGVta293c3BudnhudG1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc5MDc5MDMsImV4cCI6MjEwMzQ4MzkwM30.AGKuUBKKc2lAbAp_x2oNTO4QAq-Xt4DQ7fGeTRUu_b4',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );

  static const String storageBucketFundus = 'fundus-images';

  // Medical Statutory Disclaimers
  static const String standardDisclaimer =
      'Drishti is an explainable AI-assisted screening and clinical decision-support prototype. '
      'It is NOT an autonomous diagnostic medical device and does NOT replace a qualified ophthalmologist. '
      'Final clinical diagnosis and management must be confirmed by a licensed clinician.';

  static const String prototypeMedicalDisclaimer = standardDisclaimer;

  static const String xaiDisclaimer =
      'Interpretability output (Grad-CAM) highlights retinal regions contributing to model prediction. '
      'It does not represent a confirmed or definitive lesion diagnosis.';

  static const String offlineModeDisclaimer =
      'Offline — captured records will be synchronized with cloud database when network is restored. '
      'Offline data capture does not imply offline AI inference.';

  static const String reportDisclaimer =
      'Drishti is an AI-assisted screening and clinical decision-support prototype. '
      'It does not replace professional medical judgment. Final clinical interpretation '
      'must be performed by a qualified ophthalmologist or clinician.';

  // Clinical Quality Gating Thresholds
  static const double qualityGoodThreshold = 0.70;
  static const double qualityBorderlineThreshold = 0.45;

  // Model & Provenance Defaults
  static const String defaultModelId = 'drishti-dr-resnet18-v1.0';
  static const String defaultModelArchitecture = 'ResNet-18 (Deep Residual Learning)';
  static const String defaultTrainingDataset = 'APTOS 2019 Blindness Detection (Held-out Stratified)';
  static const String defaultPreprocessingPipeline = 'Circular Mask Crop + Adaptive CLAHE (v1.2)';
  static const String defaultValidationStatus = 'Held-out validation pending formal trial evaluation';
}
