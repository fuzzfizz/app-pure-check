import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_check/core/providers/user_api_keys_provider.dart';
import 'package:pure_check/core/services/ai_key_detector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserApiKeysNotifier Unit Tests', () {
    late UserApiKeysNotifier notifier;
    late AiKeyDetectorService detector;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((request) async {
        return http.Response('{"status":"ok"}', 200);
      });
      detector = AiKeyDetectorService(client: mockClient);
      notifier = UserApiKeysNotifier(detector);
    });

    test('initial state is empty and canAddMore is true', () {
      expect(notifier.state, isEmpty);
      expect(notifier.canAddMore, isTrue);
    });

    test('enforces maximum 3 keys limit strictly', () async {
      final res1 = await notifier.addKey('AIzaSyKey11111111111111111111111111111');
      expect(res1, isTrue);
      expect(notifier.state.length, equals(1));
      expect(notifier.canAddMore, isTrue);

      final res2 = await notifier.addKey('gsk_Key2222222222222222222222222222222');
      expect(res2, isTrue);
      expect(notifier.state.length, equals(2));
      expect(notifier.canAddMore, isTrue);

      final res3 = await notifier.addKey('csk-Key3333333333333333333333333333333');
      expect(res3, isTrue);
      expect(notifier.state.length, equals(3));
      expect(notifier.canAddMore, isFalse);

      // Attempting to add a 4th key should be rejected
      final res4 = await notifier.addKey('AIzaSyKey44444444444444444444444444444');
      expect(res4, isFalse);
      expect(notifier.state.length, equals(3));
    });

    test('removeKey removes the target key and restores canAddMore to true', () async {
      await notifier.addKey('AIzaSyKey1');
      await notifier.addKey('AIzaSyKey2');
      await notifier.addKey('AIzaSyKey3');
      expect(notifier.state.length, equals(3));
      expect(notifier.canAddMore, isFalse);

      final idToRemove = notifier.state.first.id;
      await notifier.removeKey(idToRemove);

      expect(notifier.state.length, equals(2));
      expect(notifier.canAddMore, isTrue);
      expect(notifier.state.any((k) => k.id == idToRemove), isFalse);
    });

    test('toggleKey toggles isEnabled state', () async {
      await notifier.addKey('AIzaSyKey1');
      final id = notifier.state.first.id;
      expect(notifier.state.first.isEnabled, isTrue);

      await notifier.toggleKey(id, false);
      expect(notifier.state.first.isEnabled, isFalse);
      expect(notifier.activeKeys, isEmpty);

      await notifier.toggleKey(id, true);
      expect(notifier.state.first.isEnabled, isTrue);
      expect(notifier.activeKeys.length, equals(1));
    });
  });
}
