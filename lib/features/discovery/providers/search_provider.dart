import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../auth/providers/auth_provider.dart';

class SearchState {
  final String query;
  final List<Product> results;
  final bool loading;
  final String? error;

  SearchState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<Product>? results,
    bool? loading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref ref;

  SearchNotifier(this.ref) : super(SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = SearchState();
      return;
    }
    state = state.copyWith(query: query, loading: true, error: null);
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final products = await supabaseService.searchProducts(query);
      state = state.copyWith(results: products, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref);
});
