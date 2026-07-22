import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/intro_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/onboarding/screens/onboarding_shell.dart';
import '../../features/discovery/screens/home_screen.dart';
import '../../features/scan/screens/camera_screen.dart';
import '../../features/scan/screens/result_screen.dart';
import '../../features/discovery/screens/search_screen.dart';
import '../../features/account/screens/profile_screen.dart';
import '../../features/account/screens/history_screen.dart';
import '../../features/account/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = Supabase.instance.client.auth.currentUser;
      final publicRoutes = ['/splash', '/intro', '/login', '/register'];
      final isPublic = publicRoutes.any((r) => state.matchedLocation.startsWith(r));

      if (user == null && !isPublic) return '/login';

      if (user != null) {
        // Skip check on splash screen (handled by splash timer)
        if (state.matchedLocation == '/splash') return null;

        final profileAsync = ref.read(currentProfileProvider);
        UserProfile? profile;
        if (profileAsync.hasValue && !profileAsync.isLoading) {
          profile = profileAsync.value;
        } else {
          profile = await ref.read(currentProfileProvider.future);
        }

        final isOnboarding = state.matchedLocation.startsWith('/onboarding');

        if (profile == null || !profile.onboardingComplete) {
          if (!isOnboarding) return '/onboarding';
        } else {
          if (isOnboarding || isPublic) return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/intro', builder: (_, __) => const IntroScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingShell()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/scan', builder: (_, __) => const CameraScreen()),
      GoRoute(
        path: '/result',
        builder: (_, state) => ResultScreen(extra: state.extra),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
