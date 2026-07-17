import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../../core/models/analysis_result.dart';
import '../../../core/services/beauty_facts_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../auth/providers/auth_provider.dart';

enum ScanStep { idle, scanning, fetching, verifying, manualEntry, analyzing, error }

class ScanState {
  final ScanStep step;
  final String? barcode;
  final Product? product;
  final AnalysisResult? analysisResult;
  final String? error;

  ScanState({
    this.step = ScanStep.idle,
    this.barcode,
    this.product,
    this.analysisResult,
    this.error,
  });

  ScanState copyWith({
    ScanStep? step,
    String? barcode,
    Product? product,
    AnalysisResult? analysisResult,
    String? error,
  }) {
    return ScanState(
      step: step ?? this.step,
      barcode: barcode ?? this.barcode,
      product: product ?? this.product,
      analysisResult: analysisResult ?? this.analysisResult,
      error: error,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final Ref ref;
  final BeautyFactsService _beautyFactsService = BeautyFactsService();
  final GeminiService _geminiService = GeminiService();

  ScanNotifier(this.ref) : super(ScanState());

  void reset() {
    state = ScanState();
  }

  void startScanning() {
    state = ScanState(step: ScanStep.scanning);
  }

  Future<void> onBarcodeScanned(String barcode) async {
    state = state.copyWith(step: ScanStep.fetching, barcode: barcode);
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      
      // 1. Check local DB
      var product = await supabaseService.getProductByBarcode(barcode);
      
      // 2. Check Open Beauty Facts
      product ??= await _beautyFactsService.fetchByBarcode(barcode);

      if (product != null) {
        state = state.copyWith(step: ScanStep.verifying, product: product);
      } else {
        state = state.copyWith(
          step: ScanStep.manualEntry,
          product: Product(
            id: '',
            barcode: barcode,
            name: '',
            ingredients: [],
            source: ProductSource.userEntered,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(step: ScanStep.error, error: e.toString());
    }
  }

  void setManualProduct(Product product) {
    state = state.copyWith(step: ScanStep.verifying, product: product);
  }

  Future<AnalysisResult?> analyzeAndSave(Product finalProduct) async {
    state = state.copyWith(step: ScanStep.analyzing, product: finalProduct);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final supabaseService = ref.read(supabaseServiceProvider);

      // Save/update product in local DB first to get a valid product ID
      final savedProduct = await supabaseService.upsertProduct(finalProduct);

      // Fetch user profile and allergens
      final profile = await supabaseService.getProfile(user.id);
      final allergens = await supabaseService.getAllergens(user.id);

      if (profile == null) throw Exception('Profile not found');

      // AI Analyze
      final analysis = await _geminiService.analyzeIngredients(
        profile: profile,
        allergens: allergens,
        ingredients: savedProduct.ingredients,
      );

      // Save scan history
      await supabaseService.addScanHistory(
        userId: user.id,
        productId: savedProduct.id,
        result: analysis,
      );

      state = state.copyWith(step: ScanStep.idle, analysisResult: analysis, product: savedProduct);
      return analysis;
    } catch (e) {
      state = state.copyWith(step: ScanStep.error, error: e.toString());
      return null;
    }
  }
}

final scanNotifierProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(ref);
});
