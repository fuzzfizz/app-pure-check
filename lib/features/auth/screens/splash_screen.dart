import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/intro');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('วิเคราะห์ส่วนผสม รู้ก่อนแพ้',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withAlpha(204))),
          ],
        ),
      ),
    );
  }
}
