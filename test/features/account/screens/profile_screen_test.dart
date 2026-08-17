import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/core/models/allergen.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/account/providers/profile_provider.dart';
import 'package:pure_check/features/account/screens/profile_screen.dart';

class FakeSupabaseService extends Fake implements SupabaseService {
  UserProfile savedProfile;
  List<Allergen> savedAllergens;
  bool shouldThrowError;

  FakeSupabaseService({
    required this.savedProfile,
    required this.savedAllergens,
    this.shouldThrowError = false,
  });

  @override
  Future<UserProfile?> getProfile(String userId) async {
    if (shouldThrowError) throw Exception('Network error');
    return savedProfile;
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    if (shouldThrowError) throw Exception('Failed to upsert profile');
    savedProfile = profile;
  }

  @override
  Future<List<Allergen>> getAllergens(String userId) async {
    if (shouldThrowError) throw Exception('Failed to get allergens');
    return savedAllergens;
  }

  @override
  Future<void> addAllergen(Allergen allergen) async {
    if (shouldThrowError) throw Exception('Failed to add allergen');
    savedAllergens = [
      ...savedAllergens,
      Allergen(
        id: 'new-id-${savedAllergens.length + 1}',
        userId: allergen.userId,
        ingredientName: allergen.ingredientName,
        severity: allergen.severity,
        reactionSymptoms: allergen.reactionSymptoms,
        source: allergen.source,
      ),
    ];
  }

  @override
  Future<void> deleteAllergen(String id) async {
    if (shouldThrowError) throw Exception('Failed to delete allergen');
    savedAllergens = savedAllergens.where((a) => a.id != id).toList();
  }
}

void main() {
  final mockUser = User(
    id: 'user-123',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  );

  const initialProfile = UserProfile(
    id: 'user-123',
    skinType: SkinType.oily,
    skinConditions: ['acne_prone'],
    skinConcerns: ['acne'],
    onboardingComplete: true,
    role: 'user',
  );

  testWidgets('ProfileScreen saves changes and keeps updated values displayed', (WidgetTester tester) async {
    final fakeService = FakeSupabaseService(
      savedProfile: initialProfile,
      savedAllergens: [],
    );

    final container = ProviderContainer(
      overrides: [
        supabaseServiceProvider.overrideWithValue(fakeService),
        currentUserProvider.overrideWithValue(mockUser),
      ],
    );
    container.read(authNotifierProvider.notifier).setUserAndProfile(mockUser, initialProfile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('th'),
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial values shown
    expect(find.text('มัน'), findsOneWidget); // Oily in Thai

    // Select skin type dropdown and change to 'แห้ง' (Dry)
    await tester.tap(find.text('มัน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แห้ง').last);
    await tester.pumpAndSettle();

    // Verify change is reflected in draft
    expect(find.text('แห้ง'), findsOneWidget);

    // Tap Save button
    await tester.tap(find.text('บันทึกข้อมูลโปรไฟล์ผิว'));
    await tester.pumpAndSettle();

    // Verify DB was updated
    expect(fakeService.savedProfile.skinType, equals(SkinType.dry));

    // Verify UI still displays 'แห้ง' (Dry) and NOT reset to 'มัน' (Oily)
    expect(find.text('แห้ง'), findsOneWidget);
    expect(find.text('มัน'), findsNothing);
  });

  testWidgets('ProfileScreen saves allergens and keeps them displayed', (WidgetTester tester) async {
    final fakeService = FakeSupabaseService(
      savedProfile: initialProfile,
      savedAllergens: [],
    );

    final container = ProviderContainer(
      overrides: [
        supabaseServiceProvider.overrideWithValue(fakeService),
        currentUserProvider.overrideWithValue(mockUser),
      ],
    );
    container.read(authNotifierProvider.notifier).setUserAndProfile(mockUser, initialProfile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('th'),
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Add an allergen
    await tester.scrollUntilVisible(find.byIcon(Icons.add_circle_outline), 200);
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Paraben');
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();

    expect(find.text('Paraben (ใหม่)'), findsOneWidget);

    // Tap Save button
    await tester.tap(find.text('บันทึกข้อมูลโปรไฟล์ผิว'));
    await tester.pumpAndSettle();

    // Verify DB has allergen
    expect(fakeService.savedAllergens.any((a) => a.ingredientName == 'Paraben'), isTrue);

    // Verify UI displays 'Paraben' (without (ใหม่))
    expect(find.text('Paraben'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows error snackbar when save fails and does not reset draft', (WidgetTester tester) async {
    final fakeService = FakeSupabaseService(
      savedProfile: initialProfile,
      savedAllergens: [],
      shouldThrowError: false,
    );

    final container = ProviderContainer(
      overrides: [
        supabaseServiceProvider.overrideWithValue(fakeService),
        currentUserProvider.overrideWithValue(mockUser),
      ],
    );
    container.read(authNotifierProvider.notifier).setUserAndProfile(mockUser, initialProfile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('th'),
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Change to 'แห้ง'
    await tester.tap(find.text('มัน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แห้ง').last);
    await tester.pumpAndSettle();

    // Set error before save
    fakeService.shouldThrowError = true;

    // Tap Save button
    await tester.tap(find.text('บันทึกข้อมูลโปรไฟล์ผิว'));
    await tester.pumpAndSettle();

    // Verify error snackbar is displayed
    expect(find.textContaining('เกิดข้อผิดพลาดในการบันทึก'), findsOneWidget);

    // Draft edit should remain 'แห้ง'
    expect(find.text('แห้ง'), findsOneWidget);
  });
}
