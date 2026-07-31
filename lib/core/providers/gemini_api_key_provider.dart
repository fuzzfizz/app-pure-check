import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiApiKeyNotifier extends StateNotifier<String?> {
  static const _key = 'custom_gemini_api_key';

  GeminiApiKeyNotifier() : super(null) {
    _initKey();
  }

  Future<void> _initKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_key);
    if (key != null && mounted) {
      state = key;
    }
  }

  Future<void> setKey(String? apiKey) async {
    state = apiKey;
    final prefs = await SharedPreferences.getInstance();
    if (apiKey == null || apiKey.trim().isEmpty) {
      await prefs.remove(_key);
      state = null;
    } else {
      await prefs.setString(_key, apiKey.trim());
      state = apiKey.trim();
    }
  }
}

final geminiApiKeyProvider = StateNotifierProvider<GeminiApiKeyNotifier, String?>((ref) {
  return GeminiApiKeyNotifier();
});
