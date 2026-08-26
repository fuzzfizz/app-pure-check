import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/inci_core_dataset.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/product.dart';
import '../../../core/services/inci_search_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/repositories/scan_repository_impl.dart';
import '../providers/scan_provider.dart';
import '../widgets/typo_correction_dialog.dart';

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

  Timer? _debounceTimer;
  List<String> _suggestions = [];
  int _activeTokenStart = 0;
  int _activeTokenEnd = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _ingredientsCtrl.addListener(_onIngredientsChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _ingredientsCtrl.removeListener(_onIngredientsChanged);
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _ingredientsCtrl.dispose();
    super.dispose();
  }

  void _onIngredientsChanged() {
    final text = _ingredientsCtrl.text;
    final selection = _ingredientsCtrl.selection;
    final cursor = selection.baseOffset;

    if (cursor < 0 || cursor > text.length) {
      _clearSuggestions();
      return;
    }

    int start = text.lastIndexOf(RegExp(r'[,;]'), (cursor - 1).clamp(0, text.length));
    start = (start == -1) ? 0 : start + 1;

    int end = text.indexOf(RegExp(r'[,;]'), cursor);
    if (end == -1) end = text.length;

    final rawToken = text.substring(start, end);
    final token = rawToken.trim();

    if (token.length >= 3) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        final results = await ref
            .read(inciSearchServiceProvider)
            .searchIngredients(token, limit: 5);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _activeTokenStart = start;
            _activeTokenEnd = end;
          });
        }
      });
    } else {
      _clearSuggestions();
    }
  }

  void _clearSuggestions() {
    _debounceTimer?.cancel();
    if (_suggestions.isNotEmpty) {
      setState(() {
        _suggestions = [];
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    final text = _ingredientsCtrl.text;
    final prefix = text.substring(0, _activeTokenStart);
    final suffix = text.substring(_activeTokenEnd.clamp(0, text.length));

    final leadingSpace = (prefix.isNotEmpty && !prefix.endsWith(' ') && !prefix.endsWith(',')) ? ' ' : '';
    final trailing = (suffix.isEmpty || suffix.startsWith(RegExp(r'[,;\s]'))) ? ', ' : '';

    final newText = '$prefix$leadingSpace$suggestion$trailing$suffix';
    _ingredientsCtrl.text = newText;

    final newCursorPos = (prefix + leadingSpace + suggestion + trailing).length;
    _ingredientsCtrl.selection = TextSelection.collapsed(
      offset: newCursorPos.clamp(0, newText.length),
    );

    _clearSuggestions();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (_isSubmitting) return;

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

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> ingredientsList = ingredientsText
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final inciSearchService = ref.read(inciSearchServiceProvider);
      final unrecognized = await inciSearchService.filterUnrecognizedIngredients(ingredientsList);

      if (unrecognized.isNotEmpty) {
        final geminiService = ref.read(geminiServiceProvider);
        final typos = await geminiService.checkIngredientTypos(unrecognized);

        if (typos.isNotEmpty && mounted) {
          final acceptedCorrections = await showDialog<Map<String, String>>(
            context: context,
            builder: (ctx) => TypoCorrectionDialog(corrections: typos),
          );

          if (acceptedCorrections != null) {
            ingredientsList = ingredientsList.map((ing) {
              return acceptedCorrections[ing] ?? ing;
            }).toList();
          }
        }
      }

      final user = ref.read(currentUserProvider);
      final product = Product(
        id: '',
        barcode: widget.barcode,
        name: name,
        brand: _brandCtrl.text.trim(),
        ingredients: ingredientsList,
        rawIngredientsText: ingredientsText,
        source: ProductSource.userEntered,
        status: 'pending',
        isVerified: false,
        submittedBy: user?.id,
      );

      if (mounted) {
        ref.read(scanNotifierProvider.notifier).setManualProduct(product);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
                helperText: _ingredientsCtrl.text.trim().isNotEmpty
                    ? (l10n.localeName == 'th'
                        ? 'ตรวจพบ ${_ingredientsCtrl.text.split(RegExp(r'[,;]')).where((s) => s.trim().isNotEmpty).length} ส่วนผสม'
                        : 'Detected ${_ingredientsCtrl.text.split(RegExp(r'[,;]')).where((s) => s.trim().isNotEmpty).length} ingredients')
                    : (l10n.localeName == 'th'
                        ? 'คั่นแต่ละส่วนผสมด้วยเครื่องหมายจุลภาค (,)'
                        : 'Separate each ingredient with a comma (,)'),
                helperStyle: TextStyle(
                  color: _ingredientsCtrl.text.trim().isNotEmpty
                      ? AppColors.primary
                      : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          l10n.localeName == 'th'
                              ? 'คำแนะนำส่วนผสมมาตรฐาน (INCI):'
                              : 'Standard INCI Suggestions:',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _suggestions.map((suggestion) {
                        final inciInfo = InciCoreDataset.find(suggestion);
                        final labelText = inciInfo != null
                            ? '$suggestion (${inciInfo.category})'
                            : suggestion;

                        return ActionChip(
                          avatar: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                          label: Text(
                            labelText,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _selectSuggestion(suggestion),
                          backgroundColor: AppColors.primary.withAlpha(15),
                          side: BorderSide(color: AppColors.primary.withAlpha(50)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submit(l10n),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.doneAndContinue),
          ),
        ),
      ),
    );
  }
}
