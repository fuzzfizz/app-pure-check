import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final response = await _supabaseService.client
        .from('inci_ingredients')
        .select('name')
        .ilike('name', '%$query%')
        .limit(limit);

    final list = response as List;
    return list.map((item) => item['name'] as String).toList();
  }

  Future<List<String>> filterUnrecognizedIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) return [];

    final response = await _supabaseService.client
        .from('inci_ingredients')
        .select('name')
        .inFilter('name', ingredients);

    final list = response as List;
    final recognizedSet = list
        .map((item) => (item['name'] as String).toLowerCase().trim())
        .toSet();

    final unrecognized = <String>[];
    for (final ingredient in ingredients) {
      if (!recognizedSet.contains(ingredient.toLowerCase().trim())) {
        unrecognized.add(ingredient);
      }
    }
    return unrecognized;
  }
}
