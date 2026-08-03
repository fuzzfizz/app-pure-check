import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/models/analysis_result.dart';
import 'package:pure_check/features/scan/screens/result_screen.dart';

void main() {
  group('ResultScreen Health Disclaimer Tests', () {
    testWidgets('renders health disclaimer card with Key health_disclaimer_card containing l10n.healthDisclaimer', (WidgetTester tester) async {
      const product = Product(
        id: 'p1',
        name: 'Test Product',
        brand: 'Test Brand',
        verifiedCount: 1,
      );

      const analysis = AnalysisResult(
        overallSafety: SafetyLevel.safe,
        summaryTh: 'ปลอดภัย',
        summaryEn: 'Safe',
        flaggedIngredients: [],
        ingredientBreakdown: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ResultScreen(
              extra: {
                'product': product,
                'analysis': analysis,
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final disclaimerCardFinder = find.byKey(const Key('health_disclaimer_card'));
      expect(disclaimerCardFinder, findsOneWidget);

      final BuildContext context = tester.element(find.byType(ResultScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(
        find.descendant(
          of: disclaimerCardFinder,
          matching: find.text(l10n.healthDisclaimer),
        ),
        findsOneWidget,
      );
    });
  });
}
