import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Profile
  Future<UserProfile?> getProfile(String userId) async {
    final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (res == null) return null;
    return UserProfile.fromJson(res);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await _client.from('profiles').upsert(profile.toJson());
  }

  // Allergens
  Future<List<Allergen>> getAllergens(String userId) async {
    final res = await _client.from('user_allergens').select().eq('user_id', userId);
    return (res as List).map((e) => Allergen.fromJson(e)).toList();
  }

  Future<void> addAllergen(Allergen allergen) async {
    final data = allergen.toJson();
    data.remove('id'); // let DB generate
    await _client.from('user_allergens').insert(data);
  }

  Future<void> deleteAllergen(String id) async {
    await _client.from('user_allergens').delete().eq('id', id);
  }

  // Products
  Future<Product?> getProductByBarcode(String barcode) async {
    final res = await _client.from('products').select().eq('barcode', barcode).maybeSingle();
    if (res == null) return null;
    return Product.fromJson(res);
  }

  Future<Product> upsertProduct(Product product) async {
    final data = product.toJson();
    final res = await _client.from('products').upsert(data, onConflict: 'barcode').select().single();
    return Product.fromJson(res);
  }

  Future<List<Product>> searchProducts(String query) async {
    final res = await _client
        .from('products')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    return (res as List).map((e) => Product.fromJson(e)).toList();
  }

  // Scan history
  Future<void> addScanHistory({
    required String userId,
    required String productId,
    required AnalysisResult result,
  }) async {
    await _client.from('scan_history').insert({
      'user_id': userId,
      'product_id': productId,
      'safety_level': result.overallSafety.name,
      'ai_analysis': result.toJson(),
    });
  }

  Future<List<Map<String, dynamic>>> getScanHistory(String userId) async {
    final res = await _client
        .from('scan_history')
        .select('*, products(*)')
        .eq('user_id', userId)
        .order('scanned_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  }
}
