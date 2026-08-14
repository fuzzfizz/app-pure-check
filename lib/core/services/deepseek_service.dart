import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../models/analysis_result.dart';

class DeepSeekService {
  DeepSeekService();

  bool isOpenRouterKey(String key) {
    return key.trim().toLowerCase().startsWith('sk-or-');
  }

  String _getEndpoint(String key) {
    return isOpenRouterKey(key)
        ? 'https://openrouter.ai/api/v1/chat/completions'
        : 'https://api.deepseek.com/chat/completions';
  }

  String _getModelName(String key) {
    return isOpenRouterKey(key) ? 'deepseek/deepseek-chat' : 'deepseek-chat';
  }

  Map<String, String> _getHeaders(String key) {
    final cleanKey = key.trim();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $cleanKey',
    };
    if (isOpenRouterKey(cleanKey)) {
      headers['HTTP-Referer'] = 'https://purecheck.app';
      headers['X-Title'] = 'PureCheck';
    }
    return headers;
  }

  Future<String?> _getActiveKey() async {
    final prefs = await SharedPreferences.getInstance();
    final useCustomKey = prefs.getBool('use_custom_deepseek_api_key') ?? false;
    final customKey = prefs.getString('custom_deepseek_api_key');
    final activeKey = (useCustomKey && customKey != null && customKey.trim().isNotEmpty)
        ? customKey.trim()
        : AppConfig.deepseekApiKey;

    return activeKey.isNotEmpty ? activeKey : null;
  }

  Future<AnalysisResult?> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) async {
    final apiKey = await _getActiveKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final allergenNames = allergens.map((a) => a.ingredientName).join(', ');
    final prompt = '''
Analyze these cosmetic/skincare product ingredients for a user with the following profile:
- Skin type: ${profile.skinType.value}
- Skin conditions: ${profile.skinConditions.join(', ')}
- Known allergens: $allergenNames
- Skin concerns: ${profile.skinConcerns.join(', ')}
- Ingredients to avoid (preference): ${profile.avoidPreferences.join(', ')}

Product ingredients list: ${ingredients.join(', ')}

Return ONLY valid JSON in this exact format:
{
  "overall_safety": "safe|caution|danger",
  "summary_th": "คำอธิบายภาษาไทย 2-3 ประโยค",
  "summary_en": "English explanation 2-3 sentences",
  "flagged_ingredients": [
    {"name": "ingredient name", "reason": "why flagged", "risk_level": "caution|danger"}
  ],
  "ingredient_breakdown": [
    {"name": "ingredient name", "function": "what it does", "risk_level": "safe|caution|danger"}
  ]
}

Rules:
- overall_safety = "danger" if any known allergen is found
- overall_safety = "caution" if concerning ingredients found but no known allergens
- overall_safety = "safe" if no allergens and no significant concerns
- List ALL ingredients in ingredient_breakdown
- Only flag ingredients that are genuinely concerning for this user's profile
''';

    try {
      final response = await http.post(
        Uri.parse(_getEndpoint(apiKey)),
        headers: _getHeaders(apiKey),
        body: jsonEncode({
          'model': _getModelName(apiKey),
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional cosmetic dermatologist and ingredient safety analyst. Return ONLY valid JSON.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content'] as String? ?? '{}';
        final json = jsonDecode(content) as Map<String, dynamic>;
        return AnalysisResult.fromJson(json);
      } else {
        debugPrint('DeepSeek/OpenRouter API error HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('DeepSeek/OpenRouter API request exception: $e');
      return null;
    }
  }

  /// Validates a custom DeepSeek / OpenRouter API Key by making a lightweight request.
  /// Returns null if valid, or a user-friendly error message.
  Future<String?> validateApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return 'กรุณาระบุ API Key';
    }

    try {
      final response = await http.post(
        Uri.parse(_getEndpoint(cleanKey)),
        headers: _getHeaders(cleanKey),
        body: jsonEncode({
          'model': _getModelName(cleanKey),
          'messages': [
            {'role': 'user', 'content': 'Say OK'},
          ],
          'max_tokens': 10,
        }),
      );

      if (response.statusCode == 200) {
        return null; // Success!
      } else if (response.statusCode == 401) {
        return 'API Key ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง (Invalid API Key)';
      } else if (response.statusCode == 429) {
        return 'โควตาเต็ม หรือยอดเงินคงเหลือไม่พอ (Quota Exceeded / Insufficient Balance)';
      } else {
        final data = jsonDecode(response.body);
        return data['error']?['message'] ?? 'ข้อผิดพลาด HTTP ${response.statusCode}';
      }
    } catch (e) {
      return 'ไม่สามารถเชื่อมต่อกับ API ได้: $e';
    }
  }

  /// Checks a list of unknown/unrecognized ingredient terms for typos using DeepSeek / OpenRouter AI.
  Future<Map<String, String>> checkIngredientTypos(List<String> unknownIngredients) async {
    if (unknownIngredients.isEmpty) return {};

    final apiKey = await _getActiveKey();
    if (apiKey == null || apiKey.isEmpty) return {};

    final prompt = '''
Correct these cosmetic/skincare ingredient typos to standard INCI names.
Input terms: ${jsonEncode(unknownIngredients)}

Return ONLY valid JSON map of typo -> corrected standard INCI name.
Example format:
{
  "Niacinmid": "Niacinamide",
  "Watar": "Water"
}

Rules:
- If a term is already correct or is a valid custom ingredient, do NOT include it in the map.
- Keys must be exact string matches from the input terms.
- Values must be standard INCI names.
''';

    try {
      final response = await http.post(
        Uri.parse(_getEndpoint(apiKey)),
        headers: _getHeaders(apiKey),
        body: jsonEncode({
          'model': _getModelName(apiKey),
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content'] as String? ?? '{}';
        final json = jsonDecode(content) as Map<String, dynamic>;
        final Map<String, String> result = {};
        json.forEach((key, value) {
          if (value is String && value.isNotEmpty && key.trim().toLowerCase() != value.trim().toLowerCase()) {
            result[key] = value;
          }
        });
        return result;
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}
