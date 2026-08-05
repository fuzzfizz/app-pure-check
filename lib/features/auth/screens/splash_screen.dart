import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await ref.read(authNotifierProvider.notifier).refreshProfile();
    if (!mounted) return;
    final status = ref.read(authNotifierProvider).status;
    switch (status) {
      case AuthStatus.unauthenticated:
        context.go('/intro');
        break;
      case AuthStatus.needsOnboarding:
        context.go('/onboarding');
        break;
      case AuthStatus.authenticated:
        context.go('/home');
        break;
      case AuthStatus.loading:
        context.go('/intro');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 56),
            ),
            const SizedBox(height: 24),
            Text('PureCheck',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.white)),
            const SizedBox(height: 8),
            Text(l10n.introSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withAlpha(204))),
          ],
        ),
      ),
    );
  }
}
