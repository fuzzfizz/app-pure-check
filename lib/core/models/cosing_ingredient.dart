class CosIngIngredient {
  final String name;
  final bool isValidInci;
  final String? cosingId;
  final String category;
  final String descriptionTh;
  final int confidenceScore;

  const CosIngIngredient({
    required this.name,
    required this.isValidInci,
    this.cosingId,
    required this.category,
    required this.descriptionTh,
    this.confidenceScore = 100,
  });

  factory CosIngIngredient.fromJson(Map<String, dynamic> json) {
    return CosIngIngredient(
      name: json['name'] as String? ?? '',
      isValidInci: json['isValidInci'] as bool? ?? json['is_valid_inci'] as bool? ?? false,
      cosingId: json['cosingId'] as String? ?? json['cosing_id'] as String?,
      category: json['category'] as String? ?? 'General / Other',
      descriptionTh: json['descriptionTh'] as String? ?? json['description_th'] as String? ?? '',
      confidenceScore: json['confidenceScore'] as int? ?? json['confidence_score'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isValidInci': isValidInci,
      'cosingId': cosingId,
      'category': category,
      'descriptionTh': descriptionTh,
      'confidenceScore': confidenceScore,
    };
  }

  @override
  String toString() => 'CosIngIngredient(name: $name, isValid: $isValidInci, category: $category)';
}
