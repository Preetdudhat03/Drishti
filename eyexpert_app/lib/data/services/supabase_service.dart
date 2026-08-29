import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/quality_assessment_model.dart';
import '../models/dr_prediction_model.dart';
import '../models/explainability_model.dart';
import '../models/screening_case_model.dart';
import '../models/clinician_review_model.dart';

class SupabaseService {
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isInitialized => client != null;

  // Initialize Supabase at Application Start
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
        debug: kDebugMode,
      );
      debugPrint('[SupabaseService] Initialized successfully with ${AppConstants.supabaseUrl}');
    } catch (e) {
      debugPrint('[SupabaseService] Initialization warning (offline/local fallback): $e');
    }
  }

  // Auth Operations
  Future<UserModel?> signIn({required String email, required String password}) async {
    final supa = client;
    if (supa == null) return null;

    final response = await supa.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) return null;

    return await fetchUserProfile(user.id);
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String facilityId = 'PHC-RAMGARH-01',
  }) async {
    final supa = client;
    if (supa == null) return null;

    final response = await supa.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role.displayName,
        'facility_id': facilityId,
      },
    );

    final user = response.user;
    if (user == null) return null;

    // Create profile record in 'profiles' table
    try {
      await supa.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'name': fullName,
        'role': role.displayName,
        'facility_id': facilityId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] Profile creation notice: $e');
    }

    return UserModel(
      id: user.id,
      name: fullName,
      role: role,
      organization: facilityId,
    );
  }

  Future<void> signOut() async {
    try {
      await client?.auth.signOut();
    } catch (_) {}
  }

  Future<UserModel?> fetchUserProfile(String userId) async {
    final supa = client;
    if (supa == null) return null;

    try {
      final data = await supa.from('profiles').select().eq('id', userId).maybeSingle();
      if (data != null) {
        return UserModel(
          id: data['id'] ?? userId,
          name: data['name'] ?? 'Medical Officer',
          role: UserRole.fromString(data['role']),
          organization: data['facility_id'] ?? 'PHC-01',
        );
      }
    } catch (e) {
      debugPrint('[SupabaseService] Profile fetch notice: $e');
    }

    final user = supa.auth.currentUser;
    if (user != null) {
      return UserModel(
        id: user.id,
        name: user.userMetadata?['full_name'] ?? user.email ?? 'Healthcare Worker',
        role: UserRole.fromString(user.userMetadata?['role']),
        organization: user.userMetadata?['facility_id'] ?? 'PHC-01',
      );
    }
    return null;
  }

  // Storage Bucket: Upload Captured Fundus Photo
  Future<String?> uploadFundusImage({
    required String screeningId,
    required String facilityId,
    required dynamic imageBytesOrFile,
    required String filename,
  }) async {
    final supa = client;
    if (supa == null) return null;

    try {
      final storagePath = '$facilityId/$screeningId/original/$filename';
      
      if (imageBytesOrFile is Uint8List) {
        await supa.storage.from(AppConstants.storageBucketFundus).uploadBinary(
          storagePath,
          imageBytesOrFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      } else if (imageBytesOrFile is File) {
        await supa.storage.from(AppConstants.storageBucketFundus).upload(
          storagePath,
          imageBytesOrFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      }

      // Retrieve public URL
      final publicUrl = supa.storage.from(AppConstants.storageBucketFundus).getPublicUrl(storagePath);
      
      // Update screenings table with the uploaded image URL
      try {
        await supa.from('screenings').update({'image_url': publicUrl}).eq('screening_id', screeningId);
      } catch (_) {}

      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] Image storage bucket notice: $e');
      // Fallback: If bucket upload fails or RLS policy restricts bucket, encode as compact Data URI
      try {
        String dataUri = '';
        if (imageBytesOrFile is Uint8List) {
          dataUri = 'data:image/jpeg;base64,${base64Encode(imageBytesOrFile)}';
        } else if (imageBytesOrFile is File && imageBytesOrFile.existsSync()) {
          final bytes = await imageBytesOrFile.readAsBytes();
          dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
        if (dataUri.isNotEmpty) {
          await supa.from('screenings').update({'image_url': dataUri}).eq('screening_id', screeningId);
          return dataUri;
        }
      } catch (_) {}
      return null;
    }
  }

  // Database: Save Screening & Clinical Pipeline Results
  Future<bool> saveScreeningCase(ScreeningCaseModel screeningCase) async {
    final supa = client;
    if (supa == null) return false;

    try {
      String? imageUrl = screeningCase.image?.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http') && !imageUrl.startsWith('data:')) {
        try {
          final file = File(imageUrl);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          }
        } catch (_) {}
      }

      // 1. Insert into 'screenings'
      await supa.from('screenings').upsert({
        'screening_id': screeningCase.screeningId,
        'patient_id': screeningCase.patient.patientId,
        'patient_name': 'Patient ${screeningCase.patient.patientId}',
        'age': screeningCase.patient.age,
        'gender': screeningCase.patient.gender,
        'diabetes_duration_years': screeningCase.patient.diabetesDurationYears,
        'eye': screeningCase.patient.eye,
        'facility_id': screeningCase.patient.facilityId,
        'status': screeningCase.status.label,
        'image_url': imageUrl,
        'created_at': screeningCase.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Insert into 'quality_assessments' if available
      if (screeningCase.quality != null) {
        final q = screeningCase.quality!;
        await supa.from('quality_assessments').upsert({
          'screening_id': screeningCase.screeningId,
          'quality_score': q.overallScore,
          'status': q.status.name.toUpperCase(),
          'sharpness_score': q.sharpness.score,
          'illumination_score': q.illumination.score,
          'fov_score': q.fieldOfView.score,
          'clahe_applied': q.enhancementApplied,
          'feedback_messages': q.feedbackMessages,
          'evaluated_at': q.evaluatedAt.toIso8601String(),
        });
      }

      // 3. Insert into 'ai_predictions' if available
      if (screeningCase.prediction != null) {
        final p = screeningCase.prediction!;
        await supa.from('ai_predictions').upsert({
          'screening_id': screeningCase.screeningId,
          'dr_level': p.drLevel,
          'severity_label': p.severityLabel,
          'referable': p.referable,
          'model_probability': p.modelProbability,
          'calibrated_confidence': p.calibratedConfidence,
          'class_probabilities': p.classProbabilities,
          'review_priority': p.referable ? 'HIGH' : 'NORMAL',
          'recommendation': p.recommendation,
          'model_version': p.provenance.modelId,
          'analyzed_at': p.analyzedAt.toIso8601String(),
        });
      }

      // 4. Insert into 'explainability_results' if available
      if (screeningCase.explainability != null) {
        final exp = screeningCase.explainability!;
        await supa.from('explainability_results').upsert({
          'screening_id': screeningCase.screeningId,
          'gradcam_url': exp.gradcamImageUrl,
          'overlay_url': exp.overlayImageUrl,
          'original_url': exp.originalImageUrl.isNotEmpty ? exp.originalImageUrl : imageUrl,
          'target_layer': exp.targetLayer,
          'model_attended_regions': exp.modelAttendedRegions,
          'disclaimer': exp.disclaimer,
          'generated_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('[SupabaseService] Successfully synced screening ${screeningCase.screeningId} to Supabase');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Save screening notice: $e');
      return false;
    }
  }

  // Database: Fetch all screenings with joined pipeline tables
  Future<List<ScreeningCaseModel>> fetchScreeningCases() async {
    final supa = client;
    if (supa == null) return [];

    try {
      final response = await supa
          .from('screenings')
          .select('*, quality_assessments(*), ai_predictions(*), explainability_results(*), clinician_reviews(*)')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final List<ScreeningCaseModel> cases = [];
      final Set<String> seenIds = {};

      for (final item in data) {
        try {
          final Map<String, dynamic> row = Map<String, dynamic>.from(item);
          final sid = row['screening_id'] as String? ?? '';
          if (sid.isEmpty || seenIds.contains(sid)) continue;
          seenIds.add(sid);

          final patient = PatientModel(
            patientId: row['patient_id'] as String? ?? 'PT-UNKNOWN',
            age: (row['age'] as num?)?.toInt() ?? 50,
            gender: row['gender'] as String? ?? 'OTHER',
            diabetesDurationYears: (row['diabetes_duration_years'] as num?)?.toInt() ?? 5,
            eye: row['eye'] as String? ?? 'OD',
            facilityId: row['facility_id'] as String? ?? 'PHC-RAMGARH-01',
            createdAt: row['created_at'] != null
                ? DateTime.tryParse(row['created_at']) ?? DateTime.now()
                : DateTime.now(),
          );

          QualityAssessmentModel? quality;
          final qList = row['quality_assessments'] as List<dynamic>?;
          if (qList != null && qList.isNotEmpty && qList.first is Map) {
            quality = QualityAssessmentModel.fromJson(
              Map<String, dynamic>.from(qList.first as Map),
              screeningId: sid,
            );
          }

          DRPredictionModel? prediction;
          final pList = row['ai_predictions'] as List<dynamic>?;
          if (pList != null && pList.isNotEmpty && pList.last is Map) {
            prediction = DRPredictionModel.fromJson(
              Map<String, dynamic>.from(pList.last as Map),
            );
          }

          ExplainabilityModel? explainability;
          final expList = row['explainability_results'] as List<dynamic>?;
          if (expList != null && expList.isNotEmpty) {
            Map<String, dynamic>? bestExp;
            for (final item in expList) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                final g = m['gradcam_url'] as String? ?? '';
                final o = m['overlay_url'] as String? ?? '';
                if (g.length > 50 || o.length > 50) {
                  bestExp = m;
                  break;
                }
              }
            }
            if (bestExp == null && expList.last is Map) {
              bestExp = Map<String, dynamic>.from(expList.last as Map);
            }
            if (bestExp != null) {
              explainability = ExplainabilityModel.fromJson(bestExp);
            }
          }

          ClinicianReviewModel? review;
          final rList = row['clinician_reviews'] as List<dynamic>?;
          if (rList != null && rList.isNotEmpty && rList.first is Map) {
            review = ClinicianReviewModel.fromJson(
              Map<String, dynamic>.from(rList.first as Map),
            );
          }

          FundusImageData? image;
          final imgUrl = (row['image_url'] as String?)?.isNotEmpty == true
              ? row['image_url'] as String
              : (explainability?.originalImageUrl.isNotEmpty == true)
                  ? explainability!.originalImageUrl
                  : null;

          if (imgUrl != null && imgUrl.isNotEmpty) {
            image = FundusImageData(
              imageId: sid,
              imageUrl: imgUrl,
              uploadedAt: patient.createdAt,
            );
          }

          cases.add(ScreeningCaseModel(
            screeningId: sid,
            patient: patient,
            image: image,
            quality: quality,
            prediction: prediction,
            explainability: explainability,
            review: review,
            status: ScreeningStatus.fromString(row['status'] as String?),
            createdAt: row['created_at'] != null
                ? DateTime.tryParse(row['created_at']) ?? DateTime.now()
                : DateTime.now(),
            updatedAt: row['updated_at'] != null
                ? DateTime.tryParse(row['updated_at']) ?? DateTime.now()
                : DateTime.now(),
          ));
        } catch (e) {
          debugPrint('[SupabaseService] Parse error on row: $e');
        }
      }

      return cases;
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching cases: $e');
      return [];
    }
  }

  // Database: Record Clinician Validation / Override
  Future<bool> recordClinicianReview({
    required String screeningId,
    required ClinicianAction action,
    int? finalDrLevel,
    required String clinicalNotes,
    required String clinicianName,
    String? reviewerId,
  }) async {
    final supa = client;
    if (supa == null) return false;

    try {
      final now = DateTime.now().toIso8601String();
      // 1. Delete previous review row for this screening
      await supa.from('clinician_reviews').delete().eq('screening_id', screeningId);

      // 2. Insert validated review
      await supa.from('clinician_reviews').insert({
        'screening_id': screeningId,
        'reviewer_id': reviewerId ?? supa.auth.currentUser?.id,
        'clinician_name': clinicianName,
        'action': action.label,
        'final_dr_level': finalDrLevel,
        'final_referable': finalDrLevel != null ? finalDrLevel >= 2 : null,
        'clinical_notes': clinicalNotes,
        'reviewed_at': now,
      });

      // 3. Update status on parent screening record
      await supa.from('screenings').update({
        'status': action == ClinicianAction.markUngradable
            ? 'RECAPTURE_REQUIRED'
            : 'COMPLETED',
        'updated_at': now,
      }).eq('screening_id', screeningId);

      // 4. Record immutable audit event
      try {
        await supa.from('audit_events').insert({
          'screening_id': screeningId,
          'event_type': 'CLINICIAN_REVIEW_RECORDED',
          'actor_id': reviewerId ?? supa.auth.currentUser?.id,
          'payload': {
            'action': action.label,
            'final_dr_level': finalDrLevel,
            'notes': clinicalNotes,
          },
          'timestamp': now,
        });
      } catch (_) {}

      debugPrint('[SupabaseService] Successfully recorded clinician review for $screeningId');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Clinician review recording notice: $e');
      return false;
    }
  }

  // Real-Time Screening Stream
  Stream<List<Map<String, dynamic>>>? get screeningsRealtimeStream {
    final supa = client;
    if (supa == null) return null;

    try {
      return supa
          .from('screenings')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);
    } catch (_) {
      return null;
    }
  }
}
