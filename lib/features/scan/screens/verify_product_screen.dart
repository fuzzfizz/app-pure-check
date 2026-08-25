import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/product.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';

class VerifyProductScreen extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback onBack;

  const VerifyProductScreen({
    super.key,
    required this.product,
    required this.onBack,
  });

  @override
  ConsumerState<VerifyProductScreen> createState() => _VerifyProductScreenState();
}

class _VerifyProductScreenState extends ConsumerState<VerifyProductScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _ingredientInputCtrl;
  late List<String> _ingredients;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _brandCtrl = TextEditingController(text: widget.product.brand);
    _ingredientInputCtrl = TextEditingController();
    _ingredients = List<String>.from(widget.product.ingredients);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _ingredientInputCtrl.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _ingredientInputCtrl.text.trim();
    if (text.isNotEmpty && !_ingredients.contains(text)) {
      setState(() {
        _ingredients.add(text);
        _ingredientInputCtrl.clear();
      });
    }
  }

  void _removeIngredient(String name) {
    setState(() {
      _ingredients.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(scanNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifyProductInfo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.confirmBeforeAnalysis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.verifyIngredientsHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (widget.product.imageUrl != null && widget.product.imageUrl!.trim().isNotEmpty) ...[
              Center(
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.mintBg, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: widget.product.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_outlined, size: 40, color: AppColors.textHint),
                          const SizedBox(height: 4),
                          Text(
                            l10n.localeName == 'th' ? 'ไม่สามารถโหลดรูปภาพได้' : 'Unable to load image',
                            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.productNameRequired,
                hintText: l10n.productNameHint,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brandCtrl,
              decoration: InputDecoration(
                labelText: l10n.brandOptional,
                hintText: l10n.brandHint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.ingredientListCount(_ingredients.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ingredientInputCtrl,
              decoration: InputDecoration(
                hintText: l10n.addIngredientHint,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: _addIngredient,
                ),
              ),
              onSubmitted: (_) => _addIngredient(),
            ),
            const SizedBox(height: 16),
            if (_ingredients.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mintBg),
                ),
                child: Text(
                  l10n.noIngredientsYet,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredients.map((ing) {
                  return Chip(
                    label: Text(ing),
                    backgroundColor: AppColors.mintBg,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeIngredient(ing),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterProductName)),
                );
                return;
              }
              final finalProd = widget.product.copyWith(
                name: name,
                brand: _brandCtrl.text.trim(),
                ingredients: _ingredients,
              );
              notifier.analyzeAndSave(finalProd);
            },
            child: Text(l10n.analyzeWithAI),
          ),
        ),
      ),
    );
  }
}
