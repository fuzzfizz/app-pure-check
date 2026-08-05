import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../../features/admin/screens/admin_review_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<AuthStateData>(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

String? appRedirect(dynamic ref, BuildContext context, GoRouterState state) {
  AuthStateData authData;
  if (ref is WidgetRef) {
    authData = ref.read(authNotifierProvider);
  } else if (ref is Ref) {
    authData = ref.read(authNotifierProvider);
  } else if (ref is ProviderContainer) {
    authData = ref.read(authNotifierProvider);
  } else {
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {}
    if (user == null) {
      authData = const AuthStateData(status: AuthStatus.unauthenticated);
    } else {
      authData = const AuthStateData(status: AuthStatus.loading);
    }
  }

  final publicRoutes = ['/splash', '/intro', '/login', '/register'];
  final isPublic = publicRoutes.any((r) => state.matchedLocation.startsWith(r));
  final isOnboarding = state.matchedLocation.startsWith('/onboarding');
  final isAdminRoute = state.matchedLocation.startsWith('/admin');

  switch (authData.status) {
    case AuthStatus.loading:
      if (state.matchedLocation == '/splash') return null;
      return null;

    case AuthStatus.unauthenticated:
      if (isPublic) return null;
      return '/login';

    case AuthStatus.needsOnboarding:
      if (isOnboarding) return null;
      return '/onboarding';

    case AuthStatus.authenticated:
      final profile = authData.profile;
      if (isAdminRoute && (profile == null || !profile.isAdmin)) {
        return '/home';
      }
      if (isOnboarding || isPublic) {
        return '/home';
      }
      return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) => appRedirect(ref, context, state),
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
      GoRoute(path: '/admin/review', builder: (_, __) => const AdminReviewScreen()),
    ],
  );
});
