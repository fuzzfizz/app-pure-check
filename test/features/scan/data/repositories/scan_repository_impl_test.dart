import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/allergen.dart';
import 'package:pure_check/core/models/analysis_result.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/core/services/beauty_facts_service.dart';
import 'package:pure_check/core/services/gemini_service.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:pure_check/features/scan/domain/repositories/scan_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeFunctionsClient implements FunctionsClient {
  FunctionResponse? responseToReturn;
  bool shouldThrow = false;
  String? lastFunctionName;
  Object? lastBody;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #invoke) {
      if (invocation.positionalArguments.isNotEmpty) {
        lastFunctionName = invocation.positionalArguments.first as String;
      }
      lastBody = invocation.namedArguments[#body];
      if (shouldThrow) {
        throw Exception('Edge Function Error');
      }
      return Future.value(
        responseToReturn ??
            FunctionResponse(
              status: 200,
              data: {
                'overall_safety': 'safe',
                'summary_th': 'ปลอดภัยจาก Edge Function',
                'summary_en': 'Safe from Edge Function',
              },
            ),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeSupabaseClient extends SupabaseClient {
  final FakeFunctionsClient fakeFunctions;

  FakeSupabaseClient(this.fakeFunctions)
      : super('https://fake.supabase.co', 'fake_anon_key');

  @override
  FunctionsClient get functions => fakeFunctions;
}

class FakeSupabaseService extends SupabaseService {
  final FakeSupabaseClient mockClient;
  Product? productByBarcode;
  bool getProductByBarcodeCalled = false;
  bool upsertProductCalled = false;
  bool addScanHistoryCalled = false;
  String? lastSavedUserId;
  String? lastSavedProductId;

  FakeSupabaseService(this.mockClient) : super(mockClient);

  @override
  SupabaseClient get client => mockClient;

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    getProductByBarcodeCalled = true;
    return productByBarcode;
  }

  @override
  Future<Product> upsertProduct(Product product) async {
    upsertProductCalled = true;
    return product;
  }

  @override
  Future<void> addScanHistory({
    required String userId,
    required String productId,
    required AnalysisResult result,
  }) async {
    addScanHistoryCalled = true;
    lastSavedUserId = userId;
    lastSavedProductId = productId;
  }
}

class FakeBeautyFactsService extends BeautyFactsService {
  Product? productByBarcode;
  bool fetchByBarcodeCalled = false;

  @override
  Future<Product?> fetchByBarcode(String barcode) async {
    fetchByBarcodeCalled = true;
    return productByBarcode;
  }
}

class FakeGeminiService extends GeminiService {
  AnalysisResult? resultToReturn;
  bool analyzeIngredientsCalled = false;

  @override
  Future<AnalysisResult> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) async {
    analyzeIngredientsCalled = true;
    return resultToReturn ??
        const AnalysisResult(
          overallSafety: SafetyLevel.caution,
          summaryTh: 'วิเคราะห์โดย Gemini Client',
          summaryEn: 'Analyzed by Gemini Client',
        );
  }
}

