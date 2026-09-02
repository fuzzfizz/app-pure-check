import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_api_key.dart';
import '../services/ai_key_detector_service.dart';

final aiKeyDetectorServiceProvider = Provider<AiKeyDetectorService>((ref) {
  return AiKeyDetectorService();
});

class UserApiKeysNotifier extends StateNotifier<List<UserApiKey>> {
  static const _storageKey = 'custom_user_api_keys_list_v1';
  static const int maxKeysLimit = 3;
  final AiKeyDetectorService _detector;

  UserApiKeysNotifier(this._detector) : super([]) {
    _loadKeys();
  }

  bool get canAddMore => state.length < maxKeysLimit;

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey);

    if (rawList != null && rawList.isNotEmpty) {
      state = rawList
          .map((item) {
            try {
              return UserApiKey.fromJson(jsonDecode(item) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<UserApiKey>()
          .take(maxKeysLimit)
          .toList();
    } else {
      // Migrate legacy single keys if present
      final legacyGemini = prefs.getString('custom_gemini_api_key');
      final legacyDeepSeek = prefs.getString('custom_deepseek_api_key');
      final List<UserApiKey> migrated = [];

      if (legacyGemini != null && legacyGemini.trim().isNotEmpty) {
        final info = _detector.detectProvider(legacyGemini);
        migrated.add(UserApiKey(
          id: 'migrated_gemini',
          key: legacyGemini.trim(),
          provider: info.provider,
          providerName: info.providerName,
          defaultModel: info.defaultModel,
          status: KeyStatus.valid,
          isEnabled: prefs.getBool('use_custom_gemini_api_key') ?? true,
          lastChecked: DateTime.now(),
        ));
      }

      if (legacyDeepSeek != null && legacyDeepSeek.trim().isNotEmpty && migrated.length < maxKeysLimit) {
        final info = _detector.detectProvider(legacyDeepSeek);
        migrated.add(UserApiKey(
          id: 'migrated_deepseek',
          key: legacyDeepSeek.trim(),
          provider: info.provider,
          providerName: info.providerName,
          defaultModel: info.defaultModel,
          status: KeyStatus.valid,
          isEnabled: prefs.getBool('use_custom_deepseek_api_key') ?? true,
          lastChecked: DateTime.now(),
        ));
      }

      if (migrated.isNotEmpty) {
        state = migrated;
        await _saveKeys();
      }
    }
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = state.map((k) => jsonEncode(k.toJson())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  Future<bool> addKey(String rawKey, {DetectedProviderInfo? overrideProvider}) async {
    if (state.length >= maxKeysLimit) {
      return false;
    }

    final cleanKey = rawKey.trim();
    if (cleanKey.isEmpty) return false;

    final info = overrideProvider ?? _detector.detectProvider(cleanKey);
    final probe = await _detector.testKeyQuota(cleanKey, info);

    final newKey = UserApiKey(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      key: cleanKey,
      provider: info.provider,
      providerName: info.providerName,
      defaultModel: info.defaultModel,
      status: probe.status,
      statusMessage: probe.message,
      isEnabled: true,
      lastChecked: DateTime.now(),
    );

    state = [...state, newKey];
    await _saveKeys();
    return true;
  }

  Future<void> removeKey(String id) async {
    state = state.where((k) => k.id != id).toList();
    await _saveKeys();
  }

  Future<void> toggleKey(String id, bool enabled) async {
    state = state.map((k) => k.id == id ? k.copyWith(isEnabled: enabled) : k).toList();
    await _saveKeys();
  }

  Future<void> recheckKey(String id) async {
    final keyItem = state.firstWhere((k) => k.id == id, orElse: () => throw Exception('Key not found'));
    final info = _detector.detectProvider(keyItem.key);
    final probe = await _detector.testKeyQuota(keyItem.key, info);

    state = state.map((k) => k.id == id
        ? k.copyWith(
            status: probe.status,
            statusMessage: probe.message,
            lastChecked: DateTime.now(),
          )
        : k).toList();
    await _saveKeys();
  }

  List<UserApiKey> get activeKeys => state.where((k) => k.isEnabled).toList();
}

final userApiKeysProvider = StateNotifierProvider<UserApiKeysNotifier, List<UserApiKey>>((ref) {
  final detector = ref.watch(aiKeyDetectorServiceProvider);
  return UserApiKeysNotifier(detector);
});
