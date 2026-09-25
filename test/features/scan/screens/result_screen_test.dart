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

    testWidgets('renders English ingredient names with Thai descriptions when in Thai mode', (WidgetTester tester) async {
      const product = Product(
        id: 'p2',
        name: 'Pure Care Cream',
        brand: 'Pure Brand',
      );

      const analysis = AnalysisResult(
        overallSafety: SafetyLevel.caution,
        summaryTh: 'มีส่วนผสมที่ควรระวัง',
        summaryEn: 'Caution ingredients found',
        flaggedIngredients: [
          FlaggedIngredient(
            name: 'Alcohol Denat.',
            reason: 'แอลกอฮอล์เข้มข้น อาจทำให้ผิวแห้งตึง',
            reasonTh: 'แอลกอฮอล์เข้มข้น อาจทำให้ผิวแห้งตึง',
            reasonEn: 'High-concentration alcohol may cause dryness',
            riskLevel: SafetyLevel.caution,
          ),
        ],
        ingredientBreakdown: [
          IngredientBreakdown(
            name: 'Glycerin',
            function: 'สารกักเก็บความชุ่มชื้น',
            functionTh: 'สารกักเก็บความชุ่มชื้น',
            functionEn: 'Humectant',
            riskLevel: SafetyLevel.safe,
          ),
          IngredientBreakdown(
            name: 'Alcohol Denat.',
            function: 'ตัวทำละลาย / สมานกระชับผิว',
            functionTh: 'ตัวทำละลาย / สมานกระชับผิว',
            functionEn: 'Solvent / Astringent',
            riskLevel: SafetyLevel.caution,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('th'),
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

      // Ingredient names in English
      expect(find.text('Alcohol Denat.'), findsAtLeastNWidgets(1));
      expect(find.text('Glycerin'), findsOneWidget);

      // Descriptions in Thai
      expect(find.text('แอลกอฮอล์เข้มข้น อาจทำให้ผิวแห้งตึง'), findsOneWidget);
      expect(find.text('ตัวทำละลาย / สมานกระชับผิว'), findsOneWidget);
    });
  });
}
