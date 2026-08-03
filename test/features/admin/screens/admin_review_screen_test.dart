import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/core/models/product.dart';
import 'package:pure_check/core/services/admin_moderation_service.dart';
import 'package:pure_check/core/services/inci_search_service.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/admin/screens/admin_review_screen.dart';

class FakeSupabaseService extends SupabaseService {
  List<Product> pendingProducts;
  final List<Map<String, dynamic>> updatedStatuses = [];

  FakeSupabaseService({this.pendingProducts = const []});

  @override
  Future<List<Product>> getPendingProducts() async {
    return List.from(pendingProducts);
  }

  @override
  Future<void> updateProductStatus(
    String productId,
    String status,
    bool isVerified,
  ) async {
    updatedStatuses.add({
      'productId': productId,
      'status': status,
      'isVerified': isVerified,
    });
  }
}

class FakeInciSearchService implements InciSearchService {
  @override
  Future<List<String>> searchIngredients(String query, {int limit = 5}) async => [];

  @override
  Future<List<String>> filterUnrecognizedIngredients(List<String> ingredients) async {
    final unrecognized = <String>[];
    for (final ing in ingredients) {
      if (ing.contains('Unknown') || ing.contains('http')) {
        unrecognized.add(ing);
      }
    }
    return unrecognized;
  }
}

void main() {
  late FakeSupabaseService fakeSupabase;
  late FakeInciSearchService fakeInci;

  final highConfProduct = const Product(
    id: 'p-high',
    name: 'Safe Cleanser',
    brand: 'Pure Brand',
    ingredients: ['Water', 'Glycerin'],
    status: 'pending',
  );

  final medConfProduct = const Product(
    id: 'p-med',
    name: 'Medium Lotion',
    brand: null, // missing brand (-15)
    ingredients: ['Water', 'Glycerin', 'Niacinamide', 'UnknownIngr'], // 75% recognized rate (-20) => Score: 65 (Yellow)
    status: 'pending',
  );

  final lowConfProduct = const Product(
    id: 'p-low',
    name: 'X', // short name (-30), missing brand (-15), spam (-40)
    brand: null,
    ingredients: ['http://spam.com'],
    status: 'pending',
  );

  setUp(() {
    fakeSupabase = FakeSupabaseService(
      pendingProducts: [highConfProduct, medConfProduct, lowConfProduct],
    );
    fakeInci = FakeInciSearchService();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        supabaseServiceProvider.overrideWithValue(fakeSupabase),
        inciSearchServiceProvider.overrideWithValue(fakeInci),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminReviewScreen(),
      ),
    );
  }

  testWidgets('renders pending products with traffic light badges', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Safe Cleanser'), findsOneWidget);
    expect(find.text('Medium Lotion'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);

    // Traffic light badge check
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Yellow'), findsOneWidget);
    expect(find.text('Red'), findsOneWidget);
  });

  testWidgets('1-Click Auto-Approve Safe Batch approves high confidence products', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final batchButton = find.text('1-Click Auto-Approve Safe Batch');
    expect(batchButton, findsOneWidget);

    await tester.tap(batchButton);
    await tester.pumpAndSettle();

    // High confidence product should be approved and removed from pending list
    expect(fakeSupabase.updatedStatuses.length, equals(1));
    expect(fakeSupabase.updatedStatuses.first['productId'], equals('p-high'));
    expect(fakeSupabase.updatedStatuses.first['status'], equals('approved'));
    expect(fakeSupabase.updatedStatuses.first['isVerified'], isTrue);

    expect(find.text('Safe Cleanser'), findsNothing);
    expect(find.text('Medium Lotion'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
  });

  testWidgets('Approve action button approves individual product', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final approveButtons = find.widgetWithText(ElevatedButton, 'Approve');
    expect(approveButtons, findsAtLeastNWidgets(1));

    await tester.tap(approveButtons.first);
    await tester.pumpAndSettle();

    expect(fakeSupabase.updatedStatuses, isNotEmpty);
    expect(fakeSupabase.updatedStatuses.last['status'], equals('approved'));
    expect(fakeSupabase.updatedStatuses.last['isVerified'], isTrue);
  });

  testWidgets('Reject action button rejects individual product', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final rejectButtons = find.widgetWithText(OutlinedButton, 'Reject');
    expect(rejectButtons, findsAtLeastNWidgets(1));

    await tester.tap(rejectButtons.first);
    await tester.pumpAndSettle();

    expect(fakeSupabase.updatedStatuses, isNotEmpty);
    expect(fakeSupabase.updatedStatuses.last['status'], equals('rejected'));
    expect(fakeSupabase.updatedStatuses.last['isVerified'], isFalse);
  });
}
