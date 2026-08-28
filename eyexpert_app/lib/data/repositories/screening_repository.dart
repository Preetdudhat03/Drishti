import '../models/patient_model.dart';
import '../models/quality_assessment_model.dart';
import '../models/screening_case_model.dart';
import '../services/screening_service.dart';
import '../services/sync_service.dart';

class ScreeningRepository {
  final ScreeningService _screeningService;
  final SyncService _syncService;

  ScreeningRepository({
    required ScreeningService screeningService,
    required SyncService syncService,
  })  : _screeningService = screeningService,
        _syncService = syncService;

  Future<ScreeningCaseModel> createScreening({
    required PatientModel patient,
    required String clientRequestId,
    bool isDemo = false,
  }) async {
    return _screeningService.createScreening(
      patient: patient,
      clientRequestId: clientRequestId,
      isDemo: isDemo,
    );
  }

  Future<QualityAssessmentModel> checkQuality({
    required String screeningId,
    required String imagePath,
    bool isDemo = false,
  }) async {
    return _screeningService.assessImageQuality(
      screeningId: screeningId,
      imagePath: imagePath,
      isDemo: isDemo,
    );
  }

  Future<Map<String, dynamic>> analyze({
    required String screeningId,
    required QualityAssessmentModel quality,
    String? imagePath,
    bool isDemo = false,
  }) async {
    return _screeningService.analyzeScreening(
      screeningId: screeningId,
      quality: quality,
      imagePath: imagePath,
      isDemo: isDemo,
    );
  }
}
