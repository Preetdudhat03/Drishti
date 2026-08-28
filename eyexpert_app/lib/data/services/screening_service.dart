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
    bool isDemo = false,
  }) async {
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
  }) async {
    // Safety Gate: UNGRADABLE images strictly block automated DR classification
    if (quality.isUngradable) {
      throw UngradableImageException(
        'Automated DR screening is blocked because the retinal photograph is ungradable. A clear recapture is required for patient safety.',
      );
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
