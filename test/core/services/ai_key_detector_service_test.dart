import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pure_check/core/models/user_api_key.dart';
import 'package:pure_check/core/services/ai_key_detector_service.dart';

void main() {
  group('AiKeyDetectorService Unit Tests', () {
    late AiKeyDetectorService service;

    setUp(() {
      service = AiKeyDetectorService();
    });

    test('detectProvider correctly recognizes Google Gemini key prefix', () {
      final detected = service.detectProvider('AIzaSyD-1234567890abcdef');
      expect(detected.provider, equals('gemini'));
      expect(detected.providerName, equals('Google Gemini'));
      expect(detected.defaultModel, equals('gemini-1.5-flash'));
    });

    test('detectProvider correctly recognizes Groq key prefix', () {
      final detected = service.detectProvider('gsk_abcdef1234567890');
      expect(detected.provider, equals('groq'));
      expect(detected.providerName, equals('Groq Cloud'));
      expect(detected.defaultModel, equals('llama-3.3-70b-versatile'));
    });

    test('detectProvider correctly recognizes Cerebras key prefix', () {
      final detected = service.detectProvider('csk-abcdef1234567890');
      expect(detected.provider, equals('cerebras'));
      expect(detected.providerName, equals('Cerebras Cloud'));
      expect(detected.defaultModel, equals('llama-3.3-70b'));
    });

    test('detectProvider correctly recognizes OpenRouter key prefix', () {
      final detected1 = service.detectProvider('sk-or-v1-abcdef1234567890');
      expect(detected1.provider, equals('openrouter'));
      expect(detected1.providerName, equals('OpenRouter'));

      final detected2 = service.detectProvider('sk-or-abcdef1234567890');
      expect(detected2.provider, equals('openrouter'));
    });

    test('detectProvider correctly recognizes GitHub Models key prefix', () {
      final detected1 = service.detectProvider('ghp_abcdef1234567890');
      expect(detected1.provider, equals('github'));
      expect(detected1.providerName, equals('GitHub Models'));

      final detected2 = service.detectProvider('github_pat_abcdef1234567890');
      expect(detected2.provider, equals('github'));
    });

    test('detectProvider correctly recognizes DeepSeek key prefix', () {
      final detected = service.detectProvider('sk-12345678901234567890123456789012');
      expect(detected.provider, equals('deepseek'));
      expect(detected.providerName, equals('DeepSeek'));
      expect(detected.defaultModel, equals('deepseek-chat'));
    });

    test('testKeyQuota returns KeyStatus.valid on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"candidates":[{"content":{"parts":[{"text":"pong"}]}}]}', 200);
      });

      final testService = AiKeyDetectorService(client: mockClient);
      final info = testService.detectProvider('AIzaSyValidKey');
      final result = await testService.testKeyQuota('AIzaSyValidKey', info);

      expect(result.status, equals(KeyStatus.valid));
      expect(result.message, contains('พร้อมใช้งาน'));
    });

    test('testKeyQuota returns KeyStatus.quotaExceeded on HTTP 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"code": 429, "message": "RESOURCE_EXHAUSTED"}}', 429);
      });

      final testService = AiKeyDetectorService(client: mockClient);
      final info = testService.detectProvider('gsk_RateLimitedKey');
      final result = await testService.testKeyQuota('gsk_RateLimitedKey', info);

      expect(result.status, equals(KeyStatus.quotaExceeded));
      expect(result.message, contains('โควต้า'));
    });

    test('testKeyQuota returns KeyStatus.invalid on HTTP 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Unauthorized"}', 401);
      });

      final testService = AiKeyDetectorService(client: mockClient);
      final info = testService.detectProvider('AIzaSyInvalidKey');
      final result = await testService.testKeyQuota('AIzaSyInvalidKey', info);

      expect(result.status, equals(KeyStatus.invalid));
      expect(result.message, contains('ไม่ถูกต้อง'));
    });
  });
}
