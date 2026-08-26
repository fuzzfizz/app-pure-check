import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'inci_search_service.dart';
import 'cosing_verification_service.dart';

final adminModerationServiceProvider = Provider<AdminModerationService>((ref) {
  final inciSearchService = ref.watch(inciSearchServiceProvider);
  final cosIngService = ref.watch(cosIngVerificationServiceProvider);
  return AdminModerationService(inciSearchService, cosIngService);
});

class ModerationEvaluation {
  final int confidenceScore;
  final List<String> flags;
  final List<String> unrecognizedIngredients;
  final List<String> newlyVerifiedIngredients;
  final double inciMatchRate;
  final Map<String, int> deductions;

  const ModerationEvaluation({
    required this.confidenceScore,
    required this.flags,
    this.unrecognizedIngredients = const [],
    this.newlyVerifiedIngredients = const [],
    this.inciMatchRate = 1.0,
    this.deductions = const {},
  });

  bool get isHighConfidence => confidenceScore >= 80;
  bool get needsInspection => confidenceScore >= 50 && confidenceScore < 80;
  bool get isLowConfidence => confidenceScore < 50;

  List<String> get reasonSummaries {
    final list = <String>[];
    if (newlyVerifiedIngredients.isNotEmpty) {
      list.add('สารใหม่ได้รับการตรวจสอบรับรองตาม CosIng และบันทึกลง Cloud แล้ว (${newlyVerifiedIngredients.length} รายการ)');
    }
    if (deductions.containsKey('short_name')) {
      list.add('ชื่อผลิตภัณฑ์สั้นเกินไป (< 3 ตัวอักษร) [หัก 30 คะแนน]');
    }
    if (deductions.containsKey('missing_brand')) {
      list.add('ไม่ระบุชื่อแบรนด์ [หัก 15 คะแนน]');
    }
    if (deductions.containsKey('suspected_spam')) {
      list.add('ตรวจพบรูปแบบสแปมหรือ URL [หัก 40 คะแนน]');
    }
    if (deductions.containsKey('no_ingredients')) {
      list.add('ไม่มีข้อมูลส่วนผสม [หัก 20 คะแนน]');
    }
    if (deductions.containsKey('low_inci_match')) {
      final percent = (inciMatchRate * 100).toStringAsFixed(0);
      list.add('ส่วนผสมตรงกับฐานข้อมูล INCI เพียง $percent% (< 50%) [หัก 40 คะแนน]');
    } else if (deductions.containsKey('partial_inci_match')) {
      final percent = (inciMatchRate * 100).toStringAsFixed(0);
      list.add('ส่วนผสมตรงกับฐานข้อมูล INCI $percent% (50-79%) [หัก 20 คะแนน]');
    } else if (deductions.containsKey('unrecognized_ingredients')) {
      list.add('มีส่วนผสมบางตัวไม่พบในฐานข้อมูล INCI [หัก 10 คะแนน]');
    }

    if (list.isEmpty && confidenceScore == 100) {
      list.add('ข้อมูลสมบูรณ์และผ่านเกณฑ์ความปลอดภัยทั้งหมด (100 คะแนนเต็ม)');
    }
    return list;
  }
}

class AdminModerationService {
  final InciSearchService _inciSearchService;
  final CosIngVerificationService? _cosIngVerificationService;

  AdminModerationService(
    this._inciSearchService, [
    this._cosIngVerificationService,
  ]);

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
    final newlyVerified = <String>[];
    if (product.ingredients.isEmpty) {
      flags.add('no_ingredients');
      score -= 20;
      deductions['no_ingredients'] = -20;
      inciRate = 0.0;
    } else {
      unrecognized = await _inciSearchService.filterUnrecognizedIngredients(product.ingredients);

      // Verify unrecognized with CosIng if service is available
      if (unrecognized.isNotEmpty && _cosIngVerificationService != null) {
        final verifiedList = await _cosIngVerificationService.verifyAndSyncBatch(
          unrecognized,
          autoSyncToSupabase: true,
        );
        if (verifiedList.isNotEmpty) {
          final verifiedSet = verifiedList.map((e) => e.name.trim().toLowerCase()).toSet();
          newlyVerified.addAll(verifiedList.map((e) => e.name));
          unrecognized = unrecognized
              .where((e) => !verifiedSet.contains(e.trim().toLowerCase()))
              .toList();
        }
      }

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
      newlyVerifiedIngredients: newlyVerified,
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
