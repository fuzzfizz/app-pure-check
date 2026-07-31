import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/product.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  final String barcode;
  final VoidCallback onBack;

  const ManualEntryScreen({
    super.key,
    required this.barcode,
    required this.onBack,
  });

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _ingredientsCtrl.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final name = _nameCtrl.text.trim();
    final ingredientsText = _ingredientsCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterProductName)),
      );
      return;
    }

    if (ingredientsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterIngredients)),
      );
      return;
    }

    // Split ingredients text by commas or semicolons
    final ingredientsList = ingredientsText
        .split(RegExp(r'[,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final product = Product(
      id: '',
      barcode: widget.barcode,
      name: name,
      brand: _brandCtrl.text.trim(),
      ingredients: ingredientsList,
      rawIngredientsText: ingredientsText,
      source: ProductSource.userEntered,
    );

    ref.read(scanNotifierProvider.notifier).setManualProduct(product);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productNotFound),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.caution.withAlpha(20),
                border: Border.all(color: AppColors.caution.withAlpha(100)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.caution),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.barcodeNotFoundMessage(widget.barcode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            TextField(
              controller: _ingredientsCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.allIngredientsSeparated,
                hintText: l10n.ingredientsPlaceholder,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () => _submit(l10n),
            child: Text(l10n.doneAndContinue),
          ),
        ),
      ),
    );
  }
}
