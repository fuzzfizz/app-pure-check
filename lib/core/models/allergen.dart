enum AllergenSeverity { mild, moderate, severe }
enum AllergenSource { known, suspected }

class Allergen {
  final String id;
  final String userId;
  final String ingredientName;
  final List<String> reactionSymptoms;
  final AllergenSeverity severity;
  final AllergenSource source;

  const Allergen({
    required this.id,
    required this.userId,
    required this.ingredientName,
    this.reactionSymptoms = const [],
    this.severity = AllergenSeverity.mild,
    this.source = AllergenSource.known,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) => Allergen(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        ingredientName: json['ingredient_name'] as String,
        reactionSymptoms: List<String>.from(json['reaction_symptoms'] ?? []),
        severity: AllergenSeverity.values.firstWhere(
          (e) => e.name == (json['severity'] ?? 'mild'),
          orElse: () => AllergenSeverity.mild,
        ),
        source: AllergenSource.values.firstWhere(
          (e) => e.name == (json['source'] ?? 'known'),
          orElse: () => AllergenSource.known,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'ingredient_name': ingredientName,
        'reaction_symptoms': reactionSymptoms,
        'severity': severity.name,
        'source': source.name,
      };
}
