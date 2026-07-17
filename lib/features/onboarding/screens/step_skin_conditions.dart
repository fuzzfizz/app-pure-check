import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class StepSkinConditions extends ConsumerWidget {
  const StepSkinConditions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    final conditions = [
      _ConditionItem('acne_prone', 'เป็นสิวง่าย / ผิวมันเป็นสิว', Icons.bug_report_rounded),
      _ConditionItem('eczema', 'โรคผื่นภูมิแพ้ผิวหนัง (Eczema)', Icons.masks_rounded),
      _ConditionItem('rosacea', 'โรคผิวหนังอักเสบโรซาเชีย (Rosacea)', Icons.wb_twilight_rounded),
      _ConditionItem('psoriasis', 'โรคสะเก็ดเงิน (Psoriasis)', Icons.coronavirus_rounded),
      _ConditionItem('none', 'ไม่มีภาวะโรคผิวหนังข้างต้น', Icons.healing_rounded),
    ];

    final healthFlags = [
      _ConditionItem('pregnant', 'กำลังตั้งครรภ์ (Pregnancy)', Icons.pregnant_woman_rounded),
      _ConditionItem('breastfeeding', 'กำลังให้นมบุตร (Breastfeeding)', Icons.baby_changing_station_rounded),
      _ConditionItem('prescribed_actives', 'กำลังใช้ยารักษาสิว/ยาจากแพทย์', Icons.medical_services_rounded),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ภาวะผิวและข้อควรระวังด้านสุขภาพ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'เลือกภาวะผิวหรือปัจจัยที่ส่งผลต่อการใช้ผลิตภัณฑ์ของคุณ (เลือกได้มากกว่าหนึ่ง)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Text(
            'ภาวะผิวหนัง',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...conditions.map((item) {
            final isSelected = onboardingState.skinConditions.contains(item.key);
            return _buildTile(context, item, isSelected, () {
              if (item.key == 'none') {
                // If None selected, clear others
                if (!isSelected) {
                  for (final cond in onboardingState.skinConditions) {
                    if (cond != 'pregnant' && cond != 'breastfeeding' && cond != 'prescribed_actives') {
                      notifier.toggleSkinCondition(cond);
                    }
                  }
                  notifier.toggleSkinCondition('none');
                } else {
                  notifier.toggleSkinCondition('none');
                }
              } else {
                // If other condition selected, remove 'none' if it exists
                if (onboardingState.skinConditions.contains('none')) {
                  notifier.toggleSkinCondition('none');
                }
                notifier.toggleSkinCondition(item.key);
              }
            });
          }),
          const SizedBox(height: 24),
          Text(
            'ข้อควรระวังด้านสุขภาพ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...healthFlags.map((item) {
            final isSelected = onboardingState.skinConditions.contains(item.key);
            return _buildTile(context, item, isSelected, () {
              notifier.toggleSkinCondition(item.key);
            });
          }),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    _ConditionItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mintBg : AppColors.white,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.mintBg,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: isSelected ? AppColors.primaryDark : AppColors.textSecondary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ),
              Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                onChanged: (_) => onTap(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionItem {
  final String key;
  final String label;
  final IconData icon;
  const _ConditionItem(this.key, this.label, this.icon);
}
