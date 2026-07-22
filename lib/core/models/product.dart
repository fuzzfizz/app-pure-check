enum ProductSource { local, openBeautyFacts, userEntered }

class Product {
  final String id;
  final String? barcode;
  final String name;
  final String? brand;
  final List<String> ingredients;
  final String? rawIngredientsText;
  final ProductSource source;
  final int verifiedCount;
  final String? imageUrl;

  const Product({
    required this.id,
    this.barcode,
    required this.name,
    this.brand,
    this.ingredients = const [],
    this.rawIngredientsText,
    this.source = ProductSource.local,
    this.verifiedCount = 0,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        barcode: json['barcode'] as String?,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        ingredients: List<String>.from(json['ingredients'] ?? []),
        rawIngredientsText: json['raw_ingredients_text'] as String?,
        source: ProductSource.values.firstWhere(
          (e) => e.name == (json['source'] ?? 'local'),
          orElse: () => ProductSource.local,
        ),
        verifiedCount: json['verified_count'] as int? ?? 0,
        imageUrl: json['image_url'] as String?,
      );

  factory Product.fromOpenBeautyFacts(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final ingredientsText = product['ingredients_text'] as String? ?? '';
    final ingredients = ingredientsText
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return Product(
      id: '',
      barcode: product['code'] as String? ?? json['code'] as String?,
      name: product['product_name'] as String? ?? 'Unknown Product',
      brand: product['brands'] as String?,
      ingredients: ingredients,
      rawIngredientsText: ingredientsText,
      source: ProductSource.openBeautyFacts,
      imageUrl: product['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'ingredients': ingredients,
        'raw_ingredients_text': rawIngredientsText,
        'source': source.name,
        'verified_count': verifiedCount,
        'image_url': imageUrl,
      };

  Product copyWith({String? id, List<String>? ingredients, String? name, String? brand}) =>
      Product(
        id: id ?? this.id,
        barcode: barcode,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        ingredients: ingredients ?? this.ingredients,
        rawIngredientsText: rawIngredientsText,
        source: source,
        verifiedCount: verifiedCount,
        imageUrl: imageUrl,
      );
}
