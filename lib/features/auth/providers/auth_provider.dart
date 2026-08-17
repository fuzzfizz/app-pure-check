import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

enum AuthStatus { loading, unauthenticated, needsOnboarding, authenticated }

class AuthStateData {
  final AuthStatus status;
  final User? user;
  final UserProfile? profile;

  const AuthStateData({
    required this.status,
    this.user,
    this.profile,
  });
}

User? _getSafeCurrentUser() {
  try {
    return Supabase.instance.client.auth.currentUser;
  } catch (_) {
    return null;
  }
}

class AuthNotifier extends StateNotifier<AuthStateData> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthStateData(status: AuthStatus.loading)) {
    _init();
  }

  void _init() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final user = data.session?.user ?? _getSafeCurrentUser();
        _onUserChanged(user);
      });

      final initialUser = _getSafeCurrentUser();
      _onUserChanged(initialUser);
    } catch (_) {
      // In unit test environment without Supabase initialization
    }
  }

  Future<void> _onUserChanged(User? user) async {
    if (user == null) {
      state = const AuthStateData(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final service = _ref.read(supabaseServiceProvider);
      final profile = await service.getProfile(user.id) ?? UserProfile.empty(user.id);

      if (!profile.onboardingComplete) {
        state = AuthStateData(
          status: AuthStatus.needsOnboarding,
          user: user,
          profile: profile,
        );
      } else {
        state = AuthStateData(
          status: AuthStatus.authenticated,
          user: user,
          profile: profile,
        );
      }
    } catch (_) {
      final existingProfile = state.profile ?? UserProfile.empty(user.id);
      state = AuthStateData(
        status: existingProfile.onboardingComplete
            ? AuthStatus.authenticated
            : AuthStatus.needsOnboarding,
        user: user,
        profile: existingProfile,
      );
    }
  }

  Future<void> refreshProfile() async {
    final user = _getSafeCurrentUser() ?? state.user;
    if (user != null) {
      await _onUserChanged(user);
    } else {
      state = const AuthStateData(status: AuthStatus.unauthenticated);
    }
  }

  void setUserAndProfile(User? user, UserProfile? profile) {
    if (user == null) {
      state = const AuthStateData(status: AuthStatus.unauthenticated);
      return;
    }
    final p = profile ?? UserProfile.empty(user.id);
    state = AuthStateData(
      status: p.onboardingComplete ? AuthStatus.authenticated : AuthStatus.needsOnboarding,
      user: user,
      profile: p,
    );
  }

  void updateProfile(UserProfile profile) {
    final currentUser = state.user ?? _getSafeCurrentUser();
    if (currentUser != null) {
      state = AuthStateData(
        status: profile.onboardingComplete ? AuthStatus.authenticated : AuthStatus.needsOnboarding,
        user: currentUser,
        profile: profile,
      );
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  return AuthNotifier(ref);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  try {
    return Supabase.instance.client.auth.onAuthStateChange;
  } catch (_) {
    return const Stream.empty();
  }
});

final currentUserProvider = Provider<User?>((ref) {
  final authData = ref.watch(authNotifierProvider);
  return authData.user ?? _getSafeCurrentUser();
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authData = ref.watch(authNotifierProvider);
  if (authData.profile != null) return authData.profile;
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.read(supabaseServiceProvider);
  final profile = await service.getProfile(user.id);
  return profile ?? UserProfile.empty(user.id);
});

