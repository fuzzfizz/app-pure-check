import 'package:flutter/material.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';

class TypoCorrectionDialog extends StatelessWidget {
  final Map<String, String> corrections;

  const TypoCorrectionDialog({
    super.key,
    required this.corrections,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.didYouMeanTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.didYouMeanSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...corrections.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.keepOriginal),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(corrections),
          child: Text(l10n.acceptSuggestions),
        ),
      ],
    );
  }
}
