import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/app_exceptions.dart';
import '../../core/security/secure_storage.dart';

class ApiClient {
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    final token = await SecureStorage.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return headers;
  }

  Future<dynamic> get(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await _httpClient
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 25));
      return _processResponse(response);
    } catch (e) {
      _handleException(e);
    }
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body, String? idempotencyKey}) async {
    try {
      final headers = await _getHeaders(idempotencyKey: idempotencyKey);
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } catch (e) {
      _handleException(e);
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (body != null && body is Map && body.containsKey('error')) {
      final err = body['error'];
      final String code = err['code'] ?? 'UNKNOWN_ERROR';
      final String msg = err['message'] ?? 'An error occurred';
      if (code == 'IMAGE_UNGRADABLE') {
        throw UngradableImageException(msg, code: code, details: err['details']);
      } else if (code == 'MODEL_UNAVAILABLE') {
        throw ModelUnavailableException(msg, code: code);
      } else if (code == 'INVALID_CREDENTIALS' || code == 'UNAUTHORIZED') {
        throw AuthException(msg, code: code);
      } else {
        throw AppException(msg, code: code);
      }
    }

    throw AppException(
      'Request failed with status: ${response.statusCode}',
      code: 'HTTP_${response.statusCode}',
    );
  }

  void _handleException(dynamic e) {
    if (e is AppException) {
      rethrow;
    }
    throw NetworkException(
      'Unable to connect to EyeXpert backend. Please check network connectivity.',
      details: e.toString(),
    );
  }
}
