import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeepSeekApiKeyNotifier extends StateNotifier<String?> {
  static const _key = 'custom_deepseek_api_key';

  DeepSeekApiKeyNotifier() : super(null) {
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

final deepSeekApiKeyProvider = StateNotifierProvider<DeepSeekApiKeyNotifier, String?>((ref) {
  return DeepSeekApiKeyNotifier();
});

class UseCustomDeepSeekKeyNotifier extends StateNotifier<bool> {
  static const _key = 'use_custom_deepseek_api_key';

  UseCustomDeepSeekKeyNotifier() : super(false) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_key);
    if (value != null && mounted) {
      state = value;
    }
  }

  Future<void> setUseCustomKey(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final useCustomDeepSeekKeyProvider = StateNotifierProvider<UseCustomDeepSeekKeyNotifier, bool>((ref) {
  return UseCustomDeepSeekKeyNotifier();
});
