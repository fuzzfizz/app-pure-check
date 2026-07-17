import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/allergen.dart';
import '../../auth/providers/auth_provider.dart';

final userAllergensProvider = FutureProvider.autoDispose<List<Allergen>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.read(supabaseServiceProvider);
  return service.getAllergens(user.id);
});

final scanHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.read(supabaseServiceProvider);
  return service.getScanHistory(user.id);
});

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.upsertProfile(profile);
      ref.invalidate(currentProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAllergen(String name) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');
      final service = ref.read(supabaseServiceProvider);
      final allergen = Allergen(
        id: '',
        userId: user.id,
        ingredientName: name,
        severity: AllergenSeverity.moderate,
        reactionSymptoms: ['แดง', 'คัน'],
        source: AllergenSource.known,
      );
      await service.addAllergen(allergen);
      ref.invalidate(userAllergensProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeAllergen(String allergenId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.deleteAllergen(allergenId);
      ref.invalidate(userAllergensProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier(ref);
});
