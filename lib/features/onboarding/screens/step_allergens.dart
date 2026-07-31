import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/allergen.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class StepAllergens extends ConsumerStatefulWidget {
  const StepAllergens({super.key});
  @override
  ConsumerState<StepAllergens> createState() => _StepAllergensState();
}

class _StepAllergensState extends ConsumerState<StepAllergens> {
  int _selectedPath = -1; // -1: Not selected, 0: Knows, 1: Unsure, 2: None
  final _searchCtrl = TextEditingController();

  void _addAllergen(String name, AllergenSeverity severity, List<String> symptoms) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    // Check if already added
    final exists = ref.read(onboardingNotifierProvider).allergens.any(
      (a) => a.ingredientName.toLowerCase() == name.toLowerCase()
    );
    if (exists) return;

    final allergen = Allergen(
      id: '',
      userId: user.id,
      ingredientName: name,
      severity: severity,
      reactionSymptoms: symptoms,
      source: AllergenSource.known,
    );
    ref.read(onboardingNotifierProvider.notifier).addAllergen(allergen);
  }

  void _showAllergenDialog(String name, AppLocalizations l10n) {
    AllergenSeverity selectedSeverity = AllergenSeverity.moderate;
    final List<String> selectedSymptoms = [];
    final symptoms = l10n.localeName == 'en'
        ? const ['Redness', 'Itching', 'Rash', 'Burning']
        : const ['แดง', 'คัน', 'ผื่น', 'แสบร้อน'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.localeName == 'en' ? 'Set up allergen: $name' : 'ตั้งค่าสารแพ้: $name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.localeName == 'en' ? 'Severity of allergic reaction:' : 'ระดับความรุนแรงของอาการแพ้:'),
                  const SizedBox(height: 8),
                  DropdownButton<AllergenSeverity>(
                    value: selectedSeverity,
                    isExpanded: true,
                    onChanged: (val) {
                      if (val != null) setState(() => selectedSeverity = val);
                    },
                    items: AllergenSeverity.values.map((e) {
                      String label = l10n.localeName == 'en' ? 'Moderate' : 'ปานกลาง';
                      if (e == AllergenSeverity.mild) label = l10n.localeName == 'en' ? 'Mild' : 'เล็กน้อย';
                      if (e == AllergenSeverity.severe) label = l10n.localeName == 'en' ? 'Severe' : 'รุนแรงมาก';
                      return DropdownMenuItem(value: e, child: Text(label));
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.localeName == 'en' ? 'Symptoms occurred (select multiple):' : 'อาการที่เกิดขึ้น (เลือกได้มากกว่าหนึ่ง):'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: symptoms.map((sym) {
                      final isSelected = selectedSymptoms.contains(sym);
                      return ChoiceChip(
                        label: Text(sym),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedSymptoms.add(sym);
                            } else {
                              selectedSymptoms.remove(sym);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    _addAllergen(name, selectedSeverity, selectedSymptoms);
                    Navigator.pop(context);
                  },
                  child: Text(l10n.add),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    final commonIrritants = l10n.localeName == 'en'
        ? const [
            'Fragrance',
            'Alcohol',
            'Parabens',
            'Silicones',
            'Mineral Oil',
            'Essential Oils',
          ]
        : const [
            'Fragrance (น้ำหอม)',
            'Alcohol (แอลกอฮอล์)',
            'Parabens (พาราเบน)',
            'Silicones (ซิลิโคน)',
            'Mineral Oil (น้ำมันแร่)',
            'Essential Oils (น้ำมันหอมระเหย)',
          ];

    final pathTitle1 = l10n.localeName == 'en' ? 'I know what I\'m allergic to' : 'ฉันรู้สารที่ฉันแพ้';
    final pathDesc1 = l10n.localeName == 'en' ? 'Specify the chemicals or ingredients you are allergic to directly' : 'ระบุสารเคมีหรือส่วนผสมที่คุณแพ้โดยตรง';
    final pathTitle2 = l10n.localeName == 'en' ? 'I\'m not sure what I\'m allergic to' : 'ฉันไม่แน่ใจว่าแพ้อะไร';
    final pathDesc2 = l10n.localeName == 'en' ? 'Check from the list of common skin irritants' : 'ตรวจสอบจากกลุ่มสารก่อระคายเคืองที่พบบ่อย';
    final pathTitle3 = l10n.localeName == 'en' ? 'I have no allergy history' : 'ฉันไม่มีประวัติการแพ้';
    final pathDesc3 = l10n.localeName == 'en' ? 'Analyze suitability based solely on your skin type' : 'วิเคราะห์ความเหมาะสมเฉพาะสภาพผิวของคุณ';

    if (_selectedPath == -1) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.allergensQuestion,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.allergensHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildPathCard(
              context,
              0,
              pathTitle1,
              pathDesc1,
              Icons.search_rounded,
            ),
            const SizedBox(height: 16),
            _buildPathCard(
              context,
              1,
              pathTitle2,
              pathDesc2,
              Icons.help_outline_rounded,
            ),
            const SizedBox(height: 16),
            _buildPathCard(
              context,
              2,
              pathTitle3,
              pathDesc3,
              Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedPath = -1),
              ),
              Expanded(
                child: Text(
                  _selectedPath == 0
                      ? (l10n.localeName == 'en' ? 'Search and specify allergens' : 'ค้นหาและระบุสารที่แพ้')
                      : _selectedPath == 1
                          ? (l10n.localeName == 'en' ? 'Evaluate from common irritants' : 'ประเมินจากสารระคายเคืองทั่วไป')
                          : pathTitle3,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedPath == 0) ...[
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.allergenNameHint,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  onPressed: () {
                    final name = _searchCtrl.text.trim();
                    if (name.isNotEmpty) {
                      _showAllergenDialog(name, l10n);
                      _searchCtrl.clear();
                    }
                  },
                ),
              ),
              onSubmitted: (name) {
                final text = name.trim();
                if (text.isNotEmpty) {
                  _showAllergenDialog(text, l10n);
                  _searchCtrl.clear();
                }
              },
            ),
            const SizedBox(height: 20),
            Text(l10n.localeName == 'en' ? 'Allergens you specified:' : 'รายการสารที่แพ้ที่คุณระบุ:'),
            const SizedBox(height: 8),
            if (onboardingState.allergens.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.localeName == 'en' ? 'No allergens added yet' : 'ยังไม่ได้เพิ่มสารที่แพ้',
                  style: TextStyle(color: AppColors.textHint, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: onboardingState.allergens.map((allergen) {
                  return Chip(
                    label: Text(allergen.ingredientName),
                    backgroundColor: AppColors.mintBg,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => notifier.removeAllergen(allergen.ingredientName),
                  );
                }).toList(),
              ),
          ] else if (_selectedPath == 1) ...[
            Text(
              l10n.localeName == 'en' ? 'Select ingredients that have caused redness, itching, burning, or allergy:' : 'เลือกสารที่คุณเคยใช้แล้วมีอาการแดง คัน แสน หรือแพ้:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...commonIrritants.map((name) {
              final isSelected = onboardingState.allergens.any((a) => a.ingredientName == name);
              return CheckboxListTile(
                title: Text(name),
                value: isSelected,
                activeColor: AppColors.primary,
                onChanged: (selected) {
                  if (selected == true) {
                    _showAllergenDialog(name, l10n);
                  } else {
                    notifier.removeAllergen(name);
                  }
                },
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.mintBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 64, color: AppColors.safe),
                  const SizedBox(height: 16),
                  Text(
                    l10n.localeName == 'en' ? 'Excellent! The system will analyze based on your skin type and avoid ingredients that may cause irritation.' : 'ยอดเยี่ยม! ระบบจะวิเคราะห์โดยอ้างอิงสภาพผิวและหลีกเลี่ยงส่วนผสมที่อาจก่อให้เกิดการระคายเคืองตามประเภทผิวของคุณแทน',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPathCard(
    BuildContext context,
    int pathIndex,
    String title,
    String desc,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        setState(() => _selectedPath = pathIndex);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.mintBg),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.mintBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(desc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
