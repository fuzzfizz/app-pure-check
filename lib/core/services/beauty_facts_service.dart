import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class BeautyFactsService {
  static const _baseUrl = 'https://world.openbeautyfacts.org/api/v2/product';

  Future<Product?> fetchByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 1) return null;
      return Product.fromOpenBeautyFacts(json);
    } catch (_) {
      return null;
    }
  }
}
