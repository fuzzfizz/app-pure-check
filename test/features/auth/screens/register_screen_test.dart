import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/features/auth/screens/register_screen.dart';
import 'package:pure_check/features/auth/widgets/password_requirements_view.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('th'), Locale('en')],
        locale: Locale('th'),
        home: RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders username, email, password, confirm password, and PasswordRequirementsView checklist', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.byType(PasswordRequirementsView), findsOneWidget);
      expect(find.text('ชื่อผู้ใช้'), findsOneWidget);
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsWidgets);
      expect(find.text('ยืนยันรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('updates PasswordRequirementsView checklist dynamically as user types password', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially no requirements met (or empty)
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(2), 'SecureP@ss1');
      await tester.pumpAndSettle();

      // All 5 requirements should be checked
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(5));
    });

    testWidgets('shows validation error when username is invalid', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'ab'); // Invalid username (< 3 chars)
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'SecureP@ss1');
      await tester.enterText(textFields.at(3), 'SecureP@ss1');

      final button = find.byType(ElevatedButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.textContaining('3-20'), findsOneWidget);
    });

    testWidgets('shows validation error when password does not meet security requirements', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'validuser');
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'weakpass'); // Missing uppercase, number, special char
      await tester.enterText(textFields.at(3), 'weakpass');

      final button = find.byType(ElevatedButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านไม่ตรงตามเงื่อนไขความปลอดภัย'), findsOneWidget);
    });

    testWidgets('shows validation error when passwords do not match', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'validuser');
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'SecureP@ss1');
      await tester.enterText(textFields.at(3), 'DifferentP@ss2');

      final button = find.byType(ElevatedButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    });

    testWidgets('toggles password and confirm password visibility independently', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      TextField passField = tester.widget<TextField>(textFields.at(2));
      TextField confirmField = tester.widget<TextField>(textFields.at(3));

      expect(passField.obscureText, isTrue);
      expect(confirmField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));

      // Tap first toggle button (password)
      final toggles = find.byIcon(Icons.visibility_off);
      await tester.tap(toggles.first);
      await tester.pumpAndSettle();

      passField = tester.widget<TextField>(textFields.at(2));
      confirmField = tester.widget<TextField>(textFields.at(3));
      expect(passField.obscureText, isFalse);
      expect(confirmField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap second toggle button (confirm password)
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      passField = tester.widget<TextField>(textFields.at(2));
      confirmField = tester.widget<TextField>(textFields.at(3));
      expect(passField.obscureText, isFalse);
      expect(confirmField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });
  });
}
