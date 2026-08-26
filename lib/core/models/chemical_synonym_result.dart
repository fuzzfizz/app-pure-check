class ChemicalSynonymResult {
  final String rawInput;
  final bool isValidSynonym;
  final String? canonicalInciName;
  final String reason;

  const ChemicalSynonymResult({
    required this.rawInput,
    required this.isValidSynonym,
    this.canonicalInciName,
    required this.reason,
  });

  factory ChemicalSynonymResult.fromJson(Map<String, dynamic> json) {
    return ChemicalSynonymResult(
      rawInput: json['raw_input'] as String? ?? json['rawInput'] as String? ?? '',
      isValidSynonym: json['is_valid_synonym'] as bool? ?? json['isValidSynonym'] as bool? ?? false,
      canonicalInciName: json['canonical_inci_name'] as String? ?? json['canonicalInciName'] as String?,
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raw_input': rawInput,
      'is_valid_synonym': isValidSynonym,
      'canonical_inci_name': canonicalInciName,
      'reason': reason,
    };
  }

  @override
  String toString() => 'ChemicalSynonymResult(raw: $rawInput, valid: $isValidSynonym, canonical: $canonicalInciName)';
}
