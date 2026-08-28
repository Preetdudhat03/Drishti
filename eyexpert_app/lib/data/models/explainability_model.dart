class ExplainabilityModel {
  final String screeningId;
  final String targetLayer;
  final String gradcamImageUrl;
  final String overlayImageUrl;
  final String originalImageUrl;
  final List<String> modelAttendedRegions;
  final String disclaimer;

  const ExplainabilityModel({
    required this.screeningId,
    required this.targetLayer,
    required this.gradcamImageUrl,
    required this.overlayImageUrl,
    required this.originalImageUrl,
    required this.modelAttendedRegions,
    required this.disclaimer,
  });

  factory ExplainabilityModel.fromJson(Map<String, dynamic> json) {
    return ExplainabilityModel(
      screeningId: json['screening_id'] ?? '',
      targetLayer: json['target_layer'] ?? 'layer4[1].conv2',
      gradcamImageUrl: json['gradcam_image_url'] ?? '',
      overlayImageUrl: json['overlay_image_url'] ?? '',
      originalImageUrl: json['original_image_url'] ?? '',
      modelAttendedRegions: (json['model_attended_regions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Posterior retinal pole', 'Perimacular region'],
      disclaimer: json['disclaimer'] ??
          'Highlighted regions represent areas contributing to the model prediction (Interpretability tool — not a definitive lesion diagnosis).',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screening_id': screeningId,
      'target_layer': targetLayer,
      'gradcam_image_url': gradcamImageUrl,
      'overlay_image_url': overlayImageUrl,
      'original_image_url': originalImageUrl,
      'model_attended_regions': modelAttendedRegions,
      'disclaimer': disclaimer,
    };
  }
}
