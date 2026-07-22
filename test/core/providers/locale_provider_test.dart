import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_check/core/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state defaults to Thai (th)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale, const Locale('th'));
    });

    test('initial state loads saved locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'selected_locale': 'en',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger provider initialization
      container.read(localeProvider);
      // Wait for async SharedPreferences.getInstance() and state update
      await pumpEventQueue();

      final locale = container.read(localeProvider);
      expect(locale, const Locale('en'));
    });

    test('setLocale updates state and persists in SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale('en');

      expect(container.read(localeProvider), const Locale('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_locale'), 'en');
    });
  });
}
