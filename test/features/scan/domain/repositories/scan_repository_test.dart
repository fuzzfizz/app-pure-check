import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/features/scan/domain/repositories/scan_repository.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/models/analysis_result.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/core/models/allergen.dart';

class MockScanRepository implements ScanRepository {
  final Map<String, Product> _productsByBarcode = {};
  final List<Map<String, dynamic>> _savedHistory = [];

  @override
  Future<Product?> fetchProductByBarcode(String barcode) async {
    return _productsByBarcode[barcode];
  }

  @override
  Future<Product> upsertProduct(Product product) async {
    if (product.barcode != null) {
      _productsByBarcode[product.barcode!] = product;
    }
    return product;
  }

  @override
  Future<AnalysisResult> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) async {
    final hasAllergen = allergens.any((a) => ingredients.contains(a.ingredientName));
    return AnalysisResult(
      overallSafety: hasAllergen ? SafetyLevel.danger : SafetyLevel.safe,
      summaryTh: hasAllergen ? 'พบสารก่อภูมิแพ้' : 'ปลอดภัย',
      summaryEn: hasAllergen ? 'Allergen detected' : 'Safe',
    );
  }

  @override
  Future<void> saveScanHistory({
    required String userId,
    required String productId,
    required AnalysisResult result,
  }) async {
    _savedHistory.add({
      'userId': userId,
      'productId': productId,
      'result': result,
    });
  }

  List<Map<String, dynamic>> get savedHistory => List.unmodifiable(_savedHistory);
}

void main() {
  group('ScanRepository mock tests', () {
    late MockScanRepository mockRepo;

    setUp(() {
      mockRepo = MockScanRepository();
    });

    test('fetchProductByBarcode returns null when product not found', () async {
      final product = await mockRepo.fetchProductByBarcode('123456789');
      expect(product, isNull);
    });

    test('upsertProduct and fetchProductByBarcode work correctly', () async {
      const testProduct = Product(
        id: 'p1',
        barcode: '8850001',
        name: 'Test Shampoo',
        brand: 'CleanBrand',
        ingredients: ['Water', 'Glycerin'],
      );

      final saved = await mockRepo.upsertProduct(testProduct);
      expect(saved.id, equals('p1'));

      final fetched = await mockRepo.fetchProductByBarcode('8850001');
      expect(fetched, isNotNull);
      expect(fetched?.name, equals('Test Shampoo'));
    });

    test('analyzeIngredients returns danger level when allergen is present', () async {
      const userProfile = UserProfile(id: 'u1', skinType: SkinType.sensitive);
      const allergen = Allergen(
        id: 'a1',
        userId: 'u1',
        ingredientName: 'Fragrance',
        severity: AllergenSeverity.severe,
      );

      final result = await mockRepo.analyzeIngredients(
        profile: userProfile,
        allergens: [allergen],
        ingredients: ['Water', 'Fragrance', 'Glycerin'],
      );

      expect(result.overallSafety, equals(SafetyLevel.danger));
      expect(result.summaryEn, equals('Allergen detected'));
    });

    test('analyzeIngredients returns safe level when no allergen is present', () async {
      const userProfile = UserProfile(id: 'u1', skinType: SkinType.normal);
      const allergen = Allergen(
        id: 'a1',
        userId: 'u1',
        ingredientName: 'Paraben',
      );

      final result = await mockRepo.analyzeIngredients(
        profile: userProfile,
        allergens: [allergen],
        ingredients: ['Water', 'Glycerin'],
      );

      expect(result.overallSafety, equals(SafetyLevel.safe));
      expect(result.summaryEn, equals('Safe'));
    });

    test('saveScanHistory records scan entry', () async {
      const result = AnalysisResult(
        overallSafety: SafetyLevel.safe,
        summaryTh: 'ปลอดภัย',
        summaryEn: 'Safe',
      );

      await mockRepo.saveScanHistory(
        userId: 'user_123',
        productId: 'prod_456',
        result: result,
      );

      expect(mockRepo.savedHistory.length, equals(1));
      expect(mockRepo.savedHistory.first['userId'], equals('user_123'));
      expect(mockRepo.savedHistory.first['productId'], equals('prod_456'));
    });
  });
}
