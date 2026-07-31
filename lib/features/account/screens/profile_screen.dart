import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/user_profile.dart';
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

  Future<void> _updateSkinType(SkinType type, UserProfile current) async {
    final updated = current.copyWith(skinType: type);
    await ref.read(profileNotifierProvider.notifier).updateProfile(updated);
  }

  Future<void> _toggleCondition(String key, UserProfile current) async {
    final conditions = List<String>.from(current.skinConditions);
    if (conditions.contains(key)) {
      conditions.remove(key);
    } else {
      conditions.add(key);
    }
    final updated = current.copyWith(skinConditions: conditions);
    await ref.read(profileNotifierProvider.notifier).updateProfile(updated);
  }

  Future<void> _toggleConcern(String key, UserProfile current) async {
    final concerns = List<String>.from(current.skinConcerns);
    if (concerns.contains(key)) {
      concerns.remove(key);
    } else {
      concerns.add(key);
    }
    final updated = current.copyWith(skinConcerns: concerns);
    await ref.read(profileNotifierProvider.notifier).updateProfile(updated);
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
    final state = ref.watch(profileNotifierProvider);

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.skinProfileAndAllergy),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorGeneric(err.toString()))),
        data: (_) => profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(l10n.errorGeneric(err.toString()))),
          data: (profile) {
            if (profile == null) {
              return Center(child: Text(l10n.profileNotFound));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Skin Type
                  Text(l10n.skinType, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.mintBg),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SkinType>(
                        value: profile.skinType,
                        isExpanded: true,
                        onChanged: (val) {
                          if (val != null) _updateSkinType(val, profile);
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

                  // Conditions
                  Text(l10n.skinConditions, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: conditions.map((item) {
                      final isSelected = profile.skinConditions.contains(item.key);
                      return FilterChip(
                        label: Text(item.label),
                        selected: isSelected,
                        selectedColor: AppColors.mintBg,
                        checkmarkColor: AppColors.primaryDark,
                        onSelected: (_) => _toggleCondition(item.key, profile),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Concerns
                  Text(l10n.skinConcerns, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: concerns.map((item) {
                      final isSelected = profile.skinConcerns.contains(item.key);
                      return FilterChip(
                        label: Text(item.label),
                        selected: isSelected,
                        selectedColor: AppColors.mintBg,
                        checkmarkColor: AppColors.primaryDark,
                        onSelected: (_) => _toggleConcern(item.key, profile),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 36),

                  // Allergens Header
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

                  // Allergens list
                  allergensAsync.when(
                    loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => Text(l10n.errorGeneric(err.toString())),
                    data: (allergensList) {
                      if (allergensList.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            l10n.noAllergensRecorded,
                            style: TextStyle(color: AppColors.textHint, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allergensList.map((allergen) {
                          return Chip(
                            label: Text(allergen.ingredientName),
                            backgroundColor: AppColors.danger.withAlpha(20),
                            side: const BorderSide(color: AppColors.danger),
                            deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                            onDeleted: () {
                              ref.read(profileNotifierProvider.notifier).removeAllergen(allergen.id);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddAllergenDialog(AppLocalizations l10n) {
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
                  ref.read(profileNotifierProvider.notifier).addAllergen(name);
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
