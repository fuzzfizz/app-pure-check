import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_validator.dart';

class PasswordRequirementsView extends StatelessWidget {
  final String password;

  const PasswordRequirementsView({super.key, required this.password});

  Widget _buildRuleItem({
    required BuildContext context,
    required bool isMet,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? AppColors.success : AppColors.textSecondary,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasLength = PasswordValidator.hasMinLength(password);
    final hasUpper = PasswordValidator.hasUppercase(password);
    final hasLower = PasswordValidator.hasLowercase(password);
    final hasNum = PasswordValidator.hasNumber(password);
    final hasSpecial = PasswordValidator.hasSpecialChar(password);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRuleItem(
            context: context,
            isMet: hasLength,
            text: l10n.passwordRuleMinLength,
          ),
          _buildRuleItem(
            context: context,
            isMet: hasUpper,
            text: l10n.passwordRuleUppercase,
          ),
          _buildRuleItem(
            context: context,
            isMet: hasLower,
            text: l10n.passwordRuleLowercase,
          ),
          _buildRuleItem(
            context: context,
            isMet: hasNum,
            text: l10n.passwordRuleNumber,
          ),
          _buildRuleItem(
            context: context,
            isMet: hasSpecial,
            text: l10n.passwordRuleSpecialChar,
          ),
        ],
      ),
    );
  }
}
