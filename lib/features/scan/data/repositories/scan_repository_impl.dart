import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final SupabaseService _supabaseService;
  final BeautyFactsService _beautyFactsService;
  final GeminiService _geminiService;

  ScanRepositoryImpl({
    required SupabaseService supabaseService,
    required BeautyFactsService beautyFactsService,
    required GeminiService geminiService,
  })  : _supabaseService = supabaseService,
        _beautyFactsService = beautyFactsService,
        _geminiService = geminiService;

  @override
  Future<Product?> fetchProductByBarcode(String barcode) async {
    final dbProduct = await _supabaseService.getProductByBarcode(barcode);
    if (dbProduct != null) {
      return dbProduct;
    }
    return await _beautyFactsService.fetchByBarcode(barcode);
  }

  @override
  Future<Product> upsertProduct(Product product) async {
    return await _supabaseService.upsertProduct(product);
  }

  @override
  Future<AnalysisResult> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) async {
    try {
      final response = await _supabaseService.client.functions.invoke(
        'analyze-ingredients',
        body: {
          'profile': profile.toJson(),
          'allergens': allergens.map((a) => a.ingredientName).toList(),
          'ingredients': ingredients,
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

    return await _geminiService.analyzeIngredients(
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
    await _supabaseService.addScanHistory(
      userId: userId,
      productId: productId,
      result: result,
    );
  }
}
