import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/features/scan/widgets/typo_correction_dialog.dart';

void main() {
  final testCorrections = {
    'Waterr': 'Water',
    'Niacinamid': 'Niacinamide',
  };

  Widget buildTestableWidget({required Map<String, String> corrections, dynamic Function(dynamic)? onPopped}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                final result = await showDialog<Map<String, String>?>(
                  context: context,
                  builder: (context) => TypoCorrectionDialog(corrections: corrections),
                );
                onPopped?.call(result);
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );
  }

  group('TypoCorrectionDialog Widget Tests', () {
    testWidgets('renders dialog with title, subtitle, and correction items', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(corrections: testCorrections));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(TypoCorrectionDialog));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.didYouMeanTitle), findsOneWidget);
      expect(find.text(l10n.didYouMeanSubtitle), findsOneWidget);

      expect(find.text('Waterr'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Niacinamid'), findsOneWidget);
      expect(find.text('Niacinamide'), findsOneWidget);

      expect(find.widgetWithText(TextButton, l10n.keepOriginal), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, l10n.acceptSuggestions), findsOneWidget);
    });

    testWidgets('original typo text has lineThrough decoration and red color', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(corrections: testCorrections));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final typoTextWidget = tester.widget<Text>(find.text('Waterr'));
      expect(typoTextWidget.style?.decoration, TextDecoration.lineThrough);
      expect(typoTextWidget.style?.color, Colors.red);
    });

    testWidgets('suggested correction text has bold weight', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(corrections: testCorrections));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final suggestedTextWidget = tester.widget<Text>(find.text('Water'));
      expect(suggestedTextWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('tapping keepOriginal button pops null', (WidgetTester tester) async {
      dynamic poppedResult = 'NOT_SET';
      await tester.pumpWidget(buildTestableWidget(
        corrections: testCorrections,
        onPopped: (result) => poppedResult = result,
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(TypoCorrectionDialog));
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.widgetWithText(TextButton, l10n.keepOriginal));
      await tester.pumpAndSettle();

      expect(find.byType(TypoCorrectionDialog), findsNothing);
      expect(poppedResult, isNull);
    });

    testWidgets('tapping acceptSuggestions button pops corrections map', (WidgetTester tester) async {
      dynamic poppedResult;
      await tester.pumpWidget(buildTestableWidget(
        corrections: testCorrections,
        onPopped: (result) => poppedResult = result,
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(TypoCorrectionDialog));
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.widgetWithText(ElevatedButton, l10n.acceptSuggestions));
      await tester.pumpAndSettle();

      expect(find.byType(TypoCorrectionDialog), findsNothing);
      expect(poppedResult, equals(testCorrections));
    });
  });
}
