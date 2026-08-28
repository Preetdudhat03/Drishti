class ApiEndpoints {
  static String baseUrl = 'http://localhost:5000/api/v1';

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';

  // Screening Session & Image
  static String get screenings => '$baseUrl/screenings';
  static String screeningById(String id) => '$baseUrl/screenings/$id';
  static String screeningImage(String id) => '$baseUrl/screenings/$id/image';
  static String screeningQuality(String id) => '$baseUrl/screenings/$id/quality';
  static String screeningAnalyze(String id) => '$baseUrl/screenings/$id/analyze';
  static String screeningExplainability(String id) => '$baseUrl/screenings/$id/explainability';

  // Reviews
  static String get pendingReviews => '$baseUrl/reviews/pending';
  static String submitReview(String id) => '$baseUrl/reviews/$id/submit';

  // Offline Sync
  static String get syncBatch => '$baseUrl/sync/batch';

  // System Status
  static String get systemStatus => '$baseUrl/system/status';
}
