import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/allergen.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _allergenSearchCtrl = TextEditingController();

  SkinType? _draftSkinType;
  List<String> _draftConditions = [];
  List<String> _draftConcerns = [];
  List<Allergen> _draftAllergens = [];

  bool _isInitialized = false;
  bool _isSaving = false;

  void _initDraftIfNeeded(UserProfile profile, List<Allergen> allergens) {
    if (!_isInitialized) {
      _draftSkinType = profile.skinType;
      _draftConditions = List<String>.from(profile.skinConditions);
      _draftConcerns = List<String>.from(profile.skinConcerns);
      _draftAllergens = List<Allergen>.from(allergens);
      _isInitialized = true;
    }
  }

  void _resetDraft(UserProfile profile, List<Allergen> allergens) {
    setState(() {
      _draftSkinType = profile.skinType;
      _draftConditions = List<String>.from(profile.skinConditions);
      _draftConcerns = List<String>.from(profile.skinConcerns);
      _draftAllergens = List<Allergen>.from(allergens);
    });
  }

  bool _hasUnsavedChanges(UserProfile originalProfile, List<Allergen> originalAllergens) {
    if (!_isInitialized) return false;

    if (_draftSkinType != originalProfile.skinType) return true;

    if (!setEquals(_draftConditions.toSet(), originalProfile.skinConditions.toSet())) return true;

    if (!setEquals(_draftConcerns.toSet(), originalProfile.skinConcerns.toSet())) return true;

    // Compare allergens
    final originalIds = originalAllergens.map((a) => a.id).toSet();
    final draftIds = _draftAllergens.map((a) => a.id).where((id) => id.isNotEmpty).toSet();

    if (!setEquals(originalIds, draftIds)) return true;

    // Check newly added allergens (id is empty)
    if (_draftAllergens.any((a) => a.id.isEmpty)) return true;

    return false;
  }

  Future<void> _saveAllChanges(UserProfile currentProfile, List<Allergen> originalAllergens) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      // 1. Update Profile (Skin type, conditions, concerns)
      final updatedProfile = currentProfile.copyWith(
        skinType: _draftSkinType ?? currentProfile.skinType,
        skinConditions: _draftConditions,
        skinConcerns: _draftConcerns,
      );

      await ref.read(profileNotifierProvider.notifier).updateProfile(updatedProfile);

      // 2. Handle Allergen deletions
      final draftIds = _draftAllergens.map((a) => a.id).where((id) => id.isNotEmpty).toSet();
      for (final original in originalAllergens) {
        if (!draftIds.contains(original.id)) {
          await ref.read(profileNotifierProvider.notifier).removeAllergen(original.id);
        }
      }

      // 3. Handle Allergen additions
      for (final draft in _draftAllergens) {
        if (draft.id.isEmpty) {
          await ref.read(profileNotifierProvider.notifier).addAllergen(draft.ingredientName);
        }
      }

      // Reset initialization flag so next build syncs with refreshed provider data
      setState(() {
        _isSaving = false;
        _isInitialized = false;
      });

      if (mounted) {
        final isTh = ref.read(localeProvider).languageCode == 'th';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.white),
                const SizedBox(width: 8),
                Text(isTh ? 'บันทึกข้อมูลโปรไฟล์ผิวสำเร็จ' : 'Skin profile saved successfully'),
              ],
            ),
            backgroundColor: AppColors.safe,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _allergenSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentProfileProvider);
    final allergensAsync = ref.watch(userAllergensProvider);
    final isTh = ref.watch(localeProvider).languageCode == 'th';

    final conditions = [
      _ConditionItem('acne_prone', l10n.conditionAcneProne),
      _ConditionItem('eczema', l10n.conditionEczema),
      _ConditionItem('rosacea', l10n.conditionRosacea),
      _ConditionItem('psoriasis', l10n.conditionPsoriasis),
    ];

    final concerns = [
      _ConcernItem('acne', l10n.concernAcne),
      _ConcernItem('dark_spots', l10n.concernDarkSpots),
      _ConcernItem('wrinkles', l10n.concernWrinkles),
      _ConcernItem('pores', l10n.concernPores),
      _ConcernItem('dullness', l10n.concernDullness),
      _ConcernItem('redness', l10n.concernRedness),
      _ConcernItem('dehydrated', l10n.concernDehydrated),
    ];

    return profileAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.skinProfileAndAllergy)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.skinProfileAndAllergy)),
        body: Center(child: Text(l10n.errorGeneric(err.toString()))),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.skinProfileAndAllergy)),
            body: Center(child: Text(l10n.profileNotFound)),
          );
        }

        return allergensAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: Text(l10n.skinProfileAndAllergy)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Scaffold(
            appBar: AppBar(title: Text(l10n.skinProfileAndAllergy)),
            body: Center(child: Text(l10n.errorGeneric(err.toString()))),
          ),
          data: (allergensList) {
            _initDraftIfNeeded(profile, allergensList);
            final hasChanges = _hasUnsavedChanges(profile, allergensList);

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.skinProfileAndAllergy),
                actions: [
                  if (hasChanges)
                    TextButton.icon(
                      onPressed: _isSaving ? null : () => _resetDraft(profile, allergensList),
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                      label: Text(
                        isTh ? 'รีเซ็ต' : 'Reset',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner warning if changes are present
                    if (hasChanges) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.caution.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.caution.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: AppColors.caution),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isTh
                                    ? 'มีการแก้ไขข้อมูลเพิ่มเติม อย่าลืมกด "บันทึกข้อมูล" ด้านล่าง'
                                    : 'Profile modified. Tap "Save Profile" below to apply.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 1. Skin Type Section
                    Text(l10n.skinType, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(
                          color: hasChanges && _draftSkinType != profile.skinType
                              ? AppColors.primary
                              : AppColors.mintBg,
                          width: hasChanges && _draftSkinType != profile.skinType ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SkinType>(
                          value: _draftSkinType,
                          isExpanded: true,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _draftSkinType = val;
                              });
                            }
                          },
                          items: SkinType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.label(context)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 2. Conditions Section
                    Text(l10n.skinConditions, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: conditions.map((item) {
                        final isSelected = _draftConditions.contains(item.key);
                        return FilterChip(
                          label: Text(item.label),
                          selected: isSelected,
                          selectedColor: AppColors.mintBg,
                          checkmarkColor: AppColors.primaryDark,
                          onSelected: (_) {
                            setState(() {
                              if (isSelected) {
                                _draftConditions.remove(item.key);
                              } else {
                                _draftConditions.add(item.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // 3. Concerns Section
                    Text(l10n.skinConcerns, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: concerns.map((item) {
                        final isSelected = _draftConcerns.contains(item.key);
                        return FilterChip(
                          label: Text(item.label),
                          selected: isSelected,
                          selectedColor: AppColors.mintBg,
                          checkmarkColor: AppColors.primaryDark,
                          onSelected: (_) {
                            setState(() {
                              if (isSelected) {
                                _draftConcerns.remove(item.key);
                              } else {
                                _draftConcerns.add(item.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),

                    // 4. Allergens Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.yourAllergens, style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          onPressed: () => _showAddAllergenDialog(l10n),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_draftAllergens.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          l10n.noAllergensRecorded,
                          style: const TextStyle(color: AppColors.textHint, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _draftAllergens.map((allergen) {
                          final isNew = allergen.id.isEmpty;
                          return Chip(
                            label: Text(
                              isNew ? '${allergen.ingredientName} (ใหม่)' : allergen.ingredientName,
                            ),
                            backgroundColor: isNew
                                ? AppColors.caution.withValues(alpha: 0.2)
                                : AppColors.danger.withValues(alpha: 0.15),
                            side: BorderSide(color: isNew ? AppColors.caution : AppColors.danger),
                            deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                            onDeleted: () {
                              setState(() {
                                _draftAllergens.removeWhere((a) =>
                                    (a.id.isNotEmpty && a.id == allergen.id) ||
                                    (a.id.isEmpty && a.ingredientName == allergen.ingredientName));
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              bottomSheet: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: (hasChanges && !_isSaving)
                        ? () => _saveAllChanges(profile, allergensList)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasChanges ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.4),
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.3),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isTh ? 'บันทึกข้อมูลโปรไฟล์ผิว' : 'Save Skin Profile',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAllergenDialog(AppLocalizations l10n) {
    final user = ref.read(currentUserProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addAllergen),
          content: TextField(
            controller: _allergenSearchCtrl,
            decoration: InputDecoration(
              hintText: l10n.allergenNameHint,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _allergenSearchCtrl.clear();
                Navigator.pop(context);
              },
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final name = _allergenSearchCtrl.text.trim();
                if (name.isNotEmpty) {
                  final exists = _draftAllergens.any(
                    (a) => a.ingredientName.toLowerCase() == name.toLowerCase(),
                  );

                  if (!exists) {
                    setState(() {
                      _draftAllergens.add(
                        Allergen(
                          id: '', // Empty ID indicates a new local addition
                          userId: user?.id ?? '',
                          ingredientName: name,
                          severity: AllergenSeverity.moderate,
                          reactionSymptoms: ['แดง', 'คัน'],
                          source: AllergenSource.known,
                        ),
                      );
                    });
                  }

                  _allergenSearchCtrl.clear();
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );
  }
}

class _ConditionItem {
  final String key;
  final String label;
  const _ConditionItem(this.key, this.label);
}

class _ConcernItem {
  final String key;
  final String label;
  const _ConcernItem(this.key, this.label);
}
