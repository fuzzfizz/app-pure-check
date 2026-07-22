import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/models/analysis_result.dart';
import 'package:pure_check/features/scan/screens/result_screen.dart';

void main() {
  group('Product model verification tests', () {
    test('toJson includes verified_count', () {
      const product = Product(
        id: 'p1',
        name: 'Test Product',
        verifiedCount: 5,
      );

      final json = product.toJson();
      expect(json['verified_count'], equals(5));
    });
  });

  group('ResultScreen community contribution button tests', () {
    testWidgets('renders community contribution button on result screen', (WidgetTester tester) async {
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
            home: ResultScreen(
              extra: {
                'product': product,
                'analysis': analysis,
              },
            ),
          ),
        ),
      );

      expect(find.text('ช่วยชุมชน: ยืนยันส่งข้อมูล'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
    });
  });
}