void main() {
  group('ScanRepositoryImpl Unit Tests', () {
    late FakeFunctionsClient fakeFunctions;
    late FakeSupabaseClient fakeSupabaseClient;
    late FakeSupabaseService fakeSupabaseService;
    late FakeBeautyFactsService fakeBeautyFactsService;
    late FakeGeminiService fakeGeminiService;
    late ScanRepositoryImpl repository;

    setUp(() {
      fakeFunctions = FakeFunctionsClient();
      fakeSupabaseClient = FakeSupabaseClient(fakeFunctions);
      fakeSupabaseService = FakeSupabaseService(fakeSupabaseClient);
      fakeBeautyFactsService = FakeBeautyFactsService();
      fakeGeminiService = FakeGeminiService();

      repository = ScanRepositoryImpl(
        supabaseService: fakeSupabaseService,
        beautyFactsService: fakeBeautyFactsService,
        geminiService: fakeGeminiService,
      );
    });

    group('fetchProductByBarcode', () {
      test('returns DB product when found, does not call BeautyFactsService', () async {
        const dbProduct = Product(
          id: 'p1',
          barcode: '12345',
          name: 'DB Shampoo',
          ingredients: ['Water'],
        );
        fakeSupabaseService.productByBarcode = dbProduct;

        final result = await repository.fetchProductByBarcode('12345');

        expect(result, equals(dbProduct));
        expect(fakeSupabaseService.getProductByBarcodeCalled, isTrue);
        expect(fakeBeautyFactsService.fetchByBarcodeCalled, isFalse);
      });

      test('calls BeautyFactsService when DB product is null', () async {
        const obfProduct = Product(
          id: 'p2',
          barcode: '12345',
          name: 'OBF Lotion',
          ingredients: ['Glycerin'],
        );
        fakeSupabaseService.productByBarcode = null;
        fakeBeautyFactsService.productByBarcode = obfProduct;

        final result = await repository.fetchProductByBarcode('12345');

        expect(result, equals(obfProduct));
        expect(fakeSupabaseService.getProductByBarcodeCalled, isTrue);
        expect(fakeBeautyFactsService.fetchByBarcodeCalled, isTrue);
      });

      test('returns null when product is not found in DB nor BeautyFactsService', () async {
        fakeSupabaseService.productByBarcode = null;
        fakeBeautyFactsService.productByBarcode = null;

        final result = await repository.fetchProductByBarcode('99999');

        expect(result, isNull);
        expect(fakeSupabaseService.getProductByBarcodeCalled, isTrue);
        expect(fakeBeautyFactsService.fetchByBarcodeCalled, isTrue);
      });
    });

    group('upsertProduct', () {
      test('calls supabaseService.upsertProduct and returns product', () async {
        const testProduct = Product(
          id: 'p1',
          barcode: '12345',
          name: 'Test Product',
          ingredients: ['Water'],
        );

        final result = await repository.upsertProduct(testProduct);

        expect(result, equals(testProduct));
        expect(fakeSupabaseService.upsertProductCalled, isTrue);
      });
    });

    group('analyzeIngredients with BFF & Fallback', () {
      const profile = UserProfile(id: 'u1', skinType: SkinType.sensitive);
      const allergen = Allergen(id: 'a1', userId: 'u1', ingredientName: 'Fragrance');
      final ingredients = ['Water', 'Fragrance'];

      test('returns Edge Function result when Edge Function succeeds with 200', () async {
        fakeFunctions.responseToReturn = FunctionResponse(
          status: 200,
          data: {
            'overall_safety': 'danger',
            'summary_th': 'พบสารก่อภูมิแพ้',
            'summary_en': 'Allergen detected',
          },
        );

        final result = await repository.analyzeIngredients(
          profile: profile,
          allergens: [allergen],
          ingredients: ingredients,
        );

        expect(result.overallSafety, equals(SafetyLevel.danger));
        expect(result.summaryEn, equals('Allergen detected'));
        expect(fakeFunctions.lastFunctionName, equals('analyze-ingredients'));
        final bodyMap = fakeFunctions.lastBody as Map<String, dynamic>?;
        expect(bodyMap?['allergens'], equals(['Fragrance']));
        expect(fakeGeminiService.analyzeIngredientsCalled, isFalse);
      });

      test('falls back to GeminiService when Edge Function returns 500 status', () async {
        fakeFunctions.responseToReturn = FunctionResponse(
          status: 500,
          data: {'error': 'Internal server error'},
        );

        final result = await repository.analyzeIngredients(
          profile: profile,
          allergens: [allergen],
          ingredients: ingredients,
        );

        expect(result.summaryEn, equals('Analyzed by Gemini Client'));
        expect(fakeGeminiService.analyzeIngredientsCalled, isTrue);
      });

      test('falls back to GeminiService when Edge Function invocation throws exception', () async {
        fakeFunctions.shouldThrow = true;

        final result = await repository.analyzeIngredients(
          profile: profile,
          allergens: [allergen],
          ingredients: ingredients,
        );

        expect(result.summaryEn, equals('Analyzed by Gemini Client'));
        expect(fakeGeminiService.analyzeIngredientsCalled, isTrue);
      });
    });

    group('saveScanHistory', () {
      test('calls supabaseService.addScanHistory', () async {
        const result = AnalysisResult(
          overallSafety: SafetyLevel.safe,
          summaryTh: 'ปลอดภัย',
          summaryEn: 'Safe',
        );

        await repository.saveScanHistory(
          userId: 'user_1',
          productId: 'prod_1',
          result: result,
        );

        expect(fakeSupabaseService.addScanHistoryCalled, isTrue);
        expect(fakeSupabaseService.lastSavedUserId, equals('user_1'));
        expect(fakeSupabaseService.lastSavedProductId, equals('prod_1'));
      });
    });

    group('scanRepositoryProvider', () {
      test('provides a ScanRepository instance', () {
        final container = ProviderContainer(
          overrides: [
            supabaseServiceProvider.overrideWithValue(fakeSupabaseService),
            beautyFactsServiceProvider.overrideWithValue(fakeBeautyFactsService),
            geminiServiceProvider.overrideWithValue(fakeGeminiService),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(scanRepositoryProvider);

        expect(repo, isA<ScanRepository>());
      });
    });
  });
}
