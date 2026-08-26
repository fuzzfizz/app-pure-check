import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/discovery/screens/search_screen.dart';

class FakeSupabaseSearchService extends SupabaseService {
  final List<Product> mockProducts;

  FakeSupabaseSearchService({required this.mockProducts});

  @override
  Future<List<Product>> searchProducts(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];
    return mockProducts.where((p) {
      final matchesName = p.name.toLowerCase().contains(clean);
      final matchesBrand = p.brand?.toLowerCase().contains(clean) ?? false;
      return matchesName || matchesBrand;
    }).toList();
  }
}

void main() {
  final testProducts = [
    const Product(
      id: 'p1',
      name: 'Hydrating Facial Cleanser',
      brand: 'CeraVe',
      ingredients: ['Water', 'Glycerin', 'Ceramide NP', 'Hyaluronic Acid'],
    ),
    const Product(
      id: 'p2',
      name: 'Niacinamide 10% + Zinc 1%',
      brand: 'The Ordinary',
      ingredients: ['Aqua / Water / Eau', 'Niacinamide', 'Zinc PCA'],
    ),
  ];

  Widget buildTestWidget(SupabaseService fakeService) {
    return ProviderScope(
      overrides: [
        supabaseServiceProvider.overrideWithValue(fakeService),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SearchScreen(),
      ),
    );
  }

  testWidgets('SearchScreen finds products by Brand Name on the Products tab', (WidgetTester tester) async {
    final fakeService = FakeSupabaseSearchService(mockProducts: testProducts);
    await tester.pumpWidget(buildTestWidget(fakeService));
    await tester.pumpAndSettle();

    // Type Brand name "CeraVe" into search field
    final searchInput = find.byType(TextField);
    expect(searchInput, findsOneWidget);
    await tester.enterText(searchInput, 'CeraVe');
    await tester.pumpAndSettle();

    // Verify CeraVe product appears in the list
    expect(find.text('Hydrating Facial Cleanser'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'CeraVe'), findsOneWidget);
    expect(find.text('The Ordinary'), findsNothing);
  });

  testWidgets('SearchScreen finds products by Product Name on the Products tab', (WidgetTester tester) async {
    final fakeService = FakeSupabaseSearchService(mockProducts: testProducts);
    await tester.pumpWidget(buildTestWidget(fakeService));
    await tester.pumpAndSettle();

    // Type Product name "Niacinamide" into search field
    final searchInput = find.byType(TextField);
    await tester.enterText(searchInput, 'Niacinamide');
    await tester.pumpAndSettle();

    // Verify The Ordinary product appears
    expect(find.text('Niacinamide 10% + Zinc 1%'), findsOneWidget);
    expect(find.text('The Ordinary'), findsOneWidget);
  });

  testWidgets('SearchScreen displays matching INCI ingredients on Ingredients tab', (WidgetTester tester) async {
    final fakeService = FakeSupabaseSearchService(mockProducts: testProducts);
    await tester.pumpWidget(buildTestWidget(fakeService));
    await tester.pumpAndSettle();

    final searchInput = find.byType(TextField);
    await tester.enterText(searchInput, 'Hyaluronic');
    await tester.pumpAndSettle();

    // Switch to Ingredients tab
    await tester.tap(find.text('Ingredients'));
    await tester.pumpAndSettle();

    // Verify Hyaluronic Acid appears in ingredient results
    expect(find.text('Hyaluronic Acid'), findsWidgets);
  });
}
