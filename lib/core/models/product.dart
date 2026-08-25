enum ProductSource { local, openBeautyFacts, userEntered }

extension ProductSourceX on ProductSource {
  String get dbValue {
    switch (this) {
      case ProductSource.local:
        return 'local';
      case ProductSource.openBeautyFacts:
        return 'open_beauty_facts';
      case ProductSource.userEntered:
        return 'user_entered';
    }
  }

  static ProductSource fromDbValue(String value) {
    switch (value) {
      case 'local':
        return ProductSource.local;
      case 'open_beauty_facts':
        return ProductSource.openBeautyFacts;
      case 'user_entered':
        return ProductSource.userEntered;
      default:
        return ProductSource.local;
    }
  }
}

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
  final bool isVerified;
  final String status;
  final String? submittedBy;
  final int confidenceScore;
  final List<String> aiFlags;

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
    this.isVerified = false,
    this.status = 'approved',
    this.submittedBy,
    this.confidenceScore = 100,
    this.aiFlags = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String? ?? '',
        barcode: json['barcode'] as String?,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        ingredients: List<String>.from(json['ingredients'] ?? []),
        rawIngredientsText: json['raw_ingredients_text'] as String?,
        source: ProductSourceX.fromDbValue(json['source'] ?? 'local'),
        verifiedCount: json['verified_count'] as int? ?? 0,
        imageUrl: json['image_url'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        status: json['status'] as String? ?? 'approved',
        submittedBy: json['submitted_by'] as String?,
        confidenceScore: json['confidence_score'] as int? ?? 100,
        aiFlags: List<String>.from(json['ai_flags'] ?? []),
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
      isVerified: false,
      status: 'approved',
      confidenceScore: 100,
      aiFlags: const [],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'brand': brand,
      'ingredients': ingredients,
      'raw_ingredients_text': rawIngredientsText,
      'source': source.dbValue,
      'verified_count': verifiedCount,
      'image_url': imageUrl,
      'is_verified': isVerified,
      'status': status,
      'submitted_by': submittedBy,
      'confidence_score': confidenceScore,
      'ai_flags': aiFlags,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    if (barcode != null && barcode!.isNotEmpty) {
      map['barcode'] = barcode;
    }
    return map;
  }

  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    String? brand,
    List<String>? ingredients,
    String? rawIngredientsText,
    ProductSource? source,
    int? verifiedCount,
    String? imageUrl,
    bool? isVerified,
    String? status,
    String? submittedBy,
    int? confidenceScore,
    List<String>? aiFlags,
  }) =>
      Product(
        id: id ?? this.id,
        barcode: barcode ?? this.barcode,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        ingredients: ingredients ?? this.ingredients,
        rawIngredientsText: rawIngredientsText ?? this.rawIngredientsText,
        source: source ?? this.source,
        verifiedCount: verifiedCount ?? this.verifiedCount,
        imageUrl: imageUrl ?? this.imageUrl,
        isVerified: isVerified ?? this.isVerified,
        status: status ?? this.status,
        submittedBy: submittedBy ?? this.submittedBy,
        confidenceScore: confidenceScore ?? this.confidenceScore,
        aiFlags: aiFlags ?? this.aiFlags,
      );
}
