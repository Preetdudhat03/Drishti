import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_app/data/models/user_model.dart';
import 'package:drishti_app/data/models/facility_model.dart';
import 'package:drishti_app/data/models/professional_profile_model.dart';
import 'package:drishti_app/data/models/verification_document_model.dart';

void main() {
  group('Profile & Verification Domain Tests', () {
    test('Profile completion percentage calculates accurately based on populated fields', () {
      const basicUser = UserModel(
        id: 'usr-001',
        email: 'doctor@drishti.org',
        name: 'Dr. Priya Sharma',
        role: UserRole.clinician,
        organization: 'District Eye Centre',
      );

      // Basic user should have partial completion
      final initialScore = basicUser.calculateCompletionPercentage();
      expect(initialScore, greaterThanOrEqualTo(30));
      expect(initialScore, lessThan(100));

      // User with full professional info and documents
      final completeUser = basicUser.copyWith(
        phone: '+91 98765 43210',
        address: 'Sector 4, Main Hospital Campus',
        district: 'Ranchi',
        state: 'Jharkhand',
        professionalId: 'NMC-78921-JH',
        professionalProfile: const ProfessionalProfileModel(
          id: 'prof-001',
          userId: 'usr-001',
          qualification: 'MS (Ophthalmology)',
          specialization: 'Vitreo-Retina',
          registrationNumber: 'NMC-78921-JH',
          registrationAuthority: 'NMC',
          facilityName: 'District Eye Centre',
          district: 'Ranchi',
          state: 'Jharkhand',
        ),
        documents: const [
          VerificationDocumentModel(
            id: 'doc-1',
            userId: 'usr-001',
            documentType: 'MEDICAL_REGISTRATION_CERT',
            documentTitle: 'Registration Certificate',
            fileName: 'registration_cert.pdf',
            storagePath: 'usr-001/doc1.pdf',
            verificationStatus: DocumentVerificationStatus.verified,
          ),
          VerificationDocumentModel(
            id: 'doc-2',
            userId: 'usr-001',
            documentType: 'DEGREE_QUALIFICATION',
            documentTitle: 'Degree Certificate',
            fileName: 'degree.pdf',
            storagePath: 'usr-001/doc2.pdf',
            verificationStatus: DocumentVerificationStatus.underReview,
          ),
        ],
      );

      expect(completeUser.calculateCompletionPercentage(), greaterThanOrEqualTo(85));
    });

    test('FacilityModel serialization and type parsing', () {
      const facility = FacilityModel(
        id: 'fac-101',
        facilityName: 'PHC Ramgarh Rural Centre',
        facilityType: FacilityType.phc,
        facilityIdentifier: 'PHC-RAMGARH-01',
        address: 'Main Health Post, Sector 4',
        district: 'Ramgarh',
        state: 'Jharkhand',
        pinCode: '829122',
        contactNumber: '+91 98765 00000',
        cameraAvailable: true,
        cameraManufacturer: 'Remidio',
        cameraModel: 'FOP NM-01',
        connectivityType: ConnectivityType.online,
      );

      final json = facility.toJson();
      expect(json['facility_identifier'], equals('PHC-RAMGARH-01'));
      expect(json['camera_available'], isTrue);

      final parsed = FacilityModel.fromJson(json);
      expect(parsed.facilityName, equals('PHC Ramgarh Rural Centre'));
      expect(parsed.facilityType, equals(FacilityType.phc));
      expect(parsed.cameraManufacturer, equals('Remidio'));
    });

    test('VerificationDocumentModel status mapping and verification flags', () {
      const doc = VerificationDocumentModel(
        id: 'doc-001',
        userId: 'usr-123',
        documentType: 'PHC_REGISTRATION',
        documentTitle: 'Facility Registration',
        fileName: 'reg.pdf',
        storagePath: 'usr-123/reg.pdf',
        verificationStatus: DocumentVerificationStatus.underReview,
      );

      expect(doc.isUploaded, isTrue);
      expect(doc.isVerified, isFalse);

      final verifiedDoc = doc.copyWith(verificationStatus: DocumentVerificationStatus.verified);
      expect(verifiedDoc.isVerified, isTrue);
    });
  });
}
