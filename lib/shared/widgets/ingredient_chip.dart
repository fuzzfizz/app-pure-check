import 'package:flutter/material.dart';
import '../../core/models/analysis_result.dart';
import '../../core/theme/app_theme.dart';

class IngredientChip extends StatelessWidget {
  final String name;
  final SafetyLevel riskLevel;
  final VoidCallback? onTap;

  const IngredientChip({
    super.key,
    required this.name,
    required this.riskLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    Color text = AppColors.textPrimary;

    switch (riskLevel) {
      case SafetyLevel.safe:
        border = AppColors.safe.withAlpha(80);
        bg = AppColors.safe.withAlpha(20);
        break;
      case SafetyLevel.caution:
        border = AppColors.caution.withAlpha(100);
        bg = AppColors.caution.withAlpha(25);
        break;
      case SafetyLevel.danger:
        border = AppColors.danger.withAlpha(120);
        bg = AppColors.danger.withAlpha(30);
        text = AppColors.danger;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: text,
                    fontWeight: riskLevel == SafetyLevel.danger ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.info_outline_rounded, size: 14, color: text.withAlpha(180)),
            ],
          ],
        ),
      ),
    );
  }
}
