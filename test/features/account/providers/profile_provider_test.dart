import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/account/providers/profile_provider.dart';

class FakeSupabaseService extends Fake implements SupabaseService {
  UserProfile? savedProfile;

  @override
  Future<UserProfile?> getProfile(String userId) async {
    return savedProfile;
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    savedProfile = profile;
  }
}

void main() {
  group('ProfileNotifier updateProfile tests', () {
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

    test('updateProfile updates authNotifierProvider and currentProfileProvider with the new profile data', () async {
      final fakeService = FakeSupabaseService();
      fakeService.savedProfile = initialProfile;

      final container = ProviderContainer(
        overrides: [
          supabaseServiceProvider.overrideWithValue(fakeService),
          currentUserProvider.overrideWithValue(mockUser),
        ],
      );
      addTearDown(container.dispose);

      // Set initial user and profile in AuthNotifier
      container.read(authNotifierProvider.notifier).setUserAndProfile(mockUser, initialProfile);

      // Verify currentProfileProvider initial value
      final initialAsync = await container.read(currentProfileProvider.future);
      expect(initialAsync?.skinType, equals(SkinType.oily));
      expect(initialAsync?.skinConditions, contains('acne_prone'));

      // Prepare updated profile
      const updatedProfile = UserProfile(
        id: 'user-123',
        skinType: SkinType.dry,
        skinConditions: ['eczema'],
        skinConcerns: ['wrinkles'],
        onboardingComplete: true,
        role: 'user',
      );

      // Perform update via ProfileNotifier
      await container.read(profileNotifierProvider.notifier).updateProfile(updatedProfile);

      // Verify DB was updated
      expect(fakeService.savedProfile?.skinType, equals(SkinType.dry));
      expect(fakeService.savedProfile?.skinConditions, contains('eczema'));

      // Verify AuthNotifier state has the updated profile
      final authState = container.read(authNotifierProvider);
      expect(authState.profile?.skinType, equals(SkinType.dry));
      expect(authState.profile?.skinConditions, contains('eczema'));
      expect(authState.profile?.skinConcerns, contains('wrinkles'));

      // Verify currentProfileProvider returns the updated profile
      final currentProfile = await container.read(currentProfileProvider.future);
      expect(currentProfile?.skinType, equals(SkinType.dry));
      expect(currentProfile?.skinConditions, contains('eczema'));
      expect(currentProfile?.skinConcerns, contains('wrinkles'));
    });
  });
}
