# Task 2 Report: Wire Up Localization & Language Toggle

## What Was Implemented
- Created `LocaleNotifier` and `localeProvider` in `lib/core/providers/locale_provider.dart` using `StateNotifier` and `SharedPreferences` to manage and persist app locale.
- Updated `lib/main.dart` to watch `localeProvider`, set `locale` in `MaterialApp.router`, and register `localizationsDelegates` (`AppLocalizations.delegate`, `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate`) and `supportedLocales` (`[Locale('th'), Locale('en')]`).
- Updated `lib/features/account/screens/settings_screen.dart` to bind the language `DropdownButton` value to `ref.watch(localeProvider).languageCode` and invoke `ref.read(localeProvider.notifier).setLocale(val)` on selection.

## What Was Tested & Test Results
- Created `test/core/providers/locale_provider_test.dart` to test:
  1. Default locale initialization (defaults to `th`).
  2. Loading saved locale from `SharedPreferences` on initialization (`en`).
  3. Setting new locale via `setLocale` updates Riverpod state and persists to `SharedPreferences`.
- Executed `flutter test`: Passed 4/4 tests cleanly.
- Executed `flutter analyze`: Passed with 0 issues/warnings.

## Files Changed
- `lib/core/providers/locale_provider.dart` (Created)
- `lib/main.dart` (Modified)
- `lib/features/account/screens/settings_screen.dart` (Modified)
- `test/core/providers/locale_provider_test.dart` (Created)

## Self-Review Findings
- Included `if (mounted)` check in `_initLocale()` to prevent state updates if the notifier is disposed before async `SharedPreferences` instance completes.
- Clean separation of core provider state and feature UI.

## Issues or Concerns
- None. Everything is passing cleanly.
