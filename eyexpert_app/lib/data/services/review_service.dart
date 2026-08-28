import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/clinician_review_model.dart';
import '../models/screening_case_model.dart';
import '../../core/errors/app_exceptions.dart';
import 'mock_data_service.dart';
import 'supabase_service.dart';

class ReviewService {
  final ApiClient _apiClient;
  final SupabaseService _supabaseService;
  List<ScreeningCaseModel> _cachedCases = [];

  ReviewService({ApiClient? apiClient, SupabaseService? supabaseService})
      : _apiClient = apiClient ?? ApiClient(),
        _supabaseService = supabaseService ?? SupabaseService() {
    _cachedCases = MockDataService.getInitialCases();
  }

  List<ScreeningCaseModel> get cachedCases => List.unmodifiable(_cachedCases);

  Future<List<ScreeningCaseModel>> getPendingReviews({bool isDemo = true}) async {
    if (isDemo) {
      // Sort cases by Priority (Referable / Level >= 2 first)
      _cachedCases.sort((a, b) {
        if (a.isReferable && !b.isReferable) return -1;
        if (!a.isReferable && b.isReferable) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return _cachedCases;
    }

    final response = await _apiClient.get(ApiEndpoints.pendingReviews);
    final List<dynamic> casesList = response['cases'] ?? [];
    return casesList.map((c) => ScreeningCaseModel.fromJson(c)).toList();
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

    // Save review to Supabase
    if (SupabaseService.isInitialized) {
      await _supabaseService.recordClinicianReview(
        screeningId: screeningId,
        action: action,
        finalDrLevel: finalDrLevel,
        clinicalNotes: clinicalNotes,
        clinicianName: review.clinicianName ?? 'Dr. Rajesh Kumar',
      );
    }

    if (isDemo) {
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
    }

    final response = await _apiClient.post(
      ApiEndpoints.submitReview(screeningId),
      body: review.toJson(),
    );

    return ScreeningCaseModel.fromJson(response);
  }

  void addCase(ScreeningCaseModel newCase) {
    _cachedCases.insert(0, newCase);
  }
}
