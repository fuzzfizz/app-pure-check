import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/allergen.dart';
import 'package:pure_check/core/models/analysis_result.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/core/services/beauty_facts_service.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/scan/data/repositories/scan_repository_impl.dart';
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
  Product? upsertedProduct;
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
    upsertedProduct = product;
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

void main() {
  group('ScanRepositoryImpl Unit Tests', () {
    late FakeFunctionsClient fakeFunctions;
    late FakeSupabaseClient fakeSupabaseClient;
    late FakeSupabaseService fakeSupabaseService;
    late FakeBeautyFactsService fakeBeautyFactsService;
    late ScanRepositoryImpl repository;

    setUp(() {
      fakeFunctions = FakeFunctionsClient();
      fakeSupabaseClient = FakeSupabaseClient(fakeFunctions);
      fakeSupabaseService = FakeSupabaseService(fakeSupabaseClient);
      fakeBeautyFactsService = FakeBeautyFactsService();

      repository = ScanRepositoryImpl(
        supabaseService: fakeSupabaseService,
        beautyFactsService: fakeBeautyFactsService,
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

      test('calls BeautyFactsService when product not in Supabase DB', () async {
        fakeSupabaseService.productByBarcode = null;
        const apiProduct = Product(
          id: 'p2',
          barcode: '99999',
          name: 'API Lotion',
          ingredients: ['Glycerin'],
        );
        fakeBeautyFactsService.productByBarcode = apiProduct;

        final result = await repository.fetchProductByBarcode('99999');

        expect(result, equals(apiProduct));
        expect(fakeSupabaseService.getProductByBarcodeCalled, isTrue);
        expect(fakeBeautyFactsService.fetchByBarcodeCalled, isTrue);
      });

      test('returns null when product is neither in DB nor in BeautyFacts API', () async {
        fakeSupabaseService.productByBarcode = null;
        fakeBeautyFactsService.productByBarcode = null;

        final result = await repository.fetchProductByBarcode('00000');

        expect(result, isNull);
        expect(fakeSupabaseService.getProductByBarcodeCalled, isTrue);
        expect(fakeBeautyFactsService.fetchByBarcodeCalled, isTrue);
      });
    });

    group('upsertProduct', () {
      test('delegates upsert to SupabaseService', () async {
        const newProduct = Product(
          id: 'p3',
          barcode: '77777',
          name: 'Sunscreen',
          ingredients: ['Zinc Oxide'],
        );

        final result = await repository.upsertProduct(newProduct);

        expect(result, equals(newProduct));
        expect(fakeSupabaseService.upsertProductCalled, isTrue);
        expect(fakeSupabaseService.upsertedProduct, equals(newProduct));
      });
    });

    group('analyzeIngredients', () {
      const profile = UserProfile(
        id: 'u1',
        skinType: SkinType.sensitive,
        skinConditions: ['Acne'],
      );
      const allergen = Allergen(
        id: 'a1',
        userId: 'u1',
        ingredientName: 'Fragrance',
      );
      const ingredients = ['Water', 'Glycerin', 'Fragrance'];

      test('invokes Supabase Edge Function analyze-ingredients and returns result on 200', () async {
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
      });

      test('falls back to local heuristic analysis when Edge Function returns 500 status', () async {
        fakeFunctions.responseToReturn = FunctionResponse(
          status: 500,
          data: {'error': 'Internal server error'},
        );

        final result = await repository.analyzeIngredients(
          profile: profile,
          allergens: [allergen],
          ingredients: ingredients,
        );

        expect(result.overallSafety, equals(SafetyLevel.danger));
        expect(result.flaggedIngredients.any((f) => f.name == 'Fragrance'), isTrue);
      });

      test('falls back to local heuristic analysis when Edge Function throws exception', () async {
        fakeFunctions.shouldThrow = true;

        final result = await repository.analyzeIngredients(
          profile: profile,
          allergens: [allergen],
          ingredients: ingredients,
        );

        expect(result.overallSafety, equals(SafetyLevel.danger));
        expect(result.flaggedIngredients.any((f) => f.name == 'Fragrance'), isTrue);
      });
    });

    group('saveScanHistory', () {
      test('delegates saveScanHistory to SupabaseService', () async {
        const analysis = AnalysisResult(
          overallSafety: SafetyLevel.safe,
          summaryTh: 'ปลอดภัย',
          summaryEn: 'Safe',
        );

        await repository.saveScanHistory(
          userId: 'u123',
          productId: 'p456',
          result: analysis,
        );

        expect(fakeSupabaseService.addScanHistoryCalled, isTrue);
        expect(fakeSupabaseService.lastSavedUserId, equals('u123'));
        expect(fakeSupabaseService.lastSavedProductId, equals('p456'));
      });
    });

    group('Riverpod Provider Initialization', () {
      test('scanRepositoryProvider correctly creates ScanRepositoryImpl instance', () {
        final container = ProviderContainer(
          overrides: [
            supabaseServiceProvider.overrideWithValue(fakeSupabaseService),
            beautyFactsServiceProvider.overrideWithValue(fakeBeautyFactsService),
          ],
        );

        final repo = container.read(scanRepositoryProvider);
        expect(repo, isA<ScanRepositoryImpl>());
      });
    });
  });
}
