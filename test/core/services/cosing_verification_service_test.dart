import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pure_check/core/services/cosing_verification_service.dart';
import 'package:pure_check/core/services/supabase_service.dart';

class FakeSupabaseService extends SupabaseService {
  final List<Map<String, String?>> addedInci = [];
  final Map<String, dynamic>? Function(String name, String? action)? onVerifyIngredient;

  FakeSupabaseService({this.onVerifyIngredient});

  @override
  Future<Map<String, dynamic>?> verifyIngredient({
    required String name,
    String? action,
  }) async {
    if (onVerifyIngredient != null) return onVerifyIngredient!(name, action);
    if (name.contains('gas') || name.contains('poison')) {
      return {
        'raw_input': name,
        'is_valid_synonym': false,
        'canonical_inci_name': null,
        'reason': 'Invalid or suspicious mixture',
      };
    }
    if (name.contains('Aqua') || name.contains('Water') || name.contains('Eau')) {
      return {
        'raw_input': name,
        'is_valid_synonym': true,
        'canonical_inci_name': 'Water',
        'reason': 'Aqua, Water, and Eau are multi-lingual translations for water',
      };
    }
    return {
      'name': name,
      'is_valid_inci': true,
      'category': 'Active / Vitamin',
      'description_th': 'สารบำรุงผิวที่ผ่านการรับรอง',
      'confidence_score': 90,
    };
  }

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

      final fakeSupabase = FakeSupabaseService(
        onVerifyIngredient: (name, action) => {
          'name': name,
          'is_valid_inci': true,
          'cosing_id': '35650',
          'category': 'Active / Vitamin B3',
          'description_th': 'วิตามินบี 3 ช่วยลดรอยแดงและคุมมัน',
          'confidence_score': 99,
        },
      );

      final service = CosIngVerificationService(
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

    test('verifyIngredient falls back to Supabase Edge Function when REST API returns 404', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('{"status": 0}', 404);
      });

      final fakeSupabase = FakeSupabaseService(
        onVerifyIngredient: (name, action) => {
          'name': name,
          'is_valid_inci': true,
          'category': 'Botanical Extract',
          'description_th': 'สารสกัดจากพืชธรรมชาติช่วยปลอบประโลมผิว',
          'confidence_score': 90,
        },
      );

      final service = CosIngVerificationService(
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
      final fakeSupabase = FakeSupabaseService(
        onVerifyIngredient: (name, action) {
          if (name == 'InvalidText123') {
            return {
              'name': name,
              'is_valid_inci': false,
              'category': 'Invalid',
              'description_th': '',
              'confidence_score': 0,
            };
          }
          return {
            'name': name,
            'is_valid_inci': true,
            'category': 'Active',
            'description_th': 'สารบำรุงผิวที่ผ่านการรับรอง',
            'confidence_score': 95,
          };
        },
      );

      final service = CosIngVerificationService(
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
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        supabaseService: fakeSupabase,
      );

      final result = await service.verifyIngredient('Aqua / Water / Eau');
      expect(result, isNotNull);
      expect(result!.isValidInci, isTrue);
      expect(result.confidenceScore, 100);
    });

    test('verifyIngredient explicitly blocks and rejects bogus/invalid mixtures like gas/water/aqua', () async {
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        supabaseService: fakeSupabase,
      );

      final result = await service.verifyIngredient('gas/water/aqua');
      expect(result, isNotNull);
      expect(result!.isValidInci, isFalse);
      expect(result.confidenceScore, 0);
      expect(result.category, 'Invalid Mixture / Spam');
    });

    test('verifyIngredient explicitly blocks toxic combinations like poison / water', () async {
      final fakeSupabase = FakeSupabaseService();

      final service = CosIngVerificationService(
        supabaseService: fakeSupabase,
      );

      final result = await service.verifyIngredient('poison / water');
      expect(result, isNotNull);
      expect(result!.isValidInci, isFalse);
      expect(result.confidenceScore, 0);
    });
  });
}
