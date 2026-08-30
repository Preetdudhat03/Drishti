import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/quality_assessment_model.dart';
import '../../data/models/dr_prediction_model.dart';
import '../../data/models/explainability_model.dart';
import '../../data/models/screening_case_model.dart';
import '../../data/services/screening_service.dart';
import '../../data/repositories/screening_repository.dart';
import '../review/review_queue_provider.dart';
import '../offline/sync_queue_provider.dart';
import '../../data/services/supabase_service.dart';

final screeningServiceProvider = Provider<ScreeningService>((ref) => ScreeningService());

final screeningRepositoryProvider = Provider<ScreeningRepository>((ref) {
  final screeningService = ref.watch(screeningServiceProvider);
  return ScreeningRepository(
    screeningService: screeningService,
  );
});

class ScreeningSessionState {
  final PatientModel? patient;
  final String? clientRequestId;
  final String? screeningId;
  final String? imagePath;
  final QualityAssessmentModel? quality;
  final DRPredictionModel? prediction;
  final ExplainabilityModel? explainability;
  final ScreeningStatus status;
  final bool isProcessing;
  final int processingStep; // 1: Quality, 2: Preprocessing, 3: AI Inference, 4: Grad-CAM
  final String? processingStepLabel;
  final String? errorMessage;

  const ScreeningSessionState({
    this.patient,
    this.clientRequestId,
    this.screeningId,
    this.imagePath,
    this.quality,
    this.prediction,
    this.explainability,
    this.status = ScreeningStatus.created,
    this.isProcessing = false,
    this.processingStep = 0,
    this.processingStepLabel,
    this.errorMessage,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get isQualityAssessed => quality != null;
  bool get isUngradable => quality?.isUngradable ?? false;
  bool get isBorderline => quality?.isBorderline ?? false;
  bool get isResultReady => prediction != null && status == ScreeningStatus.readyForReview;

  ScreeningCaseModel? toScreeningCase() {
    if (patient == null || screeningId == null) return null;
    return ScreeningCaseModel(
      screeningId: screeningId!,
      clientRequestId: clientRequestId,
      patient: patient!,
      status: status,
      image: imagePath != null
          ? FundusImageData(
              imageId: 'IMG-${screeningId!.replaceAll("EX-", "")}',
              imageUrl: imagePath!,
              localPath: imagePath,
              uploadedAt: DateTime.now(),
            )
          : null,
      quality: quality,
      prediction: prediction,
      explainability: explainability,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ScreeningSessionState copyWith({
    PatientModel? patient,
    String? clientRequestId,
    String? screeningId,
    String? imagePath,
    QualityAssessmentModel? quality,
    DRPredictionModel? prediction,
    ExplainabilityModel? explainability,
    ScreeningStatus? status,
    bool? isProcessing,
    int? processingStep,
    String? processingStepLabel,
    String? errorMessage,
  }) {
    return ScreeningSessionState(
      patient: patient ?? this.patient,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      screeningId: screeningId ?? this.screeningId,
      imagePath: imagePath ?? this.imagePath,
      quality: quality ?? this.quality,
      prediction: prediction ?? this.prediction,
      explainability: explainability ?? this.explainability,
      status: status ?? this.status,
      isProcessing: isProcessing ?? this.isProcessing,
      processingStep: processingStep ?? this.processingStep,
      processingStepLabel: processingStepLabel ?? this.processingStepLabel,
      errorMessage: errorMessage,
    );
  }
}

class ScreeningSessionNotifier extends StateNotifier<ScreeningSessionState> {
  final ScreeningRepository _repository;
  final Ref _ref;
  final SupabaseService _supabaseService = SupabaseService();

  ScreeningSessionNotifier(this._repository, this._ref)
      : super(const ScreeningSessionState());

  void startNewSession({
    required String patientId,
    int? age,
    String? gender,
    int? diabetesDurationYears,
    required String eye,
  }) {
    // Completely clear any previous session state to prevent stale medical data
    final reqId = 'REQ-${const Uuid().v4()}';
    final sId = 'EX-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final patient = PatientModel(
      patientId: patientId.trim().isEmpty ? 'PT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}' : patientId.trim(),
      age: age,
      gender: gender,
      diabetesDurationYears: diabetesDurationYears,
      eye: eye,
      facilityId: 'PHC-RAMGARH-01',
      createdAt: DateTime.now(),
    );

    state = ScreeningSessionState(
      patient: patient,
      clientRequestId: reqId,
      screeningId: sId,
      status: ScreeningStatus.awaitingImage,
    );
  }

  void setImage({
    required String path,
  }) {
    state = state.copyWith(
      imagePath: path,
      status: ScreeningStatus.imageReceived,
      quality: null,
      prediction: null,
      explainability: null,
    );
  }

  Future<void> runQualityAssessment() async {
    if (state.screeningId == null || state.imagePath == null) return;

    state = state.copyWith(
      isProcessing: true,
      status: ScreeningStatus.qualityAssessment,
      processingStep: 1,
      processingStepLabel: 'Step 1/4: Automated Image Quality & Focus Assessment...',
      errorMessage: null,
    );

    try {
      final q = await _repository.checkQuality(
        screeningId: state.screeningId!,
        imagePath: state.imagePath!,
      );

      final nextStatus = q.isUngradable
          ? ScreeningStatus.ungradable
          : q.isBorderline
              ? ScreeningStatus.borderlineEnhancement
              : ScreeningStatus.readyForReview;

      state = state.copyWith(
        quality: q,
        status: nextStatus,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        status: ScreeningStatus.processingFailed,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> runDeepInference() async {
    if (state.quality == null || state.quality!.isUngradable) {
      state = state.copyWith(
        errorMessage: 'Automated screening blocked. Retake required.',
        status: ScreeningStatus.recaptureRequired,
      );
      return;
    }

    state = state.copyWith(
      isProcessing: true,
      status: ScreeningStatus.aiProcessing,
    );

    try {
      // Step 2: Preprocessing & CLAHE
      state = state.copyWith(
        processingStep: 2,
        processingStepLabel: state.quality!.isBorderline
            ? 'Step 2/5: Applying Green-Channel CLAHE Contrast Enhancement...'
            : 'Step 2/5: Retinal FOV Cropping & 224x224 Tensor Normalization...',
      );
      await Future.delayed(const Duration(milliseconds: 350));

      // Step 3: ResNet-18 Inference
      state = state.copyWith(
        processingStep: 3,
        processingStepLabel: 'Step 3/5: Running PyTorch ResNet-18 Neural Inference...',
      );

      final result = await _repository.analyze(
        screeningId: state.screeningId!,
        quality: state.quality!,
      );

      // Step 4: Grad-CAM Explainability Generation
      state = state.copyWith(
        processingStep: 4,
        processingStepLabel: 'Step 4/5: Generating Layer-4 Grad-CAM Lesion Activation Map...',
      );
      await Future.delayed(const Duration(milliseconds: 350));

      // Step 5: Preparing Clinical Summary
      state = state.copyWith(
        processingStep: 5,
        processingStepLabel: 'Step 5/5: Formatting Clinical Triage Summary & Registering Queue...',
      );
      await Future.delayed(const Duration(milliseconds: 300));

      final pred = result['prediction'] as DRPredictionModel;
      final exp = result['explainability'] as ExplainabilityModel;

      state = state.copyWith(
        prediction: pred,
        explainability: exp,
        status: ScreeningStatus.readyForReview,
        isProcessing: false,
      );

      // Automatically register to clinician review queue and sync to Supabase
      final newCase = state.toScreeningCase();
      if (newCase != null) {
        _ref.read(reviewQueueProvider.notifier).addCase(newCase);
        if (SupabaseService.isInitialized) {
          await _supabaseService.saveScreeningCase(newCase);
        }
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        status: ScreeningStatus.processingFailed,
        errorMessage: e.toString(),
      );
    }
  }

  void resetSession() {
    state = const ScreeningSessionState();
  }
}

final screeningSessionProvider =
    StateNotifierProvider<ScreeningSessionNotifier, ScreeningSessionState>((ref) {
  final repository = ref.watch(screeningRepositoryProvider);
  return ScreeningSessionNotifier(repository, ref);
});
