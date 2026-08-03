import '../../../../core/models/product.dart';
import '../../../../core/models/analysis_result.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/allergen.dart';

abstract class ScanRepository {
  Future<Product?> fetchProductByBarcode(String barcode);
  Future<Product> upsertProduct(Product product);
  Future<AnalysisResult> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  });
  Future<void> saveScanHistory({
    required String userId,
    required String productId,
    required AnalysisResult result,
  });
}
