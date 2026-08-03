# Gemini Key Toggle Switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable users to toggle between using the default system Gemini API key and their own custom Gemini API key from the Settings screen.

**Architecture:** Use `SharedPreferences` to persist the toggle state (`use_custom_gemini_api_key`) and the custom key (`custom_gemini_api_key`). Introduce a Riverpod provider `useCustomGeminiKeyProvider` to manage the toggle state. Update `GeminiService` to resolve the active key based on both settings.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, Google Generative AI Dart SDK.

## Global Constraints
- Do not use placeholders (TBD, TODO, etc.).
- Maintain bilingual support (Thai and English).
- Run `flutter analyze` after changes to verify compiler correctness.

---

### Task 1: Update Gemini API Key Providers

**Files:**
- Modify: `lib/core/providers/gemini_api_key_provider.dart`

**Interfaces:**
- Consumes: None
- Produces: `useCustomGeminiKeyProvider` (StateNotifierProvider<UseCustomGeminiKeyNotifier, bool>)

- [ ] **Step 1: Write the implementation code**
  Update the provider file to declare `useCustomGeminiKeyProvider` along with the existing `geminiApiKeyProvider`.

```dart
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

class UseCustomGeminiKeyNotifier extends StateNotifier<bool> {
  static const _key = 'use_custom_gemini_api_key';

  UseCustomGeminiKeyNotifier() : super(false) {
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

final useCustomGeminiKeyProvider = StateNotifierProvider<UseCustomGeminiKeyNotifier, bool>((ref) {
  return UseCustomGeminiKeyNotifier();
});
```

- [ ] **Step 2: Run flutter analyze to verify**
  Run: `flutter analyze`
  Expected: No issues found!

- [ ] **Step 3: Commit**
  ```bash
  git add lib/core/providers/gemini_api_key_provider.dart
  git commit -m "feat: add useCustomGeminiKeyProvider for settings toggle state"
  ```

---

### Task 2: Update Gemini Service to respect toggle state

**Files:**
- Modify: `lib/core/services/gemini_service.dart`

**Interfaces:**
- Consumes: `use_custom_gemini_api_key` and `custom_gemini_api_key` from SharedPreferences.
- Produces: Dynamic resolution of the active key during generative requests.

- [ ] **Step 1: Update GeminiService key resolution**
  Update `_getModel` to verify `useCustomKey` value from `SharedPreferences`.

```dart
  Future<GenerativeModel> _getModel() async {
    final prefs = await SharedPreferences.getInstance();
    final useCustomKey = prefs.getBool('use_custom_gemini_api_key') ?? false;
    final customKey = prefs.getString('custom_gemini_api_key');
    final activeKey = (useCustomKey && customKey != null && customKey.trim().isNotEmpty)
        ? customKey.trim()
        : AppConfig.geminiApiKey;

    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: activeKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }
```

- [ ] **Step 2: Run flutter analyze to verify**
  Run: `flutter analyze`
  Expected: No issues found!

- [ ] **Step 3: Commit**
  ```bash
  git add lib/core/services/gemini_service.dart
  git commit -m "feat: resolve API key dynamically based on use_custom_gemini_api_key toggle"
  ```

---

### Task 3: Update Settings Screen UI

**Files:**
- Modify: `lib/features/account/screens/settings_screen.dart`

**Interfaces:**
- Consumes: `geminiApiKeyProvider` and `useCustomGeminiKeyProvider`
- Produces: Dual list tiles in settings screen (SwitchListTile for toggling, and ListTile for editing the key).

- [ ] **Step 1: Update SettingsScreen build method**
  Add a switch to toggle custom key and automatically open key input dialog if toggled on but the key is empty.

```dart
          // API Key section
          _buildSectionHeader(isTh ? 'ตั้งค่า API Key (เสริม)' : 'API Key Settings (Optional)'),
          SwitchListTile(
            title: Text(isTh ? 'ใช้ Gemini API Key ส่วนตัว' : 'Use Custom Gemini API Key'),
            subtitle: Text(
              isTh
                  ? 'ปิดเพื่อใช้คีย์ของระบบเป็นค่าเริ่มต้น'
                  : 'Toggle to use your own API Key instead of the default',
            ),
            value: ref.watch(useCustomGeminiKeyProvider),
            activeColor: AppColors.primary,
            onChanged: (val) async {
              await ref.read(useCustomGeminiKeyProvider.notifier).setUseCustomKey(val);
              if (val && (apiKey == null || apiKey.trim().isEmpty)) {
                if (context.mounted) {
                  _showApiKeyDialog(context, ref, apiKey);
                }
              }
            },
          ),
          ListTile(
            enabled: ref.watch(useCustomGeminiKeyProvider),
            leading: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
            title: Text(isTh ? 'กรอก Gemini API Key' : 'Enter Gemini API Key'),
            subtitle: Text(
              apiKey != null && apiKey.isNotEmpty
                  ? (isTh
                      ? 'คีย์ส่วนตัว: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}'
                      : 'Custom Key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}')
                  : (isTh ? 'ยังไม่ได้ตั้งค่าคีย์' : 'No key set'),
            ),
            trailing: const Icon(Icons.edit_rounded, size: 20),
            onTap: ref.watch(useCustomGeminiKeyProvider)
                ? () => _showApiKeyDialog(context, ref, apiKey)
                : null,
          ),
          const Divider(),
```

- [ ] **Step 2: Run flutter analyze to verify**
  Run: `flutter analyze`
  Expected: No issues found!

- [ ] **Step 3: Commit**
  ```bash
  git add lib/features/account/screens/settings_screen.dart
  git commit -m "feat: add switch toggle and custom key input row in SettingsScreen"
  ```
