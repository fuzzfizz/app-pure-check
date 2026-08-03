import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

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

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SkinType.oily: return l10n.skinOily;
      case SkinType.dry: return l10n.skinDry;
      case SkinType.combination: return l10n.skinCombination;
      case SkinType.normal: return l10n.skinNormal;
      case SkinType.sensitive: return l10n.skinSensitive;
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
  final String role;

  bool get isAdmin => role == 'admin';

  const UserProfile({
    required this.id,
    required this.skinType,
    this.skinConditions = const [],
    this.skinConcerns = const [],
    this.avoidPreferences = const [],
    this.onboardingComplete = false,
    this.role = 'user',
  });

  factory UserProfile.empty(String id) => UserProfile(
        id: id,
        skinType: SkinType.normal,
        onboardingComplete: false,
        role: 'user',
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        skinType: SkinTypeX.fromString(json['skin_type'] as String? ?? 'normal'),
        skinConditions: List<String>.from(json['skin_conditions'] ?? []),
        skinConcerns: List<String>.from(json['skin_concerns'] ?? []),
        avoidPreferences: List<String>.from(json['avoid_preferences'] ?? []),
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
        role: json['role'] as String? ?? 'user',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'skin_type': skinType.value,
        'skin_conditions': skinConditions,
        'skin_concerns': skinConcerns,
        'avoid_preferences': avoidPreferences,
        'onboarding_complete': onboardingComplete,
        'role': role,
      };

  UserProfile copyWith({
    SkinType? skinType,
    List<String>? skinConditions,
    List<String>? skinConcerns,
    List<String>? avoidPreferences,
    bool? onboardingComplete,
    String? role,
  }) => UserProfile(
        id: id,
        skinType: skinType ?? this.skinType,
        skinConditions: skinConditions ?? this.skinConditions,
        skinConcerns: skinConcerns ?? this.skinConcerns,
        avoidPreferences: avoidPreferences ?? this.avoidPreferences,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        role: role ?? this.role,
      );
}
