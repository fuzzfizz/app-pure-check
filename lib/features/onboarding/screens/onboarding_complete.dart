import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingComplete extends ConsumerWidget {
  const OnboardingComplete({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    final summaryTitle = l10n.localeName == 'en' ? 'Profile Summary:' : 'สรุปโปรไฟล์ของคุณ:';
    final skinTypeLabel = l10n.localeName == 'en' ? 'Skin Type: ' : 'ประเภทผิว: ';
    final skinCondLabel = l10n.localeName == 'en' ? 'Skin Conditions: ' : 'ภาวะผิวหนัง/ข้อควรระวัง: ';
    final allergensLabel = l10n.localeName == 'en' ? 'Allergens: ' : 'สารที่แพ้ที่ระบุ: ';
    final concernsLabel = l10n.localeName == 'en' ? 'Skin Concerns: ' : 'ความกังวลผิว: ';
    final noneLabel = l10n.localeName == 'en' ? 'None' : 'ไม่มี';
    final itemsSuffix = l10n.localeName == 'en' ? ' items' : ' รายการ';
    final speciesSuffix = l10n.localeName == 'en' ? ' types' : ' ชนิด';

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
                l10n.onboardingCompleteTitle,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingCompleteMessage,
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
                    Text(summaryTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text('• $skinTypeLabel${state.skinType.label(context)}'),
                    Text('• $skinCondLabel${state.skinConditions.isEmpty ? noneLabel : "${state.skinConditions.length}$itemsSuffix"}'),
                    Text('• $allergensLabel${state.allergens.isEmpty ? noneLabel : "${state.allergens.length}$speciesSuffix"}'),
                    Text('• $concernsLabel${state.skinConcerns.isEmpty ? noneLabel : "${state.skinConcerns.length}$itemsSuffix"}'),
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
                    : Text(l10n.startUsing),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
