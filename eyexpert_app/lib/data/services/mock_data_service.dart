import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/quality_assessment_model.dart';
import '../models/dr_prediction_model.dart';
import '../models/explainability_model.dart';
import '../models/clinician_review_model.dart';
import '../models/screening_case_model.dart';
import '../models/system_status_model.dart';
import '../../core/constants/dr_severity.dart';

class MockDataService {
  static List<ScreeningCaseModel> getInitialCases() {
    return [];
  }

  static ScreeningCaseModel _createCase({
    required String id,
    required String patientId,
    required int age,
    required String gender,
    required int diabetesDurationYears,
    required String eye,
    required String imageAsset,
    required String gradcamAsset,
    required int level,
    required double modelProb,
    double? calibratedConf,
    required double qualityScore,
    required QualityStatus qualityStatus,
    required double sharpnessScore,
    required double illumScore,
    required double fovScore,
    required Map<int, double> classProbs,
    required List<String> attendedRegions,
    required ScreeningStatus status,
    ClinicianReviewModel? review,
    List<String>? feedbackMessages,
    required DateTime createdAt,
  }) {
    final bool isUngradable = qualityStatus == QualityStatus.ungradable;

    return ScreeningCaseModel(
      screeningId: id,
      clientRequestId: 'REQ-$id',
      patient: PatientModel(
        patientId: patientId,
        age: age,
        gender: gender,
        diabetesDurationYears: diabetesDurationYears,
        eye: eye,
        facilityId: 'PHC-DEMO-01',
        createdAt: createdAt,
      ),
      status: status,
      image: FundusImageData(
        imageId: 'IMG-${id.replaceAll("EX-", "")}',
        imageUrl: imageAsset,
        localPath: imageAsset,
        sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        captureDeviceModel: 'Portable Handheld Fundus Camera v2',
        uploadedAt: createdAt.add(const Duration(minutes: 1)),
      ),
      quality: QualityAssessmentModel(
        screeningId: id,
        overallScore: qualityScore,
        status: qualityStatus,
        sharpness: QualityMetric(
          score: sharpnessScore,
          status: sharpnessScore > 0.5 ? 'GOOD' : 'POOR',
          metricName: 'Laplacian Variance Focus',
        ),
        illumination: QualityMetric(
          score: illumScore,
          status: illumScore > 0.5 ? 'GOOD' : 'ATTENTION',
          metricName: 'Exposure & Uniformity',
        ),
        fieldOfView: QualityMetric(
          score: fovScore,
          status: fovScore > 0.4 ? 'ADEQUATE' : 'INADEQUATE',
          metricName: 'Retinal Mask Field of View',
        ),
        enhancementApplied: qualityStatus == QualityStatus.borderline,
        feedbackMessages: feedbackMessages ??
            (isUngradable
                ? ['Image is ungradable. Please recapture.']
                : ['Image quality optimal for automated screening.']),
        evaluatedAt: createdAt.add(const Duration(minutes: 2)),
      ),
      prediction: isUngradable
          ? null
          : DRPredictionModel(
              screeningId: id,
              drLevel: level,
              severityLabel: DRSeverity.fromLevel(level).fullName,
              severityCode: 'LEVEL_$level',
              referable: DRSeverity.checkIsReferable(level),
              modelProbability: modelProb,
              calibratedConfidence: calibratedConf,
              classProbabilities: classProbs,
              reviewPriority: level >= 2 ? 'HIGH' : 'NORMAL',
              recommendation: DRSeverity.fromLevel(level).recommendation,
              provenance: ModelProvenanceModel.defaultProvenance,
              analyzedAt: createdAt.add(const Duration(minutes: 3)),
            ),
      explainability: isUngradable
          ? null
          : ExplainabilityModel(
              screeningId: id,
              targetLayer: 'layer4[1].conv2',
              gradcamImageUrl: gradcamAsset,
              overlayImageUrl: gradcamAsset,
              originalImageUrl: imageAsset,
              modelAttendedRegions: attendedRegions,
              disclaimer:
                  'Highlighted regions represent areas contributing to the model prediction (Interpretability tool — not a definitive lesion diagnosis).',
            ),
      review: review,
      createdAt: createdAt,
      updatedAt: createdAt.add(const Duration(minutes: 5)),
    );
  }

