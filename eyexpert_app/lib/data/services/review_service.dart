import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/patient_model.dart';
import '../models/clinician_review_model.dart';
import '../models/screening_case_model.dart';
import '../../core/errors/app_exceptions.dart';
import 'supabase_service.dart';

class ReviewService {
  final ApiClient _apiClient;
  final SupabaseService _supabaseService;
  List<ScreeningCaseModel> _cachedCases = [];

  ReviewService({ApiClient? apiClient, SupabaseService? supabaseService})
      : _apiClient = apiClient ?? ApiClient(),
        _supabaseService = supabaseService ?? SupabaseService() {
    _cachedCases = [];
  }

  List<ScreeningCaseModel> get cachedCases => List.unmodifiable(_cachedCases);

  Future<List<ScreeningCaseModel>> getPendingReviews({bool isDemo = false}) async {
    // 1. Fetch real-time cases from Supabase cloud database
    if (SupabaseService.isInitialized) {
      final supaCases = await _supabaseService.fetchScreeningCases();
      supaCases.sort((a, b) {
        if (a.isReferable && !b.isReferable) return -1;
        if (!a.isReferable && b.isReferable) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      _cachedCases = supaCases;
      return supaCases;
    }

    return _cachedCases;
  }

  Future<ScreeningCaseModel> submitClinicianReview({
    required String screeningId,
    required ClinicianAction action,
    required int? finalDrLevel,
    required String clinicalNotes,
    int? recommendedFollowupDays,
    String? clinicianName,
    bool isDemo = true,
  }) async {
    // Validate business rules
    if (action == ClinicianAction.override && (finalDrLevel == null || clinicalNotes.trim().isEmpty)) {
      throw AppException(
        'An override requires selecting a final DR level and providing explanatory clinical notes.',
        code: 'OVERRIDE_NOTES_REQUIRED',
      );
    }

    final review = ClinicianReviewModel(
      action: action,
      clinicianId: 'DOC-DEMO-002',
      clinicianName: clinicianName ?? 'Dr. Rajesh Kumar',
      clinicianRole: 'Ophthalmologist',
      finalDrLevel: finalDrLevel,
      finalDrLabel: finalDrLevel != null ? 'Level $finalDrLevel' : 'Ungradable',
      finalReferable: finalDrLevel != null ? finalDrLevel >= 2 : null,
      clinicalNotes: clinicalNotes,
      recommendedFollowupDays: recommendedFollowupDays ?? 90,
      reviewedAt: DateTime.now(),
    );

    // 1. Primary Cloud Persistence: Save review to Supabase
    if (SupabaseService.isInitialized) {
      await _supabaseService.recordClinicianReview(
        screeningId: screeningId,
        action: action,
        finalDrLevel: finalDrLevel,
        clinicalNotes: clinicalNotes,
        clinicianName: review.clinicianName ?? 'Dr. Rajesh Kumar',
      );
    }

    // 2. Secondary: Notify Python backend if reachable
    try {
      await _apiClient.post(
        ApiEndpoints.submitReview(screeningId),
        body: review.toJson(),
      );
    } catch (_) {
      // Backend may be sleeping; Supabase is our authoritative persistent cloud store
    }

    // 3. Update in-memory / local cached case
    final index = _cachedCases.indexWhere((c) => c.screeningId == screeningId);
    if (index != -1) {
      final existing = _cachedCases[index];
      final updated = existing.copyWith(
        review: review,
        status: action == ClinicianAction.validateAiResult
            ? ScreeningStatus.clinicianValidated
            : action == ClinicianAction.override
                ? ScreeningStatus.clinicianOverridden
                : ScreeningStatus.recaptureRequired,
        updatedAt: DateTime.now(),
      );
      _cachedCases[index] = updated;
      return updated;
    }

    return ScreeningCaseModel(
      screeningId: screeningId,
      patient: PatientModel(patientId: 'PT-SYNC', eye: 'OD', facilityId: 'PHC-01', createdAt: DateTime.now()),
      status: action == ClinicianAction.validateAiResult
          ? ScreeningStatus.clinicianValidated
          : action == ClinicianAction.override
              ? ScreeningStatus.clinicianOverridden
              : ScreeningStatus.recaptureRequired,
      review: review,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void addCase(ScreeningCaseModel newCase) {
    _cachedCases.insert(0, newCase);
  }
}
