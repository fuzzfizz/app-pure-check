import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/inci_core_dataset.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/product.dart';
import '../../../core/services/inci_search_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
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
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _imageBytes;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot select image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  void _showImageSourceModal(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.mintBg,
                    child: Icon(Icons.camera_alt_outlined, color: AppColors.primaryDark),
                  ),
                  title: Text(l10n.takePhoto),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.mintBg,
                    child: Icon(Icons.photo_library_outlined, color: AppColors.primaryDark),
                  ),
                  title: Text(l10n.chooseFromGallery),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
        final supabaseService = ref.read(supabaseServiceProvider);
        final typos = await supabaseService.checkIngredientTypos(unrecognized);

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

      String? uploadedImageUrl;
      if (_imageBytes != null) {
        try {
          final supabaseService = ref.read(supabaseServiceProvider);
          final ext = _selectedImage?.name.split('.').last.toLowerCase() ?? 'jpg';
          uploadedImageUrl = await supabaseService.uploadProductImage(
            barcode: widget.barcode,
            bytes: _imageBytes!,
            fileExtension: ext.isNotEmpty ? ext : 'jpg',
          );
        } catch (_) {}
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
        imageUrl: uploadedImageUrl,
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
            const SizedBox(height: 20),
            // Product Image Picker Card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imageBytes != null
                  ? Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Image.memory(
                          _imageBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.black.withAlpha(150),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showImageSourceModal(l10n),
                                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                                label: Text(l10n.changePhoto, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                              IconButton(
                                onPressed: _removeImage,
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                tooltip: l10n.removePhoto,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: () => _showImageSourceModal(l10n),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withAlpha(25),
                              child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 26),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.productPhoto,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.localeName == 'th'
                                  ? 'แตะเพื่อถ่ายรูปกล่อง หรือเลือกจากอัลบั้ม'
                                  : 'Tap to capture product photo or choose from gallery',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
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
