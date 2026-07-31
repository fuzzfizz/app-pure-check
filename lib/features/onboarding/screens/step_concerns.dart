import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class StepConcerns extends ConsumerWidget {
  const StepConcerns({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    final concerns = [
      _ConcernItem('acne', l10n.concernAcne),
      _ConcernItem('dark_spots', l10n.concernDarkSpots),
      _ConcernItem('wrinkles', l10n.concernWrinkles),
      _ConcernItem('pores', l10n.concernPores),
      _ConcernItem('dullness', l10n.concernDullness),
      _ConcernItem('redness', l10n.concernRedness),
      _ConcernItem('dehydrated', l10n.concernDehydrated),
    ];

    final avoids = [
      _ConcernItem('fragrance', l10n.localeName == 'en' ? 'Fragrance' : 'Fragrance (น้ำหอม)'),
      _ConcernItem('alcohol', l10n.localeName == 'en' ? 'Alcohol' : 'Alcohol (แอลกอฮอล์)'),
      _ConcernItem('paraben', l10n.localeName == 'en' ? 'Parabens' : 'Parabens (พาราเบน)'),
      _ConcernItem('silicone', l10n.localeName == 'en' ? 'Silicones' : 'Silicones (ซิลิโคน)'),
      _ConcernItem('mineral_oil', l10n.localeName == 'en' ? 'Mineral Oil' : 'Mineral Oil (น้ำมันแร่)'),
      _ConcernItem('essential_oil', l10n.localeName == 'en' ? 'Essential Oils' : 'Essential Oils (น้ำมันหอมระเหย)'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.skinConcernsQuestion,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.skinConcernsHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.skinConcerns,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: concerns.map((item) {
              final isSelected = onboardingState.skinConcerns.contains(item.key);
              return FilterChip(
                label: Text(item.label),
                selected: isSelected,
                selectedColor: AppColors.mintBg,
                checkmarkColor: AppColors.primaryDark,
                onSelected: (_) => notifier.toggleSkinConcern(item.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.localeName == 'en' ? 'Ingredients to avoid (Preference/Concern)' : 'ส่วนผสมที่ต้องการหลีกเลี่ยง (ความชอบ/ความกังวล)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.localeName == 'en' ? 'Different from allergies, these are ingredients you generally wish to avoid to protect your skin.' : 'แตกต่างจากอาการแพ้ สารในกลุ่มนี้คือสารที่คุณต้องการเลี่ยงโดยทั่วไปเพื่อถนอมผิว',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...avoids.map((item) {
            final isSelected = onboardingState.avoidPreferences.contains(item.key);
            return SwitchListTile(
              title: Text(item.label),
              value: isSelected,
              onChanged: (_) => notifier.toggleAvoidPreference(item.key),
            );
          }),
        ],
      ),
    );
  }
}

class _ConcernItem {
  final String key;
  final String label;
  const _ConcernItem(this.key, this.label);
}
