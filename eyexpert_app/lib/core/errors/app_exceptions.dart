class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: [$code] $message';
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code = 'NETWORK_UNAVAILABLE', super.details});
}

class UngradableImageException extends AppException {
  UngradableImageException(super.message, {super.code = 'IMAGE_UNGRADABLE', super.details});
}

class ModelUnavailableException extends AppException {
  ModelUnavailableException(super.message, {super.code = 'MODEL_UNAVAILABLE', super.details});
}

class AuthException extends AppException {
  AuthException(super.message, {super.code = 'AUTHENTICATION_FAILED', super.details});
}

class OfflineSyncException extends AppException {
  OfflineSyncException(super.message, {super.code = 'SYNC_FAILED', super.details});
}
