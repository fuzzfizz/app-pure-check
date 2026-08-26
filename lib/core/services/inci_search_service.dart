import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inci_core_dataset.dart';
import 'supabase_service.dart';
import '../../features/auth/providers/auth_provider.dart';

final inciSearchServiceProvider = Provider<InciSearchService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return InciSearchService(supabaseService);
});

class InciSearchService {
  final SupabaseService _supabaseService;

  InciSearchService(this._supabaseService);

  Future<List<String>> searchIngredients(String query, {int limit = 5}) async {
    final localMatches = InciCoreDataset.search(query, limit: limit);
    if (localMatches.length >= limit) {
      return localMatches;
    }

    try {
      final response = await _supabaseService.client
          .from('inci_ingredients')
          .select('name')
          .ilike('name', '%$query%')
          .limit(limit);

      final list = response as List;
      final remoteMatches = list.map((item) => item['name'] as String).toList();

      final combined = <String>{...localMatches, ...remoteMatches}.toList();
      return combined.take(limit).toList();
    } catch (_) {
      return localMatches;
    }
  }

  Future<List<String>> filterUnrecognizedIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) return [];

    final needRemoteCheck = <String>[];
    final unrecognized = <String>[];

    // 1. Fast local check
    for (final ingredient in ingredients) {
      if (!InciCoreDataset.contains(ingredient)) {
        needRemoteCheck.add(ingredient);
      }
    }

    if (needRemoteCheck.isEmpty) {
      return [];
    }

    // 2. Remote Supabase check for remaining items
    try {
      final response = await _supabaseService.client
          .from('inci_ingredients')
          .select('name')
          .inFilter('name', needRemoteCheck);

      final list = response as List;
      final recognizedSet = list
          .map((item) => (item['name'] as String).toLowerCase().trim())
          .toSet();

      for (final ingredient in needRemoteCheck) {
        if (!recognizedSet.contains(ingredient.toLowerCase().trim())) {
          unrecognized.add(ingredient);
        }
      }
    } catch (_) {
      unrecognized.addAll(needRemoteCheck);
    }

    return unrecognized;
  }
}
