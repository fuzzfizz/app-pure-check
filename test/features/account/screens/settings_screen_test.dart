import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/account/screens/settings_screen.dart';

void main() {
  Widget buildWidget({required UserProfile? profile}) {
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => profile),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('displays Admin Product Review tile when profile.isAdmin is true', (WidgetTester tester) async {
    const adminProfile = UserProfile(
      id: 'admin-1',
      skinType: SkinType.normal,
      role: 'admin',
    );

    await tester.pumpWidget(buildWidget(profile: adminProfile));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Admin Product Review'), 200);
    expect(find.text('Admin Product Review'), findsOneWidget);
  });

  testWidgets('hides Admin Product Review tile when profile.isAdmin is false', (WidgetTester tester) async {
    const userProfile = UserProfile(
      id: 'user-1',
      skinType: SkinType.normal,
      role: 'user',
    );

    await tester.pumpWidget(buildWidget(profile: userProfile));
    await tester.pumpAndSettle();

    expect(find.text('Admin Product Review'), findsNothing);
  });

  testWidgets('renders custom AI key manager section with 0 / 3 counter and add button', (WidgetTester tester) async {
    const userProfile = UserProfile(
      id: 'user-1',
      skinType: SkinType.normal,
      role: 'user',
    );

    await tester.pumpWidget(buildWidget(profile: userProfile));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 / 3'), findsOneWidget);
    expect(find.text('เพิ่ม AI API Key'), findsOneWidget);
  });
}
