import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'step_skin_type.dart';
import 'step_skin_conditions.dart';
import 'step_allergens.dart';
import 'step_concerns.dart';
import 'onboarding_complete.dart';

class OnboardingShell extends ConsumerStatefulWidget {
  const OnboardingShell({super.key});
  @override
  ConsumerState<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends ConsumerState<OnboardingShell> {
  final _pageCtrl = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5; // 4 questions + complete screen

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == _totalSteps - 2) {
      setState(() => _currentStep = _totalSteps - 1);
    } else if (_currentStep < _totalSteps - 2) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we are on the completion screen, hide the shell framework (since it handles its own CTA)
    final isCompleteScreen = _currentStep == _totalSteps - 1;

    if (isCompleteScreen) {
      return const OnboardingComplete();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าโปรไฟล์ผิวของคุณ'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prev,
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / (_totalSteps - 1),
            backgroundColor: AppColors.mintBg,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(), // Force using buttons
        onPageChanged: (i) => setState(() => _currentStep = i),
        children: const [
          StepSkinType(),
          StepSkinConditions(),
          StepAllergens(),
          StepConcerns(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prev,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      foregroundColor: AppColors.primaryDark,
                    ),
                    child: const Text('ย้อนกลับ'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_currentStep == _totalSteps - 2 ? 'เสร็จสิ้น' : 'ถัดไป'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
