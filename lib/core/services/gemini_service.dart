import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../models/allergen.dart';
import '../models/cosing_ingredient.dart';
import '../models/user_profile.dart';
import '../models/analysis_result.dart';
import 'deepseek_service.dart';

class GeminiService {
  final DeepSeekService _deepSeekService = DeepSeekService();

  static const List<String> _candidateModels = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    'gemini-1.5-pro',
  ];

  GeminiService();

  Future<String> _getActiveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final useCustomKey = prefs.getBool('use_custom_gemini_api_key') ?? false;
    final customKey = prefs.getString('custom_gemini_api_key');
    final activeKey = (useCustomKey && customKey != null && customKey.trim().isNotEmpty)
        ? customKey.trim()
        : AppConfig.geminiApiKey;
    return activeKey;
  }

  Future<GenerativeModel> _getModel({String modelName = 'gemini-1.5-flash'}) async {
    final activeKey = await _getActiveApiKey();

    return GenerativeModel(
      model: modelName,
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

    for (final modelName in _candidateModels) {
      try {
        final model = await _getModel(modelName: modelName);
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text ?? '{}';
        final json = jsonDecode(text) as Map<String, dynamic>;
        return AnalysisResult.fromJson(json);
      } catch (e) {
        debugPrint('GeminiService model ($modelName) error: $e');
      }
    }

    debugPrint('All Gemini models failed. Attempting fallback to DeepSeekService...');
    final deepSeekResult = await _deepSeekService.analyzeIngredients(
      profile: profile,
      allergens: allergens,
      ingredients: ingredients,
    );
    if (deepSeekResult != null) {
      return deepSeekResult;
    }

    // Heuristic rule-based fallback when AI services are unreachable
    return _buildHeuristicAnalysis(
      profile: profile,
      allergens: allergens,
      ingredients: ingredients,
    );
  }

  AnalysisResult _buildHeuristicAnalysis({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) {
    final List<FlaggedIngredient> flagged = [];
    final List<IngredientBreakdown> breakdown = [];

    for (final ing in ingredients) {
      final normIng = ing.trim().toLowerCase();
      SafetyLevel level = SafetyLevel.safe;
      String? reason;
      const function = 'สารบำรุง/ส่วนผสมเครื่องสำอาง (Cosmetic ingredient)';

      // Check user allergen
      final matchedAllergen = allergens.firstWhere(
        (a) => a.ingredientName.trim().isNotEmpty &&
            (normIng == a.ingredientName.trim().toLowerCase() ||
                normIng.contains(a.ingredientName.trim().toLowerCase())),
        orElse: () => const Allergen(id: '', userId: '', ingredientName: ''),
      );

      if (matchedAllergen.ingredientName.isNotEmpty) {
        level = SafetyLevel.danger;
        reason = 'ตรงกับสารก่อภูมิแพ้ที่คุณบันทึกไว้ (${matchedAllergen.ingredientName})';
        flagged.add(FlaggedIngredient(
          name: ing,
          reason: reason,
          riskLevel: SafetyLevel.danger,
        ));
      } else if (normIng.contains('parfum') || normIng.contains('fragrance')) {
        if (profile.skinType == SkinType.sensitive ||
            profile.avoidPreferences.any((p) => p.toLowerCase().contains('fragrance') || p.toLowerCase().contains('น้ำหอม'))) {
          level = SafetyLevel.caution;
          reason = 'น้ำหอม (Fragrance) อาจก่อให้เกิดการระคายเคืองในผิวแพ้ง่าย';
          flagged.add(FlaggedIngredient(
            name: ing,
            reason: reason,
            riskLevel: SafetyLevel.caution,
          ));
        }
      } else if (normIng == 'alcohol' || normIng == 'alcohol denat.' || normIng == 'ethanol') {
        if (profile.skinType == SkinType.dry || profile.skinType == SkinType.sensitive) {
          level = SafetyLevel.caution;
          reason = 'แอลกอฮอล์เข้มข้น อาจทำให้ผิวแห้งตึงหรือระคายเคือง';
          flagged.add(FlaggedIngredient(
            name: ing,
            reason: reason,
            riskLevel: SafetyLevel.caution,
          ));
        }
      }

      breakdown.add(IngredientBreakdown(
        name: ing,
        function: function,
        riskLevel: level,
      ));
    }

    final hasDanger = flagged.any((f) => f.riskLevel == SafetyLevel.danger);
    final hasCaution = flagged.any((f) => f.riskLevel == SafetyLevel.caution);

    SafetyLevel overall = SafetyLevel.safe;
    String summaryTh;
    String summaryEn;

    if (hasDanger) {
      overall = SafetyLevel.danger;
      summaryTh = 'พบสารที่ตรงกับประวัติภูมิแพ้ของคุณ ควรหลีกเลี่ยงการใช้ผลิตภัณฑ์นี้';
      summaryEn = 'Found ingredients matching your known allergens. Avoid using this product.';
    } else if (hasCaution) {
      overall = SafetyLevel.caution;
      summaryTh = 'พบส่วนผสมที่ควรระวังสำหรับสภาพผิวของคุณ ควรทดสอบการแพ้ก่อนใช้';
      summaryEn = 'Contains ingredients to use with caution for your skin profile. Patch test recommended.';
    } else {
      overall = SafetyLevel.safe;
      summaryTh = 'ไม่พบสารก่อภูมิแพ้หรือสารเคมีอันตราย เหมาะสำหรับสภาพผิวของคุณ';
      summaryEn = 'No known allergens or hazardous chemicals found. Suitable for your skin profile.';
    }

    return AnalysisResult(
      overallSafety: overall,
      summaryTh: summaryTh,
      summaryEn: summaryEn,
      flaggedIngredients: flagged,
      ingredientBreakdown: breakdown,
    );
  }

  /// Validates a custom API Key by running a lightweight test request.
  /// Returns null if the key is valid and has active quota,
  /// otherwise returns a user-friendly error message.
  Future<String?> validateApiKey(String apiKey) async {
    String? lastError;
    for (final modelName in _candidateModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey.trim(),
        );
        final response = await model.generateContent([Content.text('Say OK')]);
        if (response.text != null) {
          return null; // Success!
        }
      } on GenerativeAIException catch (e) {
        final msg = e.message;
        if (msg.contains('API_KEY_INVALID') || msg.contains('400')) {
          return 'API Key ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง (Invalid API Key)';
        } else if (msg.contains('RESOURCE_EXHAUSTED') || msg.contains('429')) {
          return 'โควตาเต็ม หรือสิทธิ์บัญชีฟรีเป็น 0 (Quota Exceeded / Limit 0)';
        }
        lastError = msg;
      } catch (e) {
        lastError = e.toString();
      }
    }
    return lastError ?? 'ไม่สามารถเชื่อมต่อกับโมเดล Gemini ด้วยคีย์นี้ได้';
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

    for (final modelName in _candidateModels) {
      try {
        final model = await _getModel(modelName: modelName);
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
        // Try next candidate model
      }
    }

    return await _deepSeekService.checkIngredientTypos(unknownIngredients);
  }

  /// Validates whether an unknown ingredient name matches standard EU CosIng / US CIR / INCI nomenclature,
  /// categorizes its cosmetic functional category, and provides a Thai description.
  Future<CosIngIngredient?> verifyCosIngIngredient(String rawName) async {
    final term = rawName.trim();
    if (term.isEmpty) return null;

    final prompt = '''
You are an expert cosmetic chemist and regulatory toxicologist specializing in EU CosIng and INCI nomenclature.
Analyze the following ingredient candidate: "$term"

Determine:
1. Is this a valid, authorized cosmetic ingredient according to EU CosIng / CIR / INCI standards? (boolean)
2. What is its standard cosmetic functional category? (e.g. Humectant, Emollient, Active / Vitamin, Surfactant, Preservative, Botanical Extract, UV Filter, etc.)
3. Provide a concise Thai explanation (1-2 sentences) of its cosmetic function and benefits.
4. Confidence score from 0 to 100.

Return ONLY valid JSON in this exact format:
{
  "name": "$term",
  "is_valid_inci": true,
  "cosing_id": "optional cosing reference number or null",
  "category": "e.g. Active / Vitamin C",
  "description_th": "คำอธิบายภาษาไทยสั้นๆ 1-2 ประโยค",
  "confidence_score": 95
}

If the term is nonsense, spam, advertising text (e.g. "100% organic", "best cream"), or completely invalid, return:
{
  "name": "$term",
  "is_valid_inci": false,
  "category": "Invalid",
  "description_th": "ไม่พบในฐานข้อมูลสารเครื่องสำอางสากล",
  "confidence_score": 0
}
''';

    for (final modelName in _candidateModels) {
      try {
        final model = await _getModel(modelName: modelName);
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text ?? '{}';
        final json = jsonDecode(text) as Map<String, dynamic>;
        return CosIngIngredient.fromJson(json);
      } catch (_) {
        // Try next candidate
      }
    }

    return null;
  }
}
