import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/allergen.dart';
import '../../../../core/models/analysis_result.dart';
import '../../../../core/models/product.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/beauty_facts_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/repositories/scan_repository.dart';

final beautyFactsServiceProvider =
    Provider<BeautyFactsService>((ref) => BeautyFactsService());
final geminiServiceProvider =
    Provider<GeminiService>((ref) => GeminiService());

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepositoryImpl(
    supabaseService: ref.watch(supabaseServiceProvider),
    beautyFactsService: ref.watch(beautyFactsServiceProvider),
    geminiService: ref.watch(geminiServiceProvider),
  );
});

class ScanRepositoryImpl implements ScanRepository {
  final SupabaseService supabaseService;
  final BeautyFactsService beautyFactsService;
  final GeminiService geminiService;

  ScanRepositoryImpl({
    required this.supabaseService,
    required this.beautyFactsService,
    required this.geminiService,
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
      // Catch network or function invocation errors and fall back to Gemini client
    }

    return await geminiService.analyzeIngredients(
      profile: profile,
      allergens: allergens,
      ingredients: ingredients,
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
