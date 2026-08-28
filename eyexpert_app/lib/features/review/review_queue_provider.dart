import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/screening_case_model.dart';
import '../../data/models/clinician_review_model.dart';
import '../../data/services/review_service.dart';
import '../../data/repositories/review_repository.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final reviewService = ref.watch(reviewServiceProvider);
  return ReviewRepository(reviewService: reviewService);
});

class ReviewQueueState {
  final List<ScreeningCaseModel> cases;
  final bool isLoading;
  final String? errorMessage;
  final String filter; // 'ALL', 'REFERABLE', 'PENDING', 'VALIDATED'
  final String searchQuery;

  const ReviewQueueState({
    this.cases = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filter = 'ALL',
    this.searchQuery = '',
  });

  List<ScreeningCaseModel> get filteredCases {
    return cases.where((c) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchPatient = c.patient.patientId.toLowerCase().contains(q);
        final matchScreening = c.screeningId.toLowerCase().contains(q);
        if (!matchPatient && !matchScreening) return false;
      }

      // Status / Category filter
      if (filter == 'REFERABLE') {
        return c.isReferable;
      } else if (filter == 'PENDING') {
        return c.isPendingReview;
      } else if (filter == 'VALIDATED') {
        return c.hasReviewed;
      }
      return true;
    }).toList();
  }

  int get pendingReferableCount =>
      cases.where((c) => c.isReferable && c.isPendingReview).length;
  int get totalPendingCount => cases.where((c) => c.isPendingReview).length;
  int get completedCount => cases.where((c) => c.hasReviewed).length;

  ReviewQueueState copyWith({
    List<ScreeningCaseModel>? cases,
    bool? isLoading,
    String? errorMessage,
    String? filter,
    String? searchQuery,
  }) {
    return ReviewQueueState(
      cases: cases ?? this.cases,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ReviewQueueNotifier extends StateNotifier<ReviewQueueState> {
  final ReviewRepository _repository;

  ReviewQueueNotifier(this._repository) : super(const ReviewQueueState()) {
    loadPendingReviews();
  }

  Future<void> loadPendingReviews() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cases = await _repository.getPendingReviews(isDemo: true);
      state = state.copyWith(cases: cases, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String newFilter) {
    state = state.copyWith(filter: newFilter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<ScreeningCaseModel?> submitClinicianDecision({
    required String screeningId,
    required ClinicianAction action,
    required int? finalDrLevel,
    required String clinicalNotes,
    int? recommendedFollowupDays,
    String? clinicianName,
  }) async {
    try {
      final updatedCase = await _repository.submitReview(
        screeningId: screeningId,
        action: action,
        finalDrLevel: finalDrLevel,
        clinicalNotes: clinicalNotes,
        recommendedFollowupDays: recommendedFollowupDays,
        clinicianName: clinicianName,
        isDemo: true,
      );

      final updatedList = state.cases.map((c) {
        return c.screeningId == screeningId ? updatedCase : c;
      }).toList();

      state = state.copyWith(cases: updatedList);
      return updatedCase;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  void addCase(ScreeningCaseModel newCase) {
    _repository.addScreeningCase(newCase);
    final updatedList = [newCase, ...state.cases];
    state = state.copyWith(cases: updatedList);
  }
}

final reviewQueueProvider =
    StateNotifierProvider<ReviewQueueNotifier, ReviewQueueState>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return ReviewQueueNotifier(repository);
});
