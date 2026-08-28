enum QualityStatus {
  good,
  borderline,
  ungradable;

  String get label {
    switch (this) {
      case QualityStatus.good:
        return 'GOOD';
      case QualityStatus.borderline:
        return 'BORDERLINE';
      case QualityStatus.ungradable:
        return 'UNGRADABLE';
    }
  }

  static QualityStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'BORDERLINE':
        return QualityStatus.borderline;
      case 'UNGRADABLE':
        return QualityStatus.ungradable;
      case 'GOOD':
      default:
        return QualityStatus.good;
    }
  }
}

class QualityMetric {
  final double score;
  final String status;
  final String metricName;

  const QualityMetric({
    required this.score,
    required this.status,
    required this.metricName,
  });

  factory QualityMetric.fromJson(Map<String, dynamic> json, String defaultName) {
    return QualityMetric(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'GOOD',
      metricName: json['metric'] ?? defaultName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'status': status,
      'metric': metricName,
    };
  }
}

class QualityAssessmentModel {
  final String screeningId;
  final double overallScore;
  final QualityStatus status;
  final QualityMetric sharpness;
  final QualityMetric illumination;
  final QualityMetric fieldOfView;
  final bool enhancementApplied;
  final List<String> feedbackMessages;
  final DateTime evaluatedAt;

  const QualityAssessmentModel({
    required this.screeningId,
    required this.overallScore,
    required this.status,
    required this.sharpness,
    required this.illumination,
    required this.fieldOfView,
    this.enhancementApplied = false,
    required this.feedbackMessages,
    required this.evaluatedAt,
  });

  bool get isUngradable => status == QualityStatus.ungradable;
  bool get isBorderline => status == QualityStatus.borderline;
  bool get isGood => status == QualityStatus.good;

  factory QualityAssessmentModel.fromJson(Map<String, dynamic> json, {String? screeningId}) {
    return QualityAssessmentModel(
      screeningId: screeningId ?? json['screening_id'] ?? '',
      overallScore: (json['overall_score'] as num?)?.toDouble() ??
          (json['overallScore'] as num?)?.toDouble() ??
          0.0,
      status: QualityStatus.fromString(json['status']),
      sharpness: QualityMetric.fromJson(
        json['sharpness'] is Map ? Map<String, dynamic>.from(json['sharpness']) : {},
        'Focus & Sharpness',
      ),
      illumination: QualityMetric.fromJson(
        json['illumination'] is Map ? Map<String, dynamic>.from(json['illumination']) : {},
        'Illumination & Exposure',
      ),
      fieldOfView: QualityMetric.fromJson(
        (json['field_of_view'] ?? json['fov']) is Map
            ? Map<String, dynamic>.from(json['field_of_view'] ?? json['fov'])
            : {},
        'Field of View Coverage',
      ),
      enhancementApplied: json['enhancement_applied'] ?? json['clahe_applied'] ?? false,
      feedbackMessages: ((json['feedback_messages'] ?? json['feedback']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.tryParse(json['evaluated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screening_id': screeningId,
      'overall_score': overallScore,
      'status': status.label,
      'sharpness': sharpness.toJson(),
      'illumination': illumination.toJson(),
      'field_of_view': fieldOfView.toJson(),
      'enhancement_applied': enhancementApplied,
      'feedback_messages': feedbackMessages,
      'evaluated_at': evaluatedAt.toIso8601String(),
    };
  }
}
