import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class StepConcerns extends ConsumerWidget {
  const StepConcerns({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    final concerns = [
      _ConcernItem('acne', 'สิว (Acne)'),
      _ConcernItem('dark_spots', 'ฝ้า / จุดด่างดำ (Dark spots)'),
      _ConcernItem('wrinkles', 'ริ้วรอยก่อนวัย (Wrinkles)'),
      _ConcernItem('pores', 'รูขุมขนกว้าง (Pores)'),
      _ConcernItem('dullness', 'ผิวหมองคล้ำ (Dullness)'),
      _ConcernItem('redness', 'ผิวแดงระคายเคืองง่าย (Redness)'),
      _ConcernItem('dehydrated', 'ผิวขาดน้ำ / แห้งกร้าน (Dehydrated)'),
    ];

    final avoids = [
      _ConcernItem('fragrance', 'Fragrance (น้ำหอม)'),
      _ConcernItem('alcohol', 'Alcohol (แอลกอฮอล์)'),
      _ConcernItem('paraben', 'Parabens (พาราเบน)'),
      _ConcernItem('silicone', 'Silicones (ซิลิโคน)'),
      _ConcernItem('mineral_oil', 'Mineral Oil (น้ำมันแร่)'),
      _ConcernItem('essential_oil', 'Essential Oils (น้ำมันหอมระเหย)'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ความกังวลผิวและส่วนผสมที่อยากเลี่ยง',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'ข้อมูลส่วนนี้ช่วยให้ AI ให้คำแนะนำที่ตรงจุดยิ่งขึ้น (กดข้ามได้หากไม่กังวล)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Text(
            'ความกังวลเรื่องผิวพรรณ',
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
            'ส่วนผสมที่ต้องการหลีกเลี่ยง (ความชอบ/ความกังวล)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'แตกต่างจากอาการแพ้ สารในกลุ่มนี้คือสารที่คุณต้องการเลี่ยงโดยทั่วไปเพื่อถนอมผิว',
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
