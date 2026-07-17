enum SafetyLevel { safe, caution, danger }

extension SafetyLevelX on SafetyLevel {
  String get labelTh {
    switch (this) {
      case SafetyLevel.safe: return 'ปลอดภัย';
      case SafetyLevel.caution: return 'ควรระวัง';
      case SafetyLevel.danger: return 'พบสารที่แพ้';
    }
  }
  static SafetyLevel fromString(String s) => SafetyLevel.values.firstWhere(
        (e) => e.name == s,
        orElse: () => SafetyLevel.caution,
      );
}

class FlaggedIngredient {
  final String name;
  final String reason;
  final SafetyLevel riskLevel;

  const FlaggedIngredient({
    required this.name,
    required this.reason,
    required this.riskLevel,
  });

  factory FlaggedIngredient.fromJson(Map<String, dynamic> json) => FlaggedIngredient(
        name: json['name'] as String,
        reason: json['reason'] as String,
        riskLevel: SafetyLevelX.fromString(json['risk_level'] as String? ?? 'caution'),
      );
}

class IngredientBreakdown {
  final String name;
  final String? function;
  final SafetyLevel riskLevel;

  const IngredientBreakdown({
    required this.name,
    this.function,
    required this.riskLevel,
  });

  factory IngredientBreakdown.fromJson(Map<String, dynamic> json) => IngredientBreakdown(
        name: json['name'] as String,
        function: json['function'] as String?,
        riskLevel: SafetyLevelX.fromString(json['risk_level'] as String? ?? 'safe'),
      );
}

class AnalysisResult {
  final SafetyLevel overallSafety;
  final String summaryTh;
  final String summaryEn;
  final List<FlaggedIngredient> flaggedIngredients;
  final List<IngredientBreakdown> ingredientBreakdown;

  const AnalysisResult({
    required this.overallSafety,
    required this.summaryTh,
    required this.summaryEn,
    this.flaggedIngredients = const [],
    this.ingredientBreakdown = const [],
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        overallSafety: SafetyLevelX.fromString(json['overall_safety'] as String? ?? 'caution'),
        summaryTh: json['summary_th'] as String? ?? '',
        summaryEn: json['summary_en'] as String? ?? '',
        flaggedIngredients: (json['flagged_ingredients'] as List<dynamic>? ?? [])
            .map((e) => FlaggedIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        ingredientBreakdown: (json['ingredient_breakdown'] as List<dynamic>? ?? [])
            .map((e) => IngredientBreakdown.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'overall_safety': overallSafety.name,
        'summary_th': summaryTh,
        'summary_en': summaryEn,
        'flagged_ingredients': flaggedIngredients
            .map((e) => {'name': e.name, 'reason': e.reason, 'risk_level': e.riskLevel.name})
            .toList(),
        'ingredient_breakdown': ingredientBreakdown
            .map((e) => {'name': e.name, 'function': e.function, 'risk_level': e.riskLevel.name})
            .toList(),
      };
}
