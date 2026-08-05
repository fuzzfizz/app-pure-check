import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/core/router/app_router.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  group('app_router admin route authorization tests', () {
    final mockUser = User(
      id: 'test-user-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    );

    test('Non-admin user profile (role: "user", isAdmin == false) accessing /admin routes is redirected to /home', () async {
      final nonAdminProfile = UserProfile.empty('test-user-id').copyWith(
        onboardingComplete: true,
        role: 'user',
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          currentProfileProvider.overrideWith((ref) async => nonAdminProfile),
        ],
      );
      container.read(authNotifierProvider.notifier).setUserAndProfile(mockUser, nonAdminProfile);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/admin/review'),
        matchedLocation: '/admin/review',
        fullPath: '/admin/review',
        pathParameters: const {},
        pageKey: const ValueKey('/admin/review'),
      );

      final redirectResult = appRedirect(
        container,
        FakeBuildContext(),
        state,
      );

      expect(redirectResult, equals('/home'));
    });

    test('Admin user profile (role: "admin", isAdmin == true) accessing /admin routes is allowed', () async {
      final adminProfile = UserProfile.empty('test-user-id').copyWith(
        onboardingComplete: true,
        role: 'admin',
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          currentProfileProvider.overrideWith((ref) async => adminProfile),
        ],
      );
      container.read(authNotifierProvider.notifier).setUserAndProfile(mockUser, adminProfile);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/admin/review'),
        matchedLocation: '/admin/review',
        fullPath: '/admin/review',
        pathParameters: const {},
        pageKey: const ValueKey('/admin/review'),
      );

      final redirectResult = appRedirect(
        container,
        FakeBuildContext(),
        state,
      );

      expect(redirectResult, isNull);
    });

    test('User with incomplete onboarding accessing /onboarding is allowed', () async {
      final unonboardedProfile = UserProfile.empty('test-user-id').copyWith(
        onboardingComplete: false,
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          currentProfileProvider.overrideWith((ref) async => unonboardedProfile),
        ],
      );
      container.read(authNotifierProvider.notifier).setUserAndProfile(mockUser, unonboardedProfile);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/onboarding'),
        matchedLocation: '/onboarding',
        fullPath: '/onboarding',
        pathParameters: const {},
        pageKey: const ValueKey('/onboarding'),
      );

      final redirectResult = appRedirect(
        container,
        FakeBuildContext(),
        state,
      );

      expect(redirectResult, isNull);
    });

    test('Unauthenticated user accessing /onboarding is redirected to /login', () async {
      final container = ProviderContainer();
      container.read(authNotifierProvider.notifier).setUserAndProfile(null, null);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/onboarding'),
        matchedLocation: '/onboarding',
        fullPath: '/onboarding',
        pathParameters: const {},
        pageKey: const ValueKey('/onboarding'),
      );

      final redirectResult = appRedirect(
        container,
        FakeBuildContext(),
        state,
      );

      expect(redirectResult, equals('/login'));
    });
  });
}

