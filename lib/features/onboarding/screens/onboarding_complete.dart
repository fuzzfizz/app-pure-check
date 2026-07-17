import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingComplete extends ConsumerWidget {
  const OnboardingComplete({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'ตั้งค่าโปรไฟล์ผิวของคุณเรียบร้อย!',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'PureCheck พร้อมวิเคราะห์ความปลอดภัยของสารเคมีและส่วนผสมที่เหมาะกับผิวคุณแล้ว',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สรุปโปรไฟล์ของคุณ:', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text('• ประเภทผิว: ${state.skinType.labelTh}'),
                    Text('• ภาวะผิวหนัง/ข้อควรระวัง: ${state.skinConditions.isEmpty ? "ไม่มี" : state.skinConditions.length} รายการ'),
                    Text('• สารที่แพ้ที่ระบุ: ${state.allergens.isEmpty ? "ไม่มี" : state.allergens.length} ชนิด'),
                    Text('• ความกังวลผิว: ${state.skinConcerns.isEmpty ? "ไม่มี" : state.skinConcerns.length} รายการ'),
                  ],
                ),
              ),
              const Spacer(),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: state.loading
                    ? null
                    : () async {
                        final success = await notifier.completeOnboarding();
                        if (success && context.mounted) {
                          context.go('/home');
                        }
                      },
                child: state.loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('เริ่มสแกนผลิตภัณฑ์แรกเลย!'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
