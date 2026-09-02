import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_api_key.dart';

class DetectedProviderInfo {
  final String provider;
  final String providerName;
  final String defaultModel;

  const DetectedProviderInfo({
    required this.provider,
    required this.providerName,
    required this.defaultModel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedProviderInfo &&
          runtimeType == other.runtimeType &&
          provider == other.provider;

  @override
  int get hashCode => provider.hashCode;
}

class KeyValidationResult {
  final KeyStatus status;
  final String message;

  const KeyValidationResult({required this.status, required this.message});
}

class AiKeyDetectorService {
  final http.Client _client;

  AiKeyDetectorService({http.Client? client}) : _client = client ?? http.Client();

  static const List<DetectedProviderInfo> supportedProviders = [
    DetectedProviderInfo(
      provider: 'gemini',
      providerName: 'Google Gemini',
      defaultModel: 'gemini-flash-latest',
    ),
    DetectedProviderInfo(
      provider: 'groq',
      providerName: 'Groq Cloud',
      defaultModel: 'openai/gpt-oss-120b',
    ),
    DetectedProviderInfo(
      provider: 'cerebras',
      providerName: 'Cerebras Cloud',
      defaultModel: 'gpt-oss-120b',
    ),
    DetectedProviderInfo(
      provider: 'openrouter',
      providerName: 'OpenRouter',
      defaultModel: 'meta-llama/llama-3.3-70b-instruct:free',
    ),
    DetectedProviderInfo(
      provider: 'deepseek',
      providerName: 'DeepSeek',
      defaultModel: 'deepseek-chat',
    ),
    DetectedProviderInfo(
      provider: 'github',
      providerName: 'GitHub Models',
      defaultModel: 'gpt-4o-mini',
    ),
  ];

  /// Auto-detect AI provider based on key prefix
  DetectedProviderInfo detectProvider(String rawKey) {
    final clean = rawKey.trim();

    if (clean.startsWith('AIzaSy')) {
      return supportedProviders.firstWhere((p) => p.provider == 'gemini');
    } else if (clean.startsWith('gsk_')) {
      return supportedProviders.firstWhere((p) => p.provider == 'groq');
    } else if (clean.startsWith('csk-')) {
      return supportedProviders.firstWhere((p) => p.provider == 'cerebras');
    } else if (clean.startsWith('sk-or-v1-') || clean.startsWith('sk-or-')) {
      return supportedProviders.firstWhere((p) => p.provider == 'openrouter');
    } else if (clean.startsWith('ghp_') || clean.startsWith('github_pat_')) {
      return supportedProviders.firstWhere((p) => p.provider == 'github');
    } else if (clean.startsWith('sk-') && clean.length >= 30) {
      return supportedProviders.firstWhere((p) => p.provider == 'deepseek');
    }

    return const DetectedProviderInfo(
      provider: 'custom',
      providerName: 'Custom (OpenAI-compatible)',
      defaultModel: 'default',
    );
  }

  /// Probe key to verify validity and available tokens/quota
  Future<KeyValidationResult> testKeyQuota(String key, DetectedProviderInfo info) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      return const KeyValidationResult(
        status: KeyStatus.invalid,
        message: 'กรุณากรอก API Key ก่อนทดสอบ',
      );
    }

    try {
      if (info.provider == 'gemini') {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/${info.defaultModel}:generateContent?key=$cleanKey',
        );
        final res = await _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': 'ping'}
                ]
              }
            ],
            'generationConfig': {'maxOutputTokens': 1}
          }),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          return KeyValidationResult(
            status: KeyStatus.valid,
            message: 'คีย์ถูกต้อง มีโควต้าพร้อมใช้งาน (Model: ${info.defaultModel})',
          );
        } else if (res.statusCode == 429) {
          return const KeyValidationResult(
            status: KeyStatus.quotaExceeded,
            message: 'คีย์ถูกต้อง แต่โควต้าเต็มชั่วคราว (Rate Limited 429)',
          );
        } else {
          return KeyValidationResult(
            status: KeyStatus.invalid,
            message: 'คีย์ไม่ถูกต้องหรือไม่มีสิทธิ์ (HTTP ${res.statusCode})',
          );
        }
      } else {
        // OpenAI Compatible endpoints
        String endpoint = 'https://api.groq.com/openai/v1/chat/completions';
        if (info.provider == 'cerebras') {
          endpoint = 'https://api.cerebras.ai/v1/chat/completions';
        } else if (info.provider == 'openrouter') {
          endpoint = 'https://openrouter.ai/api/v1/chat/completions';
        } else if (info.provider == 'deepseek') {
          endpoint = 'https://api.deepseek.com/chat/completions';
        } else if (info.provider == 'github') {
          endpoint = 'https://models.github.ai/inference/chat/completions';
        }

        final res = await _client.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $cleanKey',
          },
          body: jsonEncode({
            'model': info.defaultModel,
            'messages': [
              {'role': 'user', 'content': 'hi'}
            ],
            'max_tokens': 1,
          }),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          return KeyValidationResult(
            status: KeyStatus.valid,
            message: 'คีย์ถูกต้อง มีโควต้าพร้อมใช้งาน (Model: ${info.defaultModel})',
          );
        } else if (res.statusCode == 429) {
          return const KeyValidationResult(
            status: KeyStatus.quotaExceeded,
            message: 'คีย์ถูกต้อง แต่โควต้าเต็ม (Rate Limited 429)',
          );
        } else {
          return KeyValidationResult(
            status: KeyStatus.invalid,
            message: 'คีย์ไม่ถูกต้อง (HTTP ${res.statusCode})',
          );
        }
      }
    } catch (e) {
      return KeyValidationResult(
        status: KeyStatus.unknown,
        message: 'ไม่สามารถทดสอบโควต้าได้: $e',
      );
    }
  }
}
