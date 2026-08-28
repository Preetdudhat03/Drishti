import '../../core/constants/dr_severity.dart';

class ModelProvenanceModel {
  final String modelId;
  final String modelName;
  final String architecture;
  final String trainingDataset;
  final String modelVersion;
  final String preprocessingVersion;
  final String? calibrationVersion;
  final Map<String, dynamic>? validationBenchmark;

  const ModelProvenanceModel({
    required this.modelId,
    required this.modelName,
    required this.architecture,
    required this.trainingDataset,
    required this.modelVersion,
    required this.preprocessingVersion,
    this.calibrationVersion,
    this.validationBenchmark,
  });

  factory ModelProvenanceModel.fromJson(Map<String, dynamic> json) {
    return ModelProvenanceModel(
      modelId: json['model_id'] ?? 'eyexpert-dr-resnet18',
      modelName: json['model_name'] ?? 'EyeXpert DR Classifier',
      architecture: json['architecture'] ?? 'ResNet-18 (Transfer Learning)',
      trainingDataset: json['training_dataset'] ?? 'APTOS 2019 Blindness Detection',
      modelVersion: json['model_version'] ?? 'v1.2.0',
      preprocessingVersion: json['preprocessing_version'] ?? 'preprocess-v1.1',
      calibrationVersion: json['calibration_version'],
      validationBenchmark: json['validation_benchmark'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_id': modelId,
      'model_name': modelName,
      'architecture': architecture,
      'training_dataset': trainingDataset,
      'model_version': modelVersion,
      'preprocessing_version': preprocessingVersion,
      'calibration_version': calibrationVersion,
      'validation_benchmark': validationBenchmark,
    };
  }

  static const ModelProvenanceModel defaultProvenance = ModelProvenanceModel(
    modelId: 'eyexpert-dr-resnet18',
    modelName: 'EyeXpert DR Classifier',
    architecture: 'ResNet-18 (Transfer Learning)',
    trainingDataset: 'APTOS 2019 Blindness Detection',
    modelVersion: 'v1.2.0',
    preprocessingVersion: 'preprocess-v1.1',
    calibrationVersion: null,
    validationBenchmark: {
      'dataset': 'APTOS 2019',
      'evaluation_type': 'Held-out Stratified Test Set',
      'qwk': null,
      'auc_referable_dr': null,
      'status': 'PENDING_BENCHMARK_EVALUATION',
    },
  );
}

class DRPredictionModel {
  final String screeningId;
  final int drLevel;
  final String severityLabel;
  final String severityCode;
  final bool referable;
  final double modelProbability;
  final double? calibratedConfidence;
  final Map<int, double> classProbabilities;
  final String reviewPriority; // 'HIGH' or 'NORMAL'
  final String recommendation;
  final ModelProvenanceModel provenance;
  final DateTime analyzedAt;

  const DRPredictionModel({
    required this.screeningId,
    required this.drLevel,
    required this.severityLabel,
    required this.severityCode,
    required this.referable,
    required this.modelProbability,
    this.calibratedConfidence,
    required this.classProbabilities,
    this.reviewPriority = 'NORMAL',
    required this.recommendation,
    required this.provenance,
    required this.analyzedAt,
  });

  DRSeverity get severity => DRSeverity.fromLevel(drLevel);

  factory DRPredictionModel.fromJson(Map<String, dynamic> json, {String? screeningId}) {
    final pred = json['prediction'] ?? json;
    final Map<int, double> classProbs = {};
    if (pred['class_probabilities'] != null) {
      (pred['class_probabilities'] as Map).forEach((key, value) {
        final int k = int.tryParse(key.toString()) ?? 0;
        classProbs[k] = (value as num).toDouble();
      });
    }

    final int level = (pred['dr_level'] as num?)?.toInt() ?? (pred['level'] as num?)?.toInt() ?? 0;

    return DRPredictionModel(
      screeningId: screeningId ?? json['screening_id'] ?? '',
      drLevel: level,
      severityLabel: pred['severity_label'] ?? DRSeverity.fromLevel(level).fullName,
      severityCode: pred['severity_code'] ?? 'LEVEL_$level',
      referable: pred['referable'] ?? DRSeverity.checkIsReferable(level),
      modelProbability: (pred['model_probability'] as num?)?.toDouble() ?? 0.0,
      calibratedConfidence: (pred['calibrated_confidence'] as num?)?.toDouble(),
      classProbabilities: classProbs,
      reviewPriority: pred['review_priority'] ?? (level >= 2 ? 'HIGH' : 'NORMAL'),
      recommendation: pred['recommendation'] ?? DRSeverity.fromLevel(level).recommendation,
      provenance: json['model_provenance'] != null
          ? ModelProvenanceModel.fromJson(json['model_provenance'])
          : ModelProvenanceModel.defaultProvenance,
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.tryParse(json['analyzed_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, double> strClassProbs = {};
    classProbabilities.forEach((k, v) => strClassProbs[k.toString()] = v);

    return {
      'screening_id': screeningId,
      'prediction': {
        'dr_level': drLevel,
        'severity_label': severityLabel,
        'severity_code': severityCode,
        'referable': referable,
        'model_probability': modelProbability,
        'calibrated_confidence': calibratedConfidence,
        'class_probabilities': strClassProbs,
        'review_priority': reviewPriority,
        'recommendation': recommendation,
      },
      'model_provenance': provenance.toJson(),
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }
}
