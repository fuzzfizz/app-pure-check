import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class StepSkinType extends ConsumerWidget {
  const StepSkinType({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    final types = [
      _SkinTypeItem(SkinType.oily, 'ผิวหมองและมันเงาง่าย รูขุมขนกว้าง', Icons.water_drop_rounded),
      _SkinTypeItem(SkinType.dry, 'ผิวแห้งตึง ลอกเป็นขุยบ่อย', Icons.grain_rounded),
      _SkinTypeItem(SkinType.combination, 'มันบริเวณ T-zone และแห้งบริเวณแก้ม', Icons.gradient_rounded),
      _SkinTypeItem(SkinType.normal, 'ผิวสมดุลดี ไม่แห้งหรือไม่มันจนเกินไป', Icons.face_rounded),
      _SkinTypeItem(SkinType.sensitive, 'ผิวแพ้ง่าย แดงระคายเคืองบ่อยเมื่อใช้ผลิตภัณฑ์', Icons.warning_amber_rounded),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ประเภทผิวของคุณคือแบบใด?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'เลือกข้อที่ตรงกับสภาพผิวของคุณที่สุด',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ...types.map((item) {
            final isSelected = onboardingState.skinType == item.type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => notifier.setSkinType(item.type),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mintBg : AppColors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.mintBg,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 36,
                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.type.labelTh,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isSelected ? AppColors.textPrimary.withAlpha(200) : AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryDark,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SkinTypeItem {
  final SkinType type;
  final String description;
  final IconData icon;
  const _SkinTypeItem(this.type, this.description, this.icon);
}
