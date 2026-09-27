import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

const String _kLanguagePrefKey = 'drishti_selected_language';

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en') {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLanguagePrefKey);
      if (saved != null && AppLocalizations.supportedLanguages.any((l) => l.code == saved)) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String langCode) async {
    if (state == langCode) return;
    state = langCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguagePrefKey, langCode);
    } catch (_) {}
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

final currentLanguageProvider = Provider<AppLanguage>((ref) {
  final code = ref.watch(localeProvider);
  return AppLocalizations.supportedLanguages.firstWhere(
    (l) => l.code == code,
    orElse: () => AppLocalizations.supportedLanguages.first,
  );
});

// Helper provider for translating strings directly
final trProvider = Provider<String Function(String)>((ref) {
  final langCode = ref.watch(localeProvider);
  return (String key) => AppLocalizations.tr(key, langCode);
});
