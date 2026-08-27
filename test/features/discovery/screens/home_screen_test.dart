import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/features/account/providers/profile_provider.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/discovery/screens/home_screen.dart';

void main() {
  Widget buildTestWidget({UserProfile? profile}) {
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => profile),
        scanHistoryProvider.overrideWith((ref) async => []),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('th'), Locale('en')],
        locale: Locale('th'),
        home: HomeScreen(),
      ),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('displays personalized greeting with username when profile has username', (tester) async {
      final profile = UserProfile(
        id: 'u1',
        username: 'beauty_expert',
        skinType: SkinType.oily,
      );

      await tester.pumpWidget(buildTestWidget(profile: profile));
      await tester.pumpAndSettle();

      expect(find.text('สวัสดีคุณ beauty_expert 👋'), findsOneWidget);
      expect(find.text('PureCheck'), findsOneWidget);
    });

    testWidgets('displays default greeting with User when profile has no username', (tester) async {
      final profile = UserProfile(
        id: 'u2',
        username: null,
        skinType: SkinType.sensitive,
      );

      await tester.pumpWidget(buildTestWidget(profile: profile));
      await tester.pumpAndSettle();

      expect(find.text('สวัสดีคุณ User 👋'), findsOneWidget);
    });
  });
}
