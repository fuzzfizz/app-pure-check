import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/services/admin_moderation_service.dart';
import 'package:pure_check/core/services/inci_search_service.dart';

class FakeInciSearchService implements InciSearchService {
  final List<String> unrecognizedReturn;

  FakeInciSearchService({this.unrecognizedReturn = const []});

  @override
  Future<List<String>> searchIngredients(String query, {int limit = 5}) async {
    return [];
  }

  @override
  Future<List<String>> filterUnrecognizedIngredients(List<String> ingredients) async {
    return unrecognizedReturn;
  }
}

void main() {
  group('ModerationEvaluation', () {
    test('getters correctly reflect score thresholds', () {
      const highEval = ModerationEvaluation(confidenceScore: 85, flags: []);
      expect(highEval.isHighConfidence, isTrue);
      expect(highEval.needsInspection, isFalse);
      expect(highEval.isLowConfidence, isFalse);

      const medEval = ModerationEvaluation(confidenceScore: 65, flags: ['missing_brand']);
      expect(medEval.isHighConfidence, isFalse);
      expect(medEval.needsInspection, isTrue);
      expect(medEval.isLowConfidence, isFalse);

      const lowEval = ModerationEvaluation(confidenceScore: 40, flags: ['short_name', 'suspected_spam']);
      expect(lowEval.isHighConfidence, isFalse);
      expect(lowEval.needsInspection, isFalse);
      expect(lowEval.isLowConfidence, isTrue);
    });
  });

  group('AdminModerationService', () {
    test('evaluateProduct returns high confidence for valid complete product', () async {
      final inciService = FakeInciSearchService(unrecognizedReturn: []);
      final moderationService = AdminModerationService(inciService);

      const product = Product(
        id: 'p1',
        name: 'Moisturizing Cream',
        brand: 'Beauty Care',
        ingredients: ['Water', 'Glycerin', 'Niacinamide'],
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.confidenceScore, equals(100));
      expect(eval.flags, isEmpty);
      expect(eval.isHighConfidence, isTrue);
    });

    test('evaluateProduct flags short name and missing brand', () async {
      final inciService = FakeInciSearchService(unrecognizedReturn: []);
      final moderationService = AdminModerationService(inciService);

      const product = Product(
        id: 'p2',
        name: 'AB',
        brand: null,
        ingredients: ['Water'],
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.flags, contains('short_name'));
      expect(eval.flags, contains('missing_brand'));
      expect(eval.confidenceScore, lessThan(80));
    });

    test('evaluateProduct flags suspected spam', () async {
      final inciService = FakeInciSearchService(unrecognizedReturn: []);
      final moderationService = AdminModerationService(inciService);

      const product = Product(
        id: 'p3',
        name: 'http://spam-site.com cheap aaaaaaa product',
        brand: 'Spam Brand',
        ingredients: ['Water'],
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.flags, contains('suspected_spam'));
      expect(eval.confidenceScore, lessThan(80));
    });

    test('evaluateProduct calculates INCI recognition rate and sets flags', () async {
      final inciService = FakeInciSearchService(
        unrecognizedReturn: ['Unk1', 'Unk2', 'Unk3'],
      );
      final moderationService = AdminModerationService(inciService);

      const product = Product(
        id: 'p4',
        name: 'Super Serum',
        brand: 'Glow Tech',
        ingredients: ['Water', 'Unk1', 'Unk2', 'Unk3'], // 1/4 recognized = 25% match
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.flags, contains('unrecognized_ingredients'));
      expect(eval.flags, contains('low_inci_match'));
      expect(eval.confidenceScore, lessThan(80));
    });

    test('evaluateProduct returns low confidence when multiple issues exist', () async {
      final inciService = FakeInciSearchService(
        unrecognizedReturn: ['Unk1', 'Unk2'],
      );
      final moderationService = AdminModerationService(inciService);

      const product = Product(
        id: 'p5',
        name: 'X', // short name (-30)
        brand: '', // missing brand (-15)
        ingredients: ['Unk1', 'Unk2'], // 0% recognized (-40) + unrecognized (-10)
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.isLowConfidence, isTrue);
      expect(eval.confidenceScore, lessThan(50));
    });

    test('adminModerationServiceProvider provides AdminModerationService instance', () {
      final container = ProviderContainer(
        overrides: [
          inciSearchServiceProvider.overrideWithValue(FakeInciSearchService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(adminModerationServiceProvider);
      expect(service, isA<AdminModerationService>());
    });
  });
}
