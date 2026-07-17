import 'package:flutter/material.dart';
import '../../core/models/analysis_result.dart';
import '../../core/theme/app_theme.dart';

class SafetyBadge extends StatelessWidget {
  final SafetyLevel level;
  final double fontSize;
  final EdgeInsets padding;

  const SafetyBadge({
    super.key,
    required this.level,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text = AppColors.white;
    String label = level.labelTh;

    switch (level) {
      case SafetyLevel.safe:
        bg = AppColors.safe;
        break;
      case SafetyLevel.caution:
        bg = AppColors.caution;
        break;
      case SafetyLevel.danger:
        bg = AppColors.danger;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: text,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
