import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/allergen.dart';
import '../../../../core/models/analysis_result.dart';
import '../../../../core/models/product.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/beauty_facts_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/repositories/scan_repository.dart';

final beautyFactsServiceProvider =
    Provider<BeautyFactsService>((ref) => BeautyFactsService());

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepositoryImpl(
    supabaseService: ref.watch(supabaseServiceProvider),
    beautyFactsService: ref.watch(beautyFactsServiceProvider),
  );
});

class ScanRepositoryImpl implements ScanRepository {
  final SupabaseService supabaseService;
  final BeautyFactsService beautyFactsService;

  ScanRepositoryImpl({
    required this.supabaseService,
    required this.beautyFactsService,
  });

  @override
  Future<Product?> fetchProductByBarcode(String barcode) async {
    final dbProduct = await supabaseService.getProductByBarcode(barcode);
    if (dbProduct != null) {
      return dbProduct;
    }
    return await beautyFactsService.fetchByBarcode(barcode);
  }

  @override
  Future<Product> upsertProduct(Product product) async {
    return await supabaseService.upsertProduct(product);
  }

  @override
  Future<AnalysisResult> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) async {
    try {
      List<Map<String, dynamic>> userApiKeysPayload = [];
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawList = prefs.getStringList('custom_user_api_keys_list_v1');
        if (rawList != null) {
          for (final item in rawList) {
            final map = jsonDecode(item) as Map<String, dynamic>;
            if (map['isEnabled'] == true && (map['key'] as String?)?.isNotEmpty == true) {
              userApiKeysPayload.add({
                'key': (map['key'] as String).trim(),
                'provider': map['provider'],
                'model': map['defaultModel'],
              });
            }
          }
        }
      } catch (_) {}

      final response = await supabaseService.client.functions.invoke(
        'analyze-ingredients',
        body: {
          'profile': profile.toJson(),
          'allergens': allergens.map((a) => a.ingredientName).toList(),
          'ingredients': ingredients,
          if (userApiKeysPayload.isNotEmpty) 'user_api_keys': userApiKeysPayload,
        },
      );

      if (response.status == 200 && response.data is Map<String, dynamic>) {
        return AnalysisResult.fromJson(response.data as Map<String, dynamic>);
      } else if (response.status == 200 && response.data is Map) {
        return AnalysisResult.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (_) {
      // Catch network or function invocation errors and fall back to local rule-based heuristic
    }

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

  @override
  Future<void> saveScanHistory({
    required String userId,
    required String productId,
    required AnalysisResult result,
  }) async {
    await supabaseService.addScanHistory(
      userId: userId,
      productId: productId,
      result: result,
    );
  }
}
