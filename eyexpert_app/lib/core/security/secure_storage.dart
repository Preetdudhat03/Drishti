import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const String _keyToken = 'drishti_auth_token';
  static const String _keyUser = 'drishti_auth_user';
  static const String _keyWorkflowMode = 'drishti_workflow_mode';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveUserData(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, userJson);
  }

  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUser);
  }

  static Future<void> saveWorkflowMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWorkflowMode, mode);
  }

  static Future<String> getWorkflowMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWorkflowMode) ?? 'DEMO';
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
