enum KeyStatus { valid, quotaExceeded, invalid, checking, unknown }

class UserApiKey {
  final String id;
  final String key;
  final String provider; // 'gemini', 'groq', 'cerebras', 'openrouter', 'deepseek', 'github', 'custom'
  final String providerName; // e.g. 'Google Gemini', 'Groq Cloud'
  final String defaultModel;
  final KeyStatus status;
  final String? statusMessage;
  final bool isEnabled;
  final DateTime lastChecked;

  const UserApiKey({
    required this.id,
    required this.key,
    required this.provider,
    required this.providerName,
    required this.defaultModel,
    this.status = KeyStatus.unknown,
    this.statusMessage,
    this.isEnabled = true,
    required this.lastChecked,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'provider': provider,
    'providerName': providerName,
    'defaultModel': defaultModel,
    'status': status.name,
    'statusMessage': statusMessage,
    'isEnabled': isEnabled,
    'lastChecked': lastChecked.toIso8601String(),
  };

  factory UserApiKey.fromJson(Map<String, dynamic> json) => UserApiKey(
    id: json['id'] as String,
    key: json['key'] as String,
    provider: json['provider'] as String? ?? 'custom',
    providerName: json['providerName'] as String? ?? 'Custom AI',
    defaultModel: json['defaultModel'] as String? ?? 'default',
    status: KeyStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => KeyStatus.unknown,
    ),
    statusMessage: json['statusMessage'] as String?,
    isEnabled: json['isEnabled'] as bool? ?? true,
    lastChecked: DateTime.tryParse(json['lastChecked'] as String? ?? '') ?? DateTime.now(),
  );

  UserApiKey copyWith({
    String? id,
    String? key,
    String? provider,
    String? providerName,
    String? defaultModel,
    KeyStatus? status,
    String? statusMessage,
    bool? isEnabled,
    DateTime? lastChecked,
  }) {
    return UserApiKey(
      id: id ?? this.id,
      key: key ?? this.key,
      provider: provider ?? this.provider,
      providerName: providerName ?? this.providerName,
      defaultModel: defaultModel ?? this.defaultModel,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      isEnabled: isEnabled ?? this.isEnabled,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  String get maskedKey {
    if (key.length <= 8) return '****';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }
}
