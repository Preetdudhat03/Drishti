import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drishti_app/data/models/user_model.dart';
import 'package:drishti_app/data/services/auth_service.dart';
import 'package:drishti_app/features/auth/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserModel & UserRole Domain Tests', () {
    test('UserRole parsing from diverse string representations', () {
      expect(UserRole.fromString('HEALTH_WORKER'), UserRole.healthWorker);
      expect(UserRole.fromString('Health Worker'), UserRole.healthWorker);
      expect(UserRole.fromString('OPHTHALMOLOGIST'), UserRole.clinician);
      expect(UserRole.fromString('Clinician'), UserRole.clinician);
      expect(UserRole.fromString('Doctor'), UserRole.clinician);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString(null), UserRole.healthWorker);
    });

    test('UserModel JSON serialization & deserialization', () {
      const user = UserModel(
        id: 'USR-TEST-001',
        email: 'doc@drishti.org',
        name: 'Dr. Test Clinician',
        role: UserRole.clinician,
        organization: 'Apex Eye Clinic',
        facilityId: 'FAC-01',
        professionalId: 'REG-12345',
        isActive: true,
      );

      final json = user.toJson();
      expect(json['role'], 'OPHTHALMOLOGIST');
      expect(json['email'], 'doc@drishti.org');
      expect(json['facility_id'], 'FAC-01');

      final reconstructed = UserModel.fromJson(json);
      expect(reconstructed.id, user.id);
      expect(reconstructed.role, UserRole.clinician);
      expect(reconstructed.isClinician, true);
      expect(reconstructed.isHealthWorker, false);
      expect(reconstructed.professionalId, 'REG-12345');
      expect(reconstructed.isActive, true);
    });

    test('UserModel role getters work correctly', () {
      const hw = UserModel(
        id: 'HW-001',
        name: 'Sunita Sharma',
        role: UserRole.healthWorker,
        organization: 'PHC Ramgarh',
      );
      expect(hw.isHealthWorker, true);
      expect(hw.isClinician, false);

      const doc = UserModel(
        id: 'DOC-001',
        name: 'Dr. Rajesh Kumar',
        role: UserRole.clinician,
        organization: 'District Eye Hospital',
      );
      expect(doc.isClinician, true);
      expect(doc.isHealthWorker, false);
    });
  });

  group('AuthState & AuthNotifier Tests', () {
    test('AuthState initial properties and copyWith', () {
      const state = AuthState();
      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
      expect(state.user, isNull);

      const testUser = UserModel(
        id: 'HW-TEST-001',
        email: 'worker@phc.gov.in',
        name: 'PHC Officer',
        role: UserRole.healthWorker,
        organization: 'Ramgarh Tele-Screening Unit',
      );

      final updated = state.copyWith(
        user: testUser,
        isLoading: false,
      );
      expect(updated.isAuthenticated, true);
      expect(updated.isHealthWorker, true);
      expect(updated.isClinician, false);
    });

    test('AuthService rejects empty credentials', () async {
      final authService = AuthService();
      expect(
        () => authService.login(
          username: '',
          password: '',
          roleRequested: UserRole.healthWorker,
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
