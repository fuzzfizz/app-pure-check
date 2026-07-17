enum SkinType { oily, dry, combination, normal, sensitive }

extension SkinTypeX on SkinType {
  String get labelTh {
    switch (this) {
      case SkinType.oily: return 'มัน';
      case SkinType.dry: return 'แห้ง';
      case SkinType.combination: return 'ผสม';
      case SkinType.normal: return 'ธรรมดา';
      case SkinType.sensitive: return 'แพ้ง่าย';
    }
  }
  String get value => name;
  static SkinType fromString(String s) =>
      SkinType.values.firstWhere((e) => e.name == s, orElse: () => SkinType.normal);
}

class UserProfile {
  final String id;
  final SkinType skinType;
  final List<String> skinConditions;
  final List<String> skinConcerns;
  final List<String> avoidPreferences;
  final bool onboardingComplete;

  const UserProfile({
    required this.id,
    required this.skinType,
    this.skinConditions = const [],
    this.skinConcerns = const [],
    this.avoidPreferences = const [],
    this.onboardingComplete = false,
  });

  factory UserProfile.empty(String id) => UserProfile(
        id: id,
        skinType: SkinType.normal,
        onboardingComplete: false,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        skinType: SkinTypeX.fromString(json['skin_type'] as String? ?? 'normal'),
        skinConditions: List<String>.from(json['skin_conditions'] ?? []),
        skinConcerns: List<String>.from(json['skin_concerns'] ?? []),
        avoidPreferences: List<String>.from(json['avoid_preferences'] ?? []),
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'skin_type': skinType.value,
        'skin_conditions': skinConditions,
        'skin_concerns': skinConcerns,
        'avoid_preferences': avoidPreferences,
        'onboarding_complete': onboardingComplete,
      };

  UserProfile copyWith({
    SkinType? skinType,
    List<String>? skinConditions,
    List<String>? skinConcerns,
    List<String>? avoidPreferences,
    bool? onboardingComplete,
  }) => UserProfile(
        id: id,
        skinType: skinType ?? this.skinType,
        skinConditions: skinConditions ?? this.skinConditions,
        skinConcerns: skinConcerns ?? this.skinConcerns,
        avoidPreferences: avoidPreferences ?? this.avoidPreferences,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );
}
