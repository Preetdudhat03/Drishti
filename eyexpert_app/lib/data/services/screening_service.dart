import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/patient_model.dart';
import '../models/quality_assessment_model.dart';
import '../models/dr_prediction_model.dart';
import '../models/explainability_model.dart';
import '../models/screening_case_model.dart';
import '../../core/errors/app_exceptions.dart';
import 'mock_data_service.dart';
import 'supabase_service.dart';

class ScreeningService {
  final ApiClient _apiClient;
  final SupabaseService _supabaseService;

  ScreeningService({ApiClient? apiClient, SupabaseService? supabaseService})
      : _apiClient = apiClient ?? ApiClient(),
        _supabaseService = supabaseService ?? SupabaseService();

  Future<ScreeningCaseModel> createScreening({
    required PatientModel patient,
    required String clientRequestId,
    bool isDemo = true,
  }) async {
    final String id = 'DR-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    final screeningCase = ScreeningCaseModel(
      screeningId: id,
      clientRequestId: clientRequestId,
      patient: patient,
      status: ScreeningStatus.awaitingImage,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Supabase
    if (SupabaseService.isInitialized) {
      await _supabaseService.saveScreeningCase(screeningCase);
    }

    if (isDemo) {
      return screeningCase;
    }

    try {
      final response = await _apiClient.post(
        ApiEndpoints.screenings,
        idempotencyKey: clientRequestId,
        body: {
          'client_request_id': clientRequestId,
          ...patient.toJson(),
        },
      );
      return ScreeningCaseModel.fromJson(response);
    } catch (_) {
      return screeningCase;
    }
  }

  Future<QualityAssessmentModel> assessImageQuality({
    required String screeningId,
    required String imagePath,
    bool isDemo = true,
    Map<String, dynamic>? demoScenario,
  }) async {
    if (isDemo && demoScenario != null) {
      final QualityStatus qStatus = demoScenario['qualityStatus'] as QualityStatus;
      final bool isUngradable = qStatus == QualityStatus.ungradable;
      final bool isBorderline = qStatus == QualityStatus.borderline;

      return QualityAssessmentModel(
        screeningId: screeningId,
        overallScore: (demoScenario['qualityScore'] as num).toDouble(),
        status: qStatus,
        sharpness: QualityMetric(
          score: (demoScenario['sharpness'] as num).toDouble(),
          status: (demoScenario['sharpness'] as num) > 0.5 ? 'GOOD' : 'POOR',
          metricName: 'Laplacian Focus & Sharpness',
        ),
        illumination: QualityMetric(
          score: (demoScenario['illumination'] as num).toDouble(),
          status: (demoScenario['illumination'] as num) > 0.5 ? 'GOOD' : 'ATTENTION',
          metricName: 'Illumination & Exposure',
        ),
        fieldOfView: QualityMetric(
          score: (demoScenario['fov'] as num).toDouble(),
          status: (demoScenario['fov'] as num) > 0.4 ? 'ADEQUATE' : 'INADEQUATE',
          metricName: 'Retinal Mask Field of View',
        ),
        enhancementApplied: isBorderline,
        feedbackMessages: isUngradable
            ? [
                'Severe blur detected on retinal vasculature.',
                'Field illumination sub-optimal.',
                'Recapture required: Please steady the patient and camera.',
              ]
            : isBorderline
                ? ['Sub-optimal exposure detected.', 'Adaptive CLAHE enhancement applied.']
                : ['Optimal focus, exposure, and field coverage confirmed.'],
        evaluatedAt: DateTime.now(),
      );
    }

    // Real Image Quality Assessment (Live PyTorch / OpenCV Backend)
    try {
      final uploadRes = await _apiClient.uploadMultipart(
        ApiEndpoints.screeningImage(screeningId),
        filePath: imagePath,
      );

      if (uploadRes != null && uploadRes is Map && uploadRes.containsKey('quality')) {
        return QualityAssessmentModel.fromJson(
          Map<String, dynamic>.from(uploadRes['quality'] as Map),
          screeningId: screeningId,
        );
      }

      final response = await _apiClient.get(ApiEndpoints.screeningQuality(screeningId));
      return QualityAssessmentModel.fromJson(
        Map<String, dynamic>.from(response as Map),
        screeningId: screeningId,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        'Unable to connect to Drishti PyTorch backend at ${ApiEndpoints.baseUrl}. Please ensure the server is online.',
        details: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> analyzeScreening({
    required String screeningId,
    required QualityAssessmentModel quality,
    bool isDemo = false,
    Map<String, dynamic>? demoScenario,
  }) async {
    // Safety Gate: UNGRADABLE images strictly block automated DR classification
    if (quality.isUngradable) {
      throw UngradableImageException(
        'Automated DR screening is blocked because the retinal photograph is ungradable. A clear recapture is required for patient safety.',
      );
    }

    if (isDemo && demoScenario != null) {
      final int level = demoScenario['expectedLevel'] ?? 2;
      final Map<int, double> classProbs = Map<int, double>.from(demoScenario['classProbs'] ?? {});
      final double modelProb = (demoScenario['modelProb'] as num?)?.toDouble() ?? 0.914;

      final prediction = DRPredictionModel(
        screeningId: screeningId,
        drLevel: level,
        severityLabel: demoScenario['title'] ?? 'Moderate NPDR',
        severityCode: 'LEVEL_$level',
        referable: demoScenario['expectedReferable'] ?? (level >= 2),
        modelProbability: modelProb,
        calibratedConfidence: null,
        classProbabilities: classProbs,
        reviewPriority: level >= 2 ? 'HIGH' : 'NORMAL',
        recommendation: 'Ophthalmologist review and dilated fundus examination recommended.',
        provenance: ModelProvenanceModel.defaultProvenance,
        analyzedAt: DateTime.now(),
      );

      final explainability = ExplainabilityModel(
        screeningId: screeningId,
        targetLayer: 'layer4[1].conv2',
        gradcamImageUrl: demoScenario['gradcamAsset'] ?? 'assets/sample_fundus/real_aptos_gradcam_level_2_094858f005ab.png',
        overlayImageUrl: demoScenario['gradcamAsset'] ?? 'assets/sample_fundus/real_aptos_gradcam_level_2_094858f005ab.png',
        originalImageUrl: demoScenario['imageAsset'] ?? 'assets/sample_fundus/sample_good_npdr_moderate.png',
        modelAttendedRegions: List<String>.from(demoScenario['attendedRegions'] ?? ['Posterior pole', 'Perimacular region']),
        disclaimer: 'Highlighted regions represent areas contributing to the model prediction (Interpretability tool — not a definitive lesion diagnosis).',
      );

      return {
        'prediction': prediction,
        'explainability': explainability,
      };
    }

    // Strict Real Inference Path — Calls Live PyTorch ResNet-18 Engine
    try {
      final response = await _apiClient.post(ApiEndpoints.screeningAnalyze(screeningId));
      if (response == null || response is! Map) {
        throw ModelUnavailableException('Empty or invalid response received from PyTorch inference engine.');
      }
      final pred = DRPredictionModel.fromJson(
        Map<String, dynamic>.from(response as Map),
        screeningId: screeningId,
      );
      
      final expResponse = await _apiClient.get(ApiEndpoints.screeningExplainability(screeningId));
      final explainability = ExplainabilityModel.fromJson(
        Map<String, dynamic>.from(expResponse as Map),
      );

      return {
        'prediction': pred,
        'explainability': explainability,
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw ModelUnavailableException(
        'Failed to execute PyTorch ResNet-18 model inference on backend. Server error: $e',
      );
    }
  }
}
