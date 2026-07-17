import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/app_config.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../models/analysis_result.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConfig.geminiApiKey,
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

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return AnalysisResult.fromJson(json);
    } catch (_) {
      return const AnalysisResult(
        overallSafety: SafetyLevel.caution,
        summaryTh: 'ไม่สามารถวิเคราะห์ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
        summaryEn: 'Unable to analyze at this time. Please try again.',
      );
    }
  }
}
