import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'inci_search_service.dart';

final adminModerationServiceProvider = Provider<AdminModerationService>((ref) {
  final inciSearchService = ref.watch(inciSearchServiceProvider);
  return AdminModerationService(inciSearchService);
});

class ModerationEvaluation {
  final int confidenceScore;
  final List<String> flags;
  final List<String> unrecognizedIngredients;
  final double inciMatchRate;
  final Map<String, int> deductions;

  const ModerationEvaluation({
    required this.confidenceScore,
    required this.flags,
    this.unrecognizedIngredients = const [],
    this.inciMatchRate = 1.0,
    this.deductions = const {},
  });

  bool get isHighConfidence => confidenceScore >= 80;
  bool get needsInspection => confidenceScore >= 50 && confidenceScore < 80;
  bool get isLowConfidence => confidenceScore < 50;
}

class AdminModerationService {
  final InciSearchService _inciSearchService;

  AdminModerationService(this._inciSearchService);

  Future<ModerationEvaluation> evaluateProduct(Product product) async {
    int score = 100;
    final flags = <String>[];
    final deductions = <String, int>{};
    List<String> unrecognized = [];
    double inciRate = 1.0;

    // 1. Name length check
    if (product.name.trim().length < 3) {
      flags.add('short_name');
      score -= 30;
      deductions['short_name'] = -30;
    }

    // 2. Brand check
    if (product.brand == null || product.brand!.trim().isEmpty) {
      flags.add('missing_brand');
      score -= 15;
      deductions['missing_brand'] = -15;
    }

    // 3. Spam detection
    if (_isSpam(product)) {
      flags.add('suspected_spam');
      score -= 40;
      deductions['suspected_spam'] = -40;
    }

    // 4. INCI ingredient recognition rate check
    if (product.ingredients.isEmpty) {
      flags.add('no_ingredients');
      score -= 20;
      deductions['no_ingredients'] = -20;
      inciRate = 0.0;
    } else {
      unrecognized = await _inciSearchService.filterUnrecognizedIngredients(product.ingredients);
      final total = product.ingredients.length;
      final recognizedCount = total - unrecognized.length;
      inciRate = total > 0 ? recognizedCount / total : 0.0;

      if (unrecognized.isNotEmpty) {
        flags.add('unrecognized_ingredients');
        if (inciRate < 0.5) {
          flags.add('low_inci_match');
          score -= 40;
          deductions['low_inci_match'] = -40;
        } else if (inciRate < 0.8) {
          flags.add('partial_inci_match');
          score -= 20;
          deductions['partial_inci_match'] = -20;
        } else {
          score -= 10;
          deductions['unrecognized_ingredients'] = -10;
        }
      }
    }

    final finalScore = score.clamp(0, 100);
    return ModerationEvaluation(
      confidenceScore: finalScore,
      flags: flags,
      unrecognizedIngredients: unrecognized,
      inciMatchRate: inciRate,
      deductions: deductions,
    );
  }

  bool _isSpam(Product product) {
    final textToCheck = '${product.name} ${product.brand ?? ''} ${product.rawIngredientsText ?? ''}'.toLowerCase();
    
    // Check for URLs
    if (textToCheck.contains('http://') ||
        textToCheck.contains('https://') ||
        textToCheck.contains('www.')) {
      return true;
    }

    // Check for repetitive characters (e.g. "aaaaa")
    final repeatPattern = RegExp(r'(.)\1{4,}');
    if (repeatPattern.hasMatch(textToCheck)) {
      return true;
    }

    return false;
  }
}
