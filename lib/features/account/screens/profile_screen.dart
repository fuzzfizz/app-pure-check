import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final profileAsync = ref.watch(currentProfileProvider);
    final allergensAsync = ref.watch(userAllergensProvider);
    final state = ref.watch(profileNotifierProvider);

    final conditions = [
      _ConditionItem('acne_prone', 'เป็นสิวง่าย / ผิวมันเป็นสิว'),
      _ConditionItem('eczema', 'โรคผื่นภูมิแพ้ผิวหนัง (Eczema)'),
      _ConditionItem('rosacea', 'โรคผิวหนังอักเสบโรซาเชีย (Rosacea)'),
      _ConditionItem('psoriasis', 'โรคสะเก็ดเงิน (Psoriasis)'),
    ];

    final concerns = [
      _ConcernItem('acne', 'สิว'),
      _ConcernItem('dark_spots', 'ฝ้า/จุดด่างดำ'),
      _ConcernItem('wrinkles', 'ริ้วรอย'),
      _ConcernItem('pores', 'รูขุมขนกว้าง'),
      _ConcernItem('dullness', 'ผิวหมองคล้ำ'),
      _ConcernItem('redness', 'ผิวแดงระคายเคืองง่าย'),
      _ConcernItem('dehydrated', 'ผิวขาดน้ำ'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์ผิว & ประวัติการแพ้'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
        data: (_) => profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('ไม่พบข้อมูลโปรไฟล์ผิว'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Skin Type
                  Text('ประเภทผิว', style: Theme.of(context).textTheme.titleMedium),
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
                            child: Text('ผิว${type.labelTh}'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Conditions
                  Text('ภาวะโรคผิวหนัง/ข้อควรระวัง', style: Theme.of(context).textTheme.titleMedium),
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
                  Text('ความกังวลผิว', style: Theme.of(context).textTheme.titleMedium),
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
                      Text('สารที่แพ้ของคุณ', style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onPressed: _showAddAllergenDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Allergens list
                  allergensAsync.when(
                    loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => Text('เกิดข้อผิดพลาด: $err'),
                    data: (allergensList) {
                      if (allergensList.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'ไม่มีสารที่ระบุประวัติการแพ้',
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

  void _showAddAllergenDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เพิ่มสารที่แพ้'),
          content: TextField(
            controller: _allergenSearchCtrl,
            decoration: const InputDecoration(
              hintText: 'ชื่อสาร เช่น Fragrance, Alcohol',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _allergenSearchCtrl.clear();
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก'),
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
              child: const Text('เพิ่ม'),
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
