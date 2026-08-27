import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService([SupabaseClient? client])
      : _client = client ?? _defaultClient();

  static SupabaseClient _defaultClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return SupabaseClient(
        'https://dummy.supabase.co',
        'dummy_anon_key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }
  }

  SupabaseClient get client => _client;

  // Username to Email lookup
  Future<String?> getEmailByUsername(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return null;

    try {
      // 1. Try RPC get_email_by_username
      final rpcRes = await _client.rpc('get_email_by_username', params: {
        'p_username': clean,
      });
      if (rpcRes != null && rpcRes is String && rpcRes.isNotEmpty) {
        return rpcRes;
      }
    } catch (_) {
      // Fallback if RPC is not deployed yet or in test/offline mode
    }

    try {
      // 2. Query profiles by username
      final res = await _client
          .from('profiles')
          .select('id')
          .ilike('username', clean)
          .maybeSingle();
      if (res != null && res['id'] != null) {
        return null;
      }
    } catch (_) {
      // Fallback
    }

    return null;
  }

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
    if (product.id.isEmpty) {
      data.remove('id');
    }
    if (product.barcode == null || product.barcode!.trim().isEmpty) {
      data.remove('barcode');
    }

    dynamic res;
    if (product.id.isNotEmpty) {
      res = await _client.from('products').upsert(data, onConflict: 'id').select().single();
    } else if (product.barcode != null && product.barcode!.trim().isNotEmpty) {
      res = await _client.from('products').upsert(data, onConflict: 'barcode').select().single();
    } else {
      res = await _client.from('products').insert(data).select().single();
    }
    return Product.fromJson(res);
  }

  Future<List<Product>> searchProducts(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final res = await _client
        .from('products')
        .select()
        .or('name.ilike.%$cleanQuery%,brand.ilike.%$cleanQuery%')
        .limit(20);
    return (res as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> getPendingProducts() async {
    final res = await _client
        .from('products')
        .select()
        .eq('status', 'pending');
    return (res as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<void> updateProductStatus(
    String productId,
    String status,
    bool isVerified,
  ) async {
    await _client.from('products').update({
      'status': status,
      'is_verified': isVerified,
    }).eq('id', productId);
  }

  // Scan history
  Future<void> addScanHistory({
    required String userId,
    required String productId,
    required AnalysisResult result,
  }) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'safety_level': result.overallSafety.name,
      'ai_analysis': result.toJson(),
    };
    if (productId.isNotEmpty) {
      data['product_id'] = productId;
    }
    await _client.from('scan_history').insert(data);
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

  // INCI Ingredients
  Future<void> addInciIngredient({
    required String name,
    String? category,
    String? descriptionTh,
  }) async {
    final data = <String, dynamic>{
      'name': name,
    };
    if (category != null && category.isNotEmpty) {
      data['category'] = category;
    }
    if (descriptionTh != null && descriptionTh.isNotEmpty) {
      data['description_th'] = descriptionTh;
    }

    try {
      await _client.from('inci_ingredients').upsert(data, onConflict: 'name');
    } catch (_) {
      // If table doesn't have category/description_th columns yet, fallback to inserting name
      try {
        await _client.from('inci_ingredients').upsert({'name': name}, onConflict: 'name');
      } catch (_) {
        // Catch silently if RLS or network issue
      }
    }
  }
}
