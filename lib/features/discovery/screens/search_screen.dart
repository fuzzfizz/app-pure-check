import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ค้นหาชื่อแบรนด์ ผลิตภัณฑ์ หรือสารเคมี...',
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
          tabs: const [
            Tab(text: 'ผลิตภัณฑ์ (Products)'),
            Tab(text: 'สารเคมี (Ingredients)'),
          ],
        ),
      ),
      body: searchState.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // Products list
                _buildProductResults(searchState),
                // Ingredients list (derived from matching products or typing search)
                _buildIngredientResults(searchState),
              ],
            ),
    );
  }

  Widget _buildProductResults(SearchState state) {
    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bubble_chart_outlined, size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                state.query.isEmpty
                    ? 'พิมพ์ข้อความด้านบนเพื่อค้นหาผลิตภัณฑ์'
                    : 'ไม่พบผลิตภัณฑ์ที่ค้นหา',
                style: TextStyle(color: AppColors.textSecondary),
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
            leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(product.brand ?? 'ไม่ระบุแบรนด์'),
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

  Widget _buildIngredientResults(SearchState state) {
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
              Icon(Icons.science_outlined, size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text(
                'พิมพ์ชื่อสารเคมีด้านบนเพื่อตรวจสอบประวัติการแพ้',
                style: TextStyle(color: AppColors.textSecondary),
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
