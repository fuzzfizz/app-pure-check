import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/search_provider.dart';
import 'product_detail_screen.dart';
import 'ingredient_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(searchNotifierProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchBrandsHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _onSearchChanged,
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.tabProducts),
            Tab(text: l10n.tabIngredients),
          ],
        ),
      ),
      body: searchState.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // Products list
                _buildProductResults(searchState, l10n),
                // Ingredients list (derived from matching products or typing search)
                _buildIngredientResults(searchState, l10n),
              ],
            ),
    );
  }

  Widget _buildProductResults(SearchState state, AppLocalizations l10n) {
    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bubble_chart_outlined, size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                state.query.isEmpty
                    ? l10n.typeToSearchProducts
                    : l10n.noProductsFound,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.results.length,
      itemBuilder: (context, i) {
        final product = state.results[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mintBg),
              ),
              clipBehavior: Clip.antiAlias,
              child: product.imageUrl != null && product.imageUrl!.trim().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.mintBg,
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                    ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(product.brand ?? l10n.unknownBrand),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildIngredientResults(SearchState state, AppLocalizations l10n) {
    // Generate ingredients from matching product ingredients or show match query
    final List<String> list = [];
    if (state.query.isNotEmpty) {
      list.add(state.query.trim()); // Always let them search raw query as ingredient
    }

    for (final prod in state.results) {
      for (final ing in prod.ingredients) {
        if (state.query.isNotEmpty && ing.toLowerCase().contains(state.query.toLowerCase()) && !list.contains(ing)) {
          list.add(ing);
        }
      }
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.science_outlined, size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                l10n.typeIngredientToCheck,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final name = list[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.science, color: AppColors.primaryDark),
            title: Text(name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => IngredientDetailScreen(ingredientName: name)),
              );
            },
          ),
        );
      },
    );
  }
}
