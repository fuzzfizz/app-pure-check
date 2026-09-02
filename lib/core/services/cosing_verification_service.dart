import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../data/inci_core_dataset.dart';
import '../models/cosing_ingredient.dart';
import 'supabase_service.dart';
import '../../features/auth/providers/auth_provider.dart';

final cosIngVerificationServiceProvider = Provider<CosIngVerificationService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return CosIngVerificationService(
    supabaseService: supabase,
  );
});

class CosIngVerificationService {
  final SupabaseService supabaseService;
  final http.Client _httpClient;

  CosIngVerificationService({
    required this.supabaseService,
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client();

  /// Verifies a single unknown ingredient name against Open Beauty Facts CosIng API,
  /// with AI Chemical Synonym & Regulatory Chemist validation via Supabase Edge Function.
  Future<CosIngIngredient?> verifyIngredient(String rawName) async {
    final cleanName = rawName.trim();
    if (cleanName.isEmpty) return null;

    // 0. If name contains slashes ('/') or brackets ('()'), evaluate with AI Chemical Synonym Analyzer
    if (cleanName.contains('/') || (cleanName.contains('(') && cleanName.contains(')'))) {
      try {
        final synonymData = await supabaseService.verifyIngredient(name: cleanName, action: 'synonym');
        if (synonymData != null) {
          final isValid = synonymData['is_valid_synonym'] == true;
          final reason = synonymData['reason'] as String? ?? 'Invalid mixture';

          if (!isValid) {
            // Explicitly reject bogus/suspicious combinations like 'gas/water/aqua' or 'poison/water'
            return CosIngIngredient(
              name: cleanName,
              isValidInci: false,
              category: 'Invalid Mixture / Spam',
              descriptionTh: 'ตรวจพบชื่อสารที่น่าสงสัยหรือไม่ใช่สารเครื่องสำอางสากล ($reason)',
              confidenceScore: 0,
            );
          }

          // If valid synonym for a single substance (e.g. 'Aqua / Water / Eau' -> 'Water')
          final canonical = synonymData['canonical_inci_name'] as String?;
          if (canonical != null && canonical.isNotEmpty) {
            if (InciCoreDataset.contains(canonical)) {
              final localItem = InciCoreDataset.find(canonical);
              return CosIngIngredient(
                name: cleanName,
                isValidInci: true,
                category: localItem?.category ?? 'Cosmetic Ingredient',
                descriptionTh: localItem?.descriptionTh ?? 'สารเครื่องสำอางมาตรฐานสากล',
                confidenceScore: 100,
              );
            }

            // Verify canonical name
            final canonicalVerified = await verifyIngredient(canonical);
            if (canonicalVerified != null && canonicalVerified.isValidInci) {
              return CosIngIngredient(
                name: cleanName,
                isValidInci: true,
                cosingId: canonicalVerified.cosingId,
                category: canonicalVerified.category,
                descriptionTh: canonicalVerified.descriptionTh,
                confidenceScore: canonicalVerified.confidenceScore,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Chemical synonym resolution error: $e');
      }
    }

    // 1. Attempt Open Beauty Facts / CosIng REST API lookup
    try {
      final normalized = cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      final uri = Uri.parse('https://world.openbeautyfacts.org/api/v2/ingredient/$normalized');
      final response = await _httpClient.get(uri).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 1 || data['status'] == 'success' || data['ingredient'] != null) {
          final ingData = data['ingredient'] as Map<String, dynamic>? ?? data;
          final officialName = ingData['name'] as String? ?? cleanName;
          final functions = (ingData['functions'] as List?)?.map((e) => e.toString()).join(', ') ?? 'Skin Conditioning';

          // Enhance with Edge Function for proper Thai description
          final aiData = await supabaseService.verifyIngredient(name: officialName, action: 'cosing');
          if (aiData != null) {
            final aiResult = CosIngIngredient.fromJson(aiData);
            if (aiResult.isValidInci) {
              return aiResult;
            }
          }

          return CosIngIngredient(
            name: officialName,
            isValidInci: true,
            cosingId: ingData['cosing_id']?.toString(),
            category: functions,
            descriptionTh: 'สารบำรุงผิวตามมาตรฐาน CosIng',
            confidenceScore: 95,
          );
        }
      }
    } catch (e) {
      debugPrint('CosIng REST API check error (will use AI fallback): $e');
    }

    // 2. Fallback to Supabase Edge Function Regulatory Chemist Validation
    final res = await supabaseService.verifyIngredient(name: cleanName, action: 'cosing');
    if (res != null) {
      return CosIngIngredient.fromJson(res);
    }

    return null;
  }

  /// Verifies a batch of unknown ingredients, and if valid, automatically synchronizes
  /// them into Supabase `inci_ingredients` table so future checks recognize them instantly.
  Future<List<CosIngIngredient>> verifyAndSyncBatch(
    List<String> unknownIngredients, {
    bool autoSyncToSupabase = true,
  }) async {
    final List<CosIngIngredient> verifiedList = [];

    for (final rawName in unknownIngredients) {
      final verified = await verifyIngredient(rawName);
      if (verified != null && verified.isValidInci) {
        verifiedList.add(verified);

        if (autoSyncToSupabase) {
          try {
            await supabaseService.addInciIngredient(
              name: verified.name,
              category: verified.category,
              descriptionTh: verified.descriptionTh,
            );
            debugPrint('CosIng Auto-Sync: Successfully added "${verified.name}" to Supabase inci_ingredients');
          } catch (e) {
            debugPrint('CosIng Auto-Sync Error: $e');
          }
        }
      }
    }

    return verifiedList;
  }
}
