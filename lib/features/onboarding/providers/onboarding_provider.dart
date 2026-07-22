import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/allergen.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingState {
  final SkinType skinType;
  final List<String> skinConditions;
  final List<Allergen> allergens;
  final List<String> skinConcerns;
  final List<String> avoidPreferences;
  final bool loading;
  final String? error;

  OnboardingState({
    this.skinType = SkinType.normal,
    this.skinConditions = const [],
    this.allergens = const [],
    this.skinConcerns = const [],
    this.avoidPreferences = const [],
    this.loading = false,
    this.error,
  });

  OnboardingState copyWith({
    SkinType? skinType,
    List<String>? skinConditions,
    List<Allergen>? allergens,
    List<String>? skinConcerns,
    List<String>? avoidPreferences,
    bool? loading,
    String? error,
  }) {
    return OnboardingState(
      skinType: skinType ?? this.skinType,
      skinConditions: skinConditions ?? this.skinConditions,
      allergens: allergens ?? this.allergens,
      skinConcerns: skinConcerns ?? this.skinConcerns,
      avoidPreferences: avoidPreferences ?? this.avoidPreferences,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref ref;
  OnboardingNotifier(this.ref) : super(OnboardingState());

  void setSkinType(SkinType type) {
    state = state.copyWith(skinType: type);
  }

  void toggleSkinCondition(String condition) {
    final list = List<String>.from(state.skinConditions);
    if (list.contains(condition)) {
      list.remove(condition);
    } else {
      list.add(condition);
    }
    state = state.copyWith(skinConditions: list);
  }

  void addAllergen(Allergen allergen) {
    state = state.copyWith(allergens: [...state.allergens, allergen]);
  }

  void removeAllergen(String name) {
    state = state.copyWith(
      allergens: state.allergens.where((a) => a.ingredientName != name).toList(),
    );
  }

  void toggleSkinConcern(String concern) {
    final list = List<String>.from(state.skinConcerns);
    if (list.contains(concern)) {
      list.remove(concern);
    } else {
      list.add(concern);
    }
    state = state.copyWith(skinConcerns: list);
  }

  void toggleAvoidPreference(String preference) {
    final list = List<String>.from(state.avoidPreferences);
    if (list.contains(preference)) {
      list.remove(preference);
    } else {
      list.add(preference);
    }
    state = state.copyWith(avoidPreferences: list);
  }

  Future<bool> completeOnboarding() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final supabaseService = ref.read(supabaseServiceProvider);

      // Create profile
      final profile = UserProfile(
        id: user.id,
        skinType: state.skinType,
        skinConditions: state.skinConditions,
        skinConcerns: state.skinConcerns,
        avoidPreferences: state.avoidPreferences,
        onboardingComplete: true,
      );

      // Save profile
      await supabaseService.upsertProfile(profile);
      ref.invalidate(currentProfileProvider);

      // Save allergens
      for (final allergen in state.allergens) {
        await supabaseService.addAllergen(allergen);
      }

      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});
