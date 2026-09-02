import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/cosing_ingredient.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/services/admin_moderation_service.dart';
import 'package:pure_check/core/services/cosing_verification_service.dart';
import 'package:pure_check/core/services/inci_search_service.dart';
import 'package:pure_check/core/services/supabase_service.dart';

class FakeCosIngVerificationService extends CosIngVerificationService {
  final List<CosIngIngredient> Function(List<String> unknowns)? onVerifyBatch;

  FakeCosIngVerificationService({this.onVerifyBatch})
      : super(
          supabaseService: SupabaseService(),
        );

  @override
  Future<List<CosIngIngredient>> verifyAndSyncBatch(
    List<String> unknownIngredients, {
    bool autoSyncToSupabase = true,
  }) async {
    if (onVerifyBatch != null) return onVerifyBatch!(unknownIngredients);
    return [];
  }
}

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

    test('reasonSummaries generates clear explanation text for deductions', () {
      const eval100 = ModerationEvaluation(
        confidenceScore: 100,
        flags: [],
        deductions: {},
      );
      expect(eval100.reasonSummaries, contains('ข้อมูลสมบูรณ์และผ่านเกณฑ์ความปลอดภัยทั้งหมด (100 คะแนนเต็ม)'));

      const evalWithDeductions = ModerationEvaluation(
        confidenceScore: 45,
        flags: ['short_name', 'missing_brand', 'low_inci_match'],
        deductions: {
          'short_name': -30,
          'missing_brand': -15,
          'low_inci_match': -40,
        },
        inciMatchRate: 0.25,
      );
      expect(evalWithDeductions.reasonSummaries.length, equals(3));
      expect(evalWithDeductions.reasonSummaries.first, contains('ชื่อผลิตภัณฑ์สั้นเกินไป'));
      expect(evalWithDeductions.reasonSummaries[1], contains('ไม่ระบุชื่อแบรนด์'));
      expect(evalWithDeductions.reasonSummaries[2], contains('ส่วนผสมตรงกับฐานข้อมูล INCI'));
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

    test('evaluateProduct with InciSearchService evaluates CeraVe Hydrating Cleanser as 100% Green', () async {
      final realInciService = InciSearchService(SupabaseService());
      final moderationService = AdminModerationService(realInciService);

      const cerave = Product(
        id: 'p-cerave',
        name: 'Hydrating Cleanser',
        brand: 'CeraVe',
        ingredients: [
          'Water',
          'Glycerin',
          'Cetearyl Alcohol',
          'Peg-40 Stearate',
          'Stearyl Alcohol',
          'Potassium Phosphate',
          'Ceramide Np',
          'Ceramide Ap',
          'Ceramide Eop',
          'Carbomer',
          'Glyceryl Stearate',
          'Behentrimonium Methosulfate',
          'Sodium Lauroyl Lactylate',
          'Sodium Hyaluronate',
          'Cholesterol',
          'Phenoxyethanol',
          'Disodium Edta',
          'Dipotassium Phosphate',
          'Tocopherol',
          'Phytosphingosine',
          'Xanthan Gum',
          'Ethylhexylglycerin',
        ],
        status: 'pending',
      );

      final eval = await moderationService.evaluateProduct(cerave);

      expect(eval.confidenceScore, equals(100));
      expect(eval.isHighConfidence, isTrue);
      expect(eval.unrecognizedIngredients, isEmpty);
      expect(eval.flags, isEmpty);
      expect(eval.reasonSummaries, contains('ข้อมูลสมบูรณ์และผ่านเกณฑ์ความปลอดภัยทั้งหมด (100 คะแนนเต็ม)'));
    });

    test('evaluateProduct verifies unrecognized ingredient via CosIng and avoids deduction', () async {
      final fakeInci = FakeInciSearchService(unrecognizedReturn: ['RareBotanicalExtract']);
      final fakeCosIng = FakeCosIngVerificationService(
        onVerifyBatch: (unknowns) => [
          const CosIngIngredient(
            name: 'RareBotanicalExtract',
            isValidInci: true,
            category: 'Botanical Extract',
            descriptionTh: 'สารสกัดธรรมชาติผ่านการรับรอง',
            confidenceScore: 95,
          ),
        ],
      );

      final moderationService = AdminModerationService(fakeInci, fakeCosIng);

      const product = Product(
        id: 'p-rare',
        name: 'Botanical Serum',
        brand: 'Nature Care',
        ingredients: ['Water', 'Glycerin', 'RareBotanicalExtract'],
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.confidenceScore, equals(100));
      expect(eval.isHighConfidence, isTrue);
      expect(eval.unrecognizedIngredients, isEmpty);
      expect(eval.newlyVerifiedIngredients, contains('RareBotanicalExtract'));
      expect(eval.reasonSummaries.first, contains('สารใหม่ได้รับการตรวจสอบรับรองตาม CosIng'));
    });

    test('evaluateProduct handles multi-lingual Aqua / Water / Eau with 100% confidence', () async {
      final fakeInci = FakeInciSearchService(unrecognizedReturn: []);
      final fakeCosIng = FakeCosIngVerificationService();
      final moderationService = AdminModerationService(fakeInci, fakeCosIng);

      const product = Product(
        id: 'p-water',
        name: 'Hydra Essence',
        brand: 'Clean Brand',
        ingredients: ['Aqua / Water / Eau', 'Glycerin', 'Niacinamide'],
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.confidenceScore, equals(100));
      expect(eval.isHighConfidence, isTrue);
      expect(eval.unrecognizedIngredients, isEmpty);
    });

    test('evaluateProduct rejects bogus mixture gas/water/aqua with deduction and unrecognized flag', () async {
      final fakeInci = FakeInciSearchService(unrecognizedReturn: ['gas/water/aqua']);
      final fakeCosIng = FakeCosIngVerificationService(
        onVerifyBatch: (unknowns) => [], // AI rejects gas/water/aqua so returns empty verified list
      );
      final moderationService = AdminModerationService(fakeInci, fakeCosIng);

      const product = Product(
        id: 'p-bogus',
        name: 'Bogus Cream',
        brand: 'Fake Brand',
        ingredients: ['gas/water/aqua', 'Niacinamide'],
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.confidenceScore, lessThanOrEqualTo(80));
      expect(eval.unrecognizedIngredients, contains('gas/water/aqua'));
      expect(eval.flags, contains('unrecognized_ingredients'));
      expect(eval.flags, contains('partial_inci_match'));
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
