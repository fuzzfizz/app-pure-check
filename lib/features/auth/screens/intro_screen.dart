import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class _Slide {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Slide(this.title, this.subtitle, this.icon);
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final slides = [
      _Slide(l10n.scanBarcode, l10n.scanBarcodeHint, Icons.qr_code_scanner_rounded),
      _Slide(l10n.quickAnalysis, l10n.analyzingAgainstProfile, Icons.auto_awesome_rounded),
      _Slide(l10n.ingredients, l10n.ingredientGenericInfo, Icons.science_rounded),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(s.icon, size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(s.title,
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(s.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.textHint,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => context.go('/register'),
                child: Text(l10n.getStarted),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text('${l10n.alreadyHaveAccount} ${l10n.loginHere}'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
