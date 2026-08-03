import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/allergen.dart';
import 'package:pure_check/core/models/analysis_result.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:pure_check/features/scan/domain/repositories/scan_repository.dart';
import 'package:pure_check/features/scan/providers/scan_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeScanRepository implements ScanRepository {
  Product? productToReturn;
  bool shouldThrowOnFetch = false;
  bool fetchProductByBarcodeCalled = false;
  String? lastFetchedBarcode;

  bool upsertProductCalled = false;
  Product? lastUpsertedProduct;

  bool analyzeIngredientsCalled = false;
  UserProfile? lastAnalyzedProfile;
  List<Allergen>? lastAnalyzedAllergens;
  List<String>? lastAnalyzedIngredients;

  bool saveScanHistoryCalled = false;
  String? lastSavedUserId;
  String? lastSavedProductId;
  AnalysisResult? lastSavedResult;

  @override
  Future<Product?> fetchProductByBarcode(String barcode) async {
    fetchProductByBarcodeCalled = true;
    lastFetchedBarcode = barcode;
    if (shouldThrowOnFetch) {
      throw Exception('Repository error');
    }
    return productToReturn;
  }

  @override
  Future<Product> upsertProduct(Product product) async {
    upsertProductCalled = true;
    lastUpsertedProduct = product;
    return product;
  }

  @override
  Future<AnalysisResult> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) async {
    analyzeIngredientsCalled = true;
    lastAnalyzedProfile = profile;
    lastAnalyzedAllergens = allergens;
    lastAnalyzedIngredients = ingredients;
    return const AnalysisResult(
      overallSafety: SafetyLevel.safe,
      summaryTh: 'ปลอดภัยจาก FakeScanRepository',
      summaryEn: 'Safe from FakeScanRepository',
    );
  }

  @override
  Future<void> saveScanHistory({
    required String userId,
    required String productId,
    required AnalysisResult result,
  }) async {
    saveScanHistoryCalled = true;
    lastSavedUserId = userId;
    lastSavedProductId = productId;
    lastSavedResult = result;
  }
}

class FakeSupabaseService extends SupabaseService {
  UserProfile? profileToReturn;
  List<Allergen> allergensToReturn = [];

  FakeSupabaseService() : super();

  @override
  Future<UserProfile?> getProfile(String userId) async {
    return profileToReturn;
  }

  @override
  Future<List<Allergen>> getAllergens(String userId) async {
    return allergensToReturn;
  }
}

void main() {
  group('ScanNotifier Unit Tests', () {
    late FakeScanRepository fakeRepo;
    late FakeSupabaseService fakeSupabaseService;

    setUp(() {
      fakeRepo = FakeScanRepository();
      fakeSupabaseService = FakeSupabaseService();
    });

    test('onBarcodeScanned sets step to verifying when product is found in ScanRepository', () async {
      const testProduct = Product(
        id: 'p100',
        barcode: '8851234567890',
        name: 'Found Product',
        ingredients: ['Water'],
      );
      fakeRepo.productToReturn = testProduct;

      final container = ProviderContainer(
        overrides: [
          scanRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(scanNotifierProvider.notifier);

      await notifier.onBarcodeScanned('8851234567890');

      final state = container.read(scanNotifierProvider);
      expect(fakeRepo.fetchProductByBarcodeCalled, isTrue);
      expect(fakeRepo.lastFetchedBarcode, equals('8851234567890'));
      expect(state.step, equals(ScanStep.verifying));
      expect(state.product, equals(testProduct));
    });

    test('onBarcodeScanned sets step to manualEntry when product is null', () async {
      fakeRepo.productToReturn = null;

      final container = ProviderContainer(
        overrides: [
          scanRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(scanNotifierProvider.notifier);

      await notifier.onBarcodeScanned('9999999999999');

      final state = container.read(scanNotifierProvider);
      expect(fakeRepo.fetchProductByBarcodeCalled, isTrue);
      expect(state.step, equals(ScanStep.manualEntry));
      expect(state.product?.barcode, equals('9999999999999'));
      expect(state.product?.source, equals(ProductSource.userEntered));
    });

    test('onBarcodeScanned sets step to error when ScanRepository throws exception', () async {
      fakeRepo.shouldThrowOnFetch = true;

      final container = ProviderContainer(
        overrides: [
          scanRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(scanNotifierProvider.notifier);

      await notifier.onBarcodeScanned('1111');

      final state = container.read(scanNotifierProvider);
      expect(state.step, equals(ScanStep.error));
      expect(state.error, contains('Repository error'));
    });

    test('analyzeAndSave succeeds and calls ScanRepository methods when user is logged in', () async {
      const userProfile = UserProfile(id: 'user_123', skinType: SkinType.sensitive);
      const allergen = Allergen(id: 'a1', userId: 'user_123', ingredientName: 'Fragrance');
      fakeSupabaseService.profileToReturn = userProfile;
      fakeSupabaseService.allergensToReturn = [allergen];

      const testProduct = Product(
        id: 'p1',
        barcode: '8850001',
        name: 'Test Cream',
        ingredients: ['Water', 'Fragrance'],
      );

      final fakeUser = User(
        id: 'user_123',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );

      final container = ProviderContainer(
        overrides: [
          scanRepositoryProvider.overrideWithValue(fakeRepo),
          supabaseServiceProvider.overrideWithValue(fakeSupabaseService),
          currentUserProvider.overrideWithValue(fakeUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(scanNotifierProvider.notifier);

      final result = await notifier.analyzeAndSave(testProduct);

      final state = container.read(scanNotifierProvider);

      expect(fakeRepo.upsertProductCalled, isTrue);
      expect(fakeRepo.lastUpsertedProduct, equals(testProduct));

      expect(fakeRepo.analyzeIngredientsCalled, isTrue);
      expect(fakeRepo.lastAnalyzedProfile, equals(userProfile));
      expect(fakeRepo.lastAnalyzedAllergens, equals([allergen]));
      expect(fakeRepo.lastAnalyzedIngredients, equals(['Water', 'Fragrance']));

      expect(fakeRepo.saveScanHistoryCalled, isTrue);
      expect(fakeRepo.lastSavedUserId, equals('user_123'));
      expect(fakeRepo.lastSavedProductId, equals('p1'));

      expect(result, isNotNull);
      expect(result?.summaryEn, equals('Safe from FakeScanRepository'));
      expect(state.step, equals(ScanStep.idle));
      expect(state.analysisResult, equals(result));
    });

    test('analyzeAndSave sets step to error when user is not logged in', () async {
      const testProduct = Product(
        id: 'p1',
        name: 'Test Product',
        ingredients: [],
      );

      final container = ProviderContainer(
        overrides: [
          scanRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(scanNotifierProvider.notifier);

      final result = await notifier.analyzeAndSave(testProduct);

      final state = container.read(scanNotifierProvider);
      expect(result, isNull);
      expect(state.step, equals(ScanStep.error));
      expect(state.error, contains('User not logged in'));
      expect(fakeRepo.upsertProductCalled, isFalse);
    });
  });
}
