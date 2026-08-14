import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../models/analysis_result.dart';
import 'deepseek_service.dart';

class GeminiService {
  final DeepSeekService _deepSeekService = DeepSeekService();

  GeminiService();

  Future<GenerativeModel> _getModel() async {
    final prefs = await SharedPreferences.getInstance();
    final useCustomKey = prefs.getBool('use_custom_gemini_api_key') ?? false;
    final customKey = prefs.getString('custom_gemini_api_key');
    final activeKey = (useCustomKey && customKey != null && customKey.trim().isNotEmpty)
        ? customKey.trim()
        : AppConfig.geminiApiKey;

    return GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: activeKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }

  Future<AnalysisResult> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) async {
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
      final model = await _getModel();
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final json = jsonDecode(text) as Map<String, dynamic>;
      return AnalysisResult.fromJson(json);
    } catch (e) {
      debugPrint('GeminiService error ($e). Attempting fallback to DeepSeekService...');
      final deepSeekResult = await _deepSeekService.analyzeIngredients(
        profile: profile,
        allergens: allergens,
        ingredients: ingredients,
      );
      if (deepSeekResult != null) {
        return deepSeekResult;
      }
      return const AnalysisResult(
        overallSafety: SafetyLevel.caution,
        summaryTh: 'ไม่สามารถวิเคราะห์ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
        summaryEn: 'Unable to analyze at this time. Please try again.',
      );
    }
  }

  /// Validates a custom API Key by running a lightweight test request.
  /// Returns null if the key is valid and has active quota,
  /// otherwise returns a user-friendly error message.
  Future<String?> validateApiKey(String apiKey) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.5-flash',
        apiKey: apiKey.trim(),
      );
      final response = await model.generateContent([Content.text('Say OK')]);
      if (response.text != null) {
        return null; // Success!
      } else {
        return 'No response from model';
      }
    } on GenerativeAIException catch (e) {
      final msg = e.message;
      if (msg.contains('API_KEY_INVALID') || msg.contains('400')) {
        return 'API Key ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง (Invalid API Key)';
      } else if (msg.contains('RESOURCE_EXHAUSTED') || msg.contains('429')) {
        return 'โควตาเต็ม หรือสิทธิ์บัญชีฟรีเป็น 0 (Quota Exceeded / Limit 0)';
      } else if (msg.contains('NOT_FOUND') || msg.contains('404')) {
        return 'ไม่พบโมเดลนี้ในคีย์ของคุณ (Model Not Found)';
      }
      return msg;
    } catch (e) {
      return e.toString();
    }
  }

  /// Fetches the list of all available Gemini model display names for a given API Key.
  /// Returns a list of strings if successful, otherwise returns null.
  Future<List<String>?> getAvailableModels(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey.trim()}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final modelsList = data['models'] as List<dynamic>?;
        if (modelsList != null) {
          final List<String> names = [];
          for (var m in modelsList) {
            final name = m['name'] as String? ?? '';
            final displayName = m['displayName'] as String? ?? '';
            final supportedMethods = m['supportedGenerationMethods'] as List<dynamic>? ?? [];
            if (name.isNotEmpty && supportedMethods.contains('generateContent')) {
              final cleanName = name.replaceFirst('models/', '');
              names.add(displayName.isNotEmpty ? '$displayName ($cleanName)' : cleanName);
            }
          }
          return names;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks a list of unknown/unrecognized ingredient terms for typos using Gemini AI
  /// and returns a map of typo -> corrected standard INCI name.
  Future<Map<String, String>> checkIngredientTypos(List<String> unknownIngredients) async {
    if (unknownIngredients.isEmpty) return {};

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
      final model = await _getModel();
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final json = jsonDecode(text) as Map<String, dynamic>;
      final Map<String, String> result = {};
      json.forEach((key, value) {
        if (value is String && value.isNotEmpty && key.trim().toLowerCase() != value.trim().toLowerCase()) {
          result[key] = value;
        }
      });
      return result;
    } catch (_) {
      return await _deepSeekService.checkIngredientTypos(unknownIngredients);
    }
  }
}
