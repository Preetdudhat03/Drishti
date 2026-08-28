import '../models/screening_case_model.dart';
import '../models/clinician_review_model.dart';
import '../services/review_service.dart';

class ReviewRepository {
  final ReviewService _reviewService;

  ReviewRepository({required ReviewService reviewService}) : _reviewService = reviewService;

  Future<List<ScreeningCaseModel>> getPendingReviews({bool isDemo = true}) async {
    return _reviewService.getPendingReviews(isDemo: isDemo);
  }

  Future<ScreeningCaseModel> submitReview({
    required String screeningId,
    required ClinicianAction action,
    required int? finalDrLevel,
    required String clinicalNotes,
    int? recommendedFollowupDays,
    String? clinicianName,
    bool isDemo = true,
  }) async {
    return _reviewService.submitClinicianReview(
      screeningId: screeningId,
      action: action,
      finalDrLevel: finalDrLevel,
      clinicalNotes: clinicalNotes,
      recommendedFollowupDays: recommendedFollowupDays,
      clinicianName: clinicianName,
      isDemo: isDemo,
    );
  }

  void addScreeningCase(ScreeningCaseModel newCase) {
    _reviewService.addCase(newCase);
  }
}
