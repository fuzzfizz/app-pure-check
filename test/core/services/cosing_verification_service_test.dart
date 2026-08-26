import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pure_check/core/models/chemical_synonym_result.dart';
import 'package:pure_check/core/models/cosing_ingredient.dart';
import 'package:pure_check/core/services/cosing_verification_service.dart';
import 'package:pure_check/core/services/gemini_service.dart';
import 'package:pure_check/core/services/supabase_service.dart';

class FakeGeminiService extends GeminiService {
  final CosIngIngredient? Function(String name)? onVerifyCosIng;
  final ChemicalSynonymResult? Function(String input)? onResolveSynonym;

  FakeGeminiService({this.onVerifyCosIng, this.onResolveSynonym});

  @override
  Future<ChemicalSynonymResult?> resolveChemicalSynonym(String rawInput) async {
    if (onResolveSynonym != null) return onResolveSynonym!(rawInput);
    if (rawInput.contains('gas') || rawInput.contains('poison')) {
      return ChemicalSynonymResult(
        rawInput: rawInput,
        isValidSynonym: false,
        canonicalInciName: null,
        reason: 'Invalid or suspicious mixture',
      );
    }
    if (rawInput.contains('Aqua') || rawInput.contains('Water') || rawInput.contains('Eau')) {
      return ChemicalSynonymResult(
        rawInput: rawInput,
        isValidSynonym: true,
        canonicalInciName: 'Water',
        reason: 'Aqua, Water, and Eau are multi-lingual translations for water',
      );
    }
    return null;
  }

  @override
  Future<CosIngIngredient?> verifyCosIngIngredient(String rawName) async {
    if (onVerifyCosIng != null) return onVerifyCosIng!(rawName);
    return CosIngIngredient(
      name: rawName,
      isValidInci: true,
      category: 'Active / Vitamin',
      descriptionTh: 'สารบำรุงผิวที่ผ่านการรับรอง',
      confidenceScore: 90,
    );
  }
}

class FakeSupabaseService extends SupabaseService {
  final List<Map<String, String?>> addedInci = [];

  @override
  Future<void> addInciIngredient({
    required String name,
    String? category,
    String? descriptionTh,
  }) async {
    addedInci.add({
      'name': name,
      'category': category,
      'description_th': descriptionTh,
    });
  }
}

void main() {
  group('CosIngVerificationService Unit Tests', () {
    test('verifyIngredient returns verified ingredient from Open Beauty Facts REST API', () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('ingredient/niacinamide')) {
          return http.Response(
            jsonEncode({
              'status': 1,
              'ingredient': {
                'name': 'Niacinamide',
                'cosing_id': '35650',
                'functions': ['skin conditioning', 'smoothing'],
              }
            }),
            200,
          );
        }
        return http.Response('{"status": 0}', 404);
      });

      final fakeGemini = FakeGeminiService(
        onVerifyCosIng: (name) => CosIngIngredient(
          name: name,
          isValidInci: true,
          cosingId: '35650',
          category: 'Active / Vitamin B3',
          descriptionTh: 'วิตามินบี 3 ช่วยลดรอยแดงและคุมมัน',
          confidenceScore: 99,
        ),
      );
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        geminiService: fakeGemini,
        supabaseService: fakeSupabase,
        httpClient: mockHttpClient,
      );

      final result = await service.verifyIngredient('Niacinamide');
      expect(result, isNotNull);
      expect(result!.name, 'Niacinamide');
      expect(result.isValidInci, isTrue);
      expect(result.category, 'Active / Vitamin B3');
      expect(result.descriptionTh, contains('วิตามินบี 3'));
    });

    test('verifyIngredient falls back to Gemini when REST API returns 404', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('{"status": 0}', 404);
      });

      final fakeGemini = FakeGeminiService(
        onVerifyCosIng: (name) => CosIngIngredient(
          name: name,
          isValidInci: true,
          category: 'Botanical Extract',
          descriptionTh: 'สารสกัดจากพืชธรรมชาติช่วยปลอบประโลมผิว',
          confidenceScore: 90,
        ),
      );
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        geminiService: fakeGemini,
        supabaseService: fakeSupabase,
        httpClient: mockHttpClient,
      );

      final result = await service.verifyIngredient('Rare Botanical Extract');
      expect(result, isNotNull);
      expect(result!.isValidInci, isTrue);
      expect(result.category, 'Botanical Extract');
    });

    test('verifyAndSyncBatch verifies and synchronizes valid ingredients to Supabase', () async {
      final mockHttpClient = MockClient((request) async => http.Response('{"status": 0}', 404));
      final fakeGemini = FakeGeminiService(
        onVerifyCosIng: (name) {
          if (name == 'InvalidText123') {
            return CosIngIngredient(
              name: name,
              isValidInci: false,
              category: 'Invalid',
              descriptionTh: '',
              confidenceScore: 0,
            );
          }
          return CosIngIngredient(
            name: name,
            isValidInci: true,
            category: 'Active',
            descriptionTh: 'สารบำรุงผิวที่ผ่านการรับรอง',
            confidenceScore: 95,
          );
        },
      );
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        geminiService: fakeGemini,
        supabaseService: fakeSupabase,
        httpClient: mockHttpClient,
      );

      final results = await service.verifyAndSyncBatch(
        ['Madecassoside', 'InvalidText123'],
        autoSyncToSupabase: true,
      );

      expect(results.length, 1);
      expect(results.first.name, 'Madecassoside');
      expect(fakeSupabase.addedInci.length, 1);
      expect(fakeSupabase.addedInci.first['name'], 'Madecassoside');
    });

    test('verifyIngredient successfully validates multi-lingual cosmetic synonyms (Aqua / Water / Eau)', () async {
      final fakeGemini = FakeGeminiService();
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        geminiService: fakeGemini,
        supabaseService: fakeSupabase,
      );

      final result = await service.verifyIngredient('Aqua / Water / Eau');
      expect(result, isNotNull);
      expect(result!.isValidInci, isTrue);
      expect(result.confidenceScore, 100);
    });

    test('verifyIngredient explicitly blocks and rejects bogus/invalid mixtures like gas/water/aqua', () async {
      final fakeGemini = FakeGeminiService();
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        geminiService: fakeGemini,
        supabaseService: fakeSupabase,
      );

      final result = await service.verifyIngredient('gas/water/aqua');
      expect(result, isNotNull);
      expect(result!.isValidInci, isFalse);
      expect(result.confidenceScore, 0);
      expect(result.category, 'Invalid Mixture / Spam');
    });

    test('verifyIngredient explicitly blocks toxic combinations like poison / water', () async {
      final fakeGemini = FakeGeminiService();
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        geminiService: fakeGemini,
        supabaseService: fakeSupabase,
      );

      final result = await service.verifyIngredient('poison / water');
      expect(result, isNotNull);
      expect(result!.isValidInci, isFalse);
      expect(result.confidenceScore, 0);
    });
  });
}
