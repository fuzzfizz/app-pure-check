import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/features/auth/widgets/password_requirements_view.dart';

void main() {
  Widget buildTestWidget(String password) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th'), Locale('en')],
      locale: const Locale('th'),
      home: Scaffold(
        body: PasswordRequirementsView(password: password),
      ),
    );
  }

  group('PasswordRequirementsView Widget Tests', () {
    testWidgets('renders all 5 requirement items', (tester) async {
      await tester.pumpWidget(buildTestWidget(''));
      await tester.pumpAndSettle();

      expect(find.text('ความยาวอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
      expect(find.text('มีตัวอักษรพิมพ์ใหญ่ (A-Z)'), findsOneWidget);
      expect(find.text('มีตัวอักษรพิมพ์เล็ก (a-z)'), findsOneWidget);
      expect(find.text('มีตัวเลข (0-9)'), findsOneWidget);
      expect(find.text(r'มีอักขระพิเศษ (เช่น !@#$%)'), findsOneWidget);
    });

    testWidgets('shows green check icon when requirement is met', (tester) async {
      await tester.pumpWidget(buildTestWidget('SecureP@ss1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(5));
    });
  });
}