  // Pre-curated demo screening scenarios
  static List<Map<String, dynamic>> getDemoScenarios() {
    return [
      {
        'id': 'scenario_normal',
        'title': 'Level 0 — Normal Retina (Non-Referable)',
        'description': 'Clear fundus view with intact vasculature and no diabetic lesions.',
        'imageAsset': 'assets/sample_fundus/sample_good_normal.png',
        'gradcamAsset': 'assets/sample_fundus/real_aptos_gradcam_level_0_c38dec54a9f7.png',
        'expectedLevel': 0,
        'expectedReferable': false,
        'qualityScore': 0.94,
        'qualityStatus': QualityStatus.good,
        'sharpness': 0.95,
        'illumination': 0.92,
        'fov': 0.96,
        'modelProb': 0.968,
        'classProbs': {0: 0.968, 1: 0.022, 2: 0.006, 3: 0.003, 4: 0.001},
        'attendedRegions': ['Clear macular zone', 'Normal optic disc margins'],
      },
      {
        'id': 'scenario_mild',
        'title': 'Level 1 — Mild NPDR (Non-Referable)',
        'description': 'Early microaneurysms detected in temporal periphery.',
        'imageAsset': 'assets/sample_fundus/sample_good_npdr_mild.png',
        'gradcamAsset': 'assets/sample_fundus/real_aptos_gradcam_level_1_36041171f441.png',
        'expectedLevel': 1,
        'expectedReferable': false,
        'qualityScore': 0.86,
        'qualityStatus': QualityStatus.good,
        'sharpness': 0.88,
        'illumination': 0.84,
        'fov': 0.89,
        'modelProb': 0.845,
        'classProbs': {0: 0.120, 1: 0.845, 2: 0.025, 3: 0.008, 4: 0.002},
        'attendedRegions': ['Temporal microaneurysms', 'Perimacular capillary beds'],
      },
      {
        'id': 'scenario_moderate',
        'title': 'Level 2 — Moderate NPDR (Referable)',
        'description': 'Hard exudates, cotton wool spots, and multiple microaneurysms.',
        'imageAsset': 'assets/sample_fundus/sample_good_npdr_moderate.png',
        'gradcamAsset': 'assets/sample_fundus/real_aptos_gradcam_level_2_094858f005ab.png',
        'expectedLevel': 2,
        'expectedReferable': true,
        'qualityScore': 0.88,
        'qualityStatus': QualityStatus.good,
        'sharpness': 0.89,
        'illumination': 0.86,
        'fov': 0.90,
        'modelProb': 0.914,
        'classProbs': {0: 0.021, 1: 0.037, 2: 0.892, 3: 0.041, 4: 0.009},
        'attendedRegions': ['Superior temporal arcade', 'Posterior pole exudates'],
      },
      {
        'id': 'scenario_severe',
        'title': 'Level 3 — Severe NPDR (Referable)',
        'description': 'Extensive intraretinal hemorrhages and venous beading.',
        'imageAsset': 'assets/sample_fundus/sample_good_npdr_moderate.png',
        'gradcamAsset': 'assets/sample_fundus/real_aptos_gradcam_level_3_405b4f78658f.png',
        'expectedLevel': 3,
        'expectedReferable': true,
        'qualityScore': 0.85,
        'qualityStatus': QualityStatus.good,
        'sharpness': 0.87,
        'illumination': 0.82,
        'fov': 0.89,
        'modelProb': 0.887,
        'classProbs': {0: 0.005, 1: 0.018, 2: 0.065, 3: 0.887, 4: 0.025},
        'attendedRegions': ['4-quadrant hemorrhages', 'Venous beading sites'],
      },
      {
        'id': 'scenario_pdr',
        'title': 'Level 4 — Proliferative DR (Urgent Referable)',
        'description': 'Active neovascularization and preretinal hemorrhage.',
        'imageAsset': 'assets/sample_fundus/sample_good_pdr_severe.png',
        'gradcamAsset': 'assets/sample_fundus/real_aptos_gradcam_level_4_eaa0dfbd5024.png',
        'expectedLevel': 4,
        'expectedReferable': true,
        'qualityScore': 0.91,
        'qualityStatus': QualityStatus.good,
        'sharpness': 0.92,
        'illumination': 0.89,
        'fov': 0.93,
        'modelProb': 0.942,
        'classProbs': {0: 0.002, 1: 0.005, 2: 0.012, 3: 0.039, 4: 0.942},
        'attendedRegions': ['Disc neovascularization (NVD)', 'Preretinal hemorrhage'],
      },
      {
        'id': 'scenario_borderline',
        'title': 'Borderline Quality — Adaptive CLAHE Applied',
        'description': 'Sub-optimal illumination automatically enhanced prior to deep inference.',
        'imageAsset': 'assets/sample_fundus/sample_borderline_illum.png',
        'gradcamAsset': 'assets/sample_fundus/real_aptos_gradcam_level_2_094858f005ab.png',
        'expectedLevel': 2,
        'expectedReferable': true,
        'qualityScore': 0.61,
        'qualityStatus': QualityStatus.borderline,
        'sharpness': 0.68,
        'illumination': 0.48,
        'fov': 0.72,
        'modelProb': 0.865,
        'classProbs': {0: 0.045, 1: 0.060, 2: 0.835, 3: 0.048, 4: 0.012},
        'attendedRegions': ['Enhanced macular region', 'Vascular arcades'],
      },
      {
        'id': 'scenario_ungradable',
        'title': 'Ungradable Quality — Recapture Gated',
        'description': 'Severe blur blocks automated AI DR screening to protect clinical safety.',
        'imageAsset': 'assets/sample_fundus/sample_ungradable_blur.png',
        'gradcamAsset': '',
        'expectedLevel': -1,
        'expectedReferable': false,
        'qualityScore': 0.28,
        'qualityStatus': QualityStatus.ungradable,
        'sharpness': 0.16,
        'illumination': 0.42,
        'fov': 0.35,
        'modelProb': 0.0,
        'classProbs': {},
        'attendedRegions': [],
      },
    ];
  }
}
