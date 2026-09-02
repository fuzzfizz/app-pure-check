import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/core/services/inci_search_service.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/scan/screens/manual_entry_screen.dart';
import 'package:pure_check/features/scan/widgets/typo_correction_dialog.dart';

class FakeInciSearchService implements InciSearchService {
  late final dynamic supabaseService;

  final List<String> Function(String query)? onSearch;
  final List<String> Function(List<String> ingredients)? onFilter;

  FakeInciSearchService({this.onSearch, this.onFilter});

  @override
  Future<List<String>> searchIngredients(String query, {int limit = 5}) async {
    if (onSearch != null) return onSearch!(query);
    return [];
  }

  @override
  Future<List<String>> filterUnrecognizedIngredients(List<String> ingredients) async {
    if (onFilter != null) return onFilter!(ingredients);
    return [];
  }
}

class FakeSupabaseService extends SupabaseService {
  final Map<String, String> Function(List<String> unknown)? onCheckTypos;

  FakeSupabaseService({this.onCheckTypos});

  @override
  Future<Map<String, String>> checkIngredientTypos(List<String> unknownIngredients) async {
    if (onCheckTypos != null) return onCheckTypos!(unknownIngredients);
    return {};
  }
}

void main() {
  testWidgets('ManualEntryScreen renders input fields and submit button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inciSearchServiceProvider.overrideWithValue(FakeInciSearchService()),
          supabaseServiceProvider.overrideWithValue(FakeSupabaseService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ManualEntryScreen(
            barcode: '123456',
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('ManualEntryScreen debounces and shows suggestions on typing in ingredients field', (WidgetTester tester) async {
    final fakeInci = FakeInciSearchService(
      onSearch: (query) => ['Niacinamide'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inciSearchServiceProvider.overrideWithValue(fakeInci),
          supabaseServiceProvider.overrideWithValue(FakeSupabaseService()),
        ],
        child: MaterialApp(
          locale: const Locale('th'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ManualEntryScreen(
            barcode: '123456',
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(3));

    // Type in ingredients textfield
    await tester.enterText(textFields.at(2), 'Niac');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('คำแนะนำส่วนผสมมาตรฐาน (INCI):'), findsOneWidget);
    final suggestionChip = find.descendant(
      of: find.byType(ActionChip),
      matching: find.textContaining('Niacinamide'),
    );
    expect(suggestionChip, findsOneWidget);

    await tester.ensureVisible(suggestionChip);
    await tester.tap(suggestionChip, warnIfMissed: false);
    await tester.pump();

    final TextField textField = tester.widget(textFields.at(2));
    expect(textField.controller?.text, contains('Niacinamide'));
  });

  testWidgets('ManualEntryScreen submits and shows TypoCorrectionDialog when unrecognized ingredients are found', (WidgetTester tester) async {
    final fakeInci = FakeInciSearchService(
      onFilter: (ingredients) => ['Niacinmid'],
    );
    final fakeSupabase = FakeSupabaseService(
      onCheckTypos: (unknown) => {'Niacinmid': 'Niacinamide'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inciSearchServiceProvider.overrideWithValue(fakeInci),
          supabaseServiceProvider.overrideWithValue(fakeSupabase),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ManualEntryScreen(
            barcode: '123456',
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Test Product');
    await tester.enterText(textFields.at(2), 'Niacinmid');

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TypoCorrectionDialog), findsOneWidget);
    expect(find.text('Niacinamide'), findsOneWidget);
  });

  testWidgets('ManualEntryScreen renders English suggestions and helper text when in English locale', (WidgetTester tester) async {
    final fakeInci = FakeInciSearchService(
      onSearch: (query) => ['Glycerin'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inciSearchServiceProvider.overrideWithValue(fakeInci),
          supabaseServiceProvider.overrideWithValue(FakeSupabaseService()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ManualEntryScreen(
            barcode: '123456',
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(2), 'Gly');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('Standard INCI Suggestions:'), findsOneWidget);
    expect(find.text('Detected 1 ingredients'), findsOneWidget);
  });
}
