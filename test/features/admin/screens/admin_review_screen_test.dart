import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/core/models/product.dart';
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

  testWidgets('renders pending products initially with Pending AI badge and Start AI Analysis button', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Safe Cleanser'), findsOneWidget);
    expect(find.text('Medium Lotion'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);

    // Initial state: all pending AI
    expect(find.text('Pending AI'), findsNWidgets(3));
    expect(find.text('Start AI Analysis (3)'), findsOneWidget);
    expect(find.text('Safe (>= 80%): 0'), findsOneWidget);
  });

  testWidgets('Start AI Analysis button sequentially evaluates products and enables Auto-Approve', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final startAiButton = find.text('Start AI Analysis (3)');
    expect(startAiButton, findsOneWidget);

    await tester.tap(startAiButton);
    await tester.pumpAndSettle();

    // After evaluation completes:
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('(100%)'), findsOneWidget);
    expect(find.text('Yellow'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Red'), 100);
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Safe (>= 80%): 1'), findsOneWidget);
    expect(find.text('All Analyzed'), findsOneWidget);
    expect(find.text('สรุปเหตุผลคะแนน (100%):'), findsOneWidget);
    expect(find.text('ข้อมูลสมบูรณ์และผ่านเกณฑ์ความปลอดภัยทั้งหมด (100 คะแนนเต็ม)'), findsOneWidget);

    // Now test 1-Click Auto-Approve Safe Batch
    final batchButton = find.text('Auto-Approve Safe');
    expect(batchButton, findsOneWidget);

    await tester.tap(batchButton);
    await tester.pumpAndSettle();

    expect(fakeSupabase.updatedStatuses.length, equals(1));
    expect(fakeSupabase.updatedStatuses.first['productId'], equals('p-high'));
    expect(fakeSupabase.updatedStatuses.first['status'], equals('approved'));
    expect(fakeSupabase.updatedStatuses.first['isVerified'], isTrue);

    expect(find.text('Safe Cleanser'), findsNothing);
    expect(find.text('Medium Lotion'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
  });

  testWidgets('Analyze button on individual card evaluates only that product', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final analyzeButtons = find.widgetWithText(OutlinedButton, 'Analyze');
    expect(analyzeButtons, findsNWidgets(3));

    // Tap first analyze button (Safe Cleanser)
    await tester.tap(analyzeButtons.first);
    await tester.pumpAndSettle();

    // First product is now Green (100%), other products remain Pending AI
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Pending AI'), findsAtLeastNWidgets(1));
    expect(find.text('Start AI Analysis (2)'), findsOneWidget);
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

  testWidgets('tapping View Details for analyzed product opens detail modal with full breakdown and allows approve', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // First run AI analysis
    await tester.tap(find.text('Start AI Analysis (3)'));
    await tester.pumpAndSettle();

    final viewDetailsButtons = find.widgetWithText(TextButton, 'View Details');
    expect(viewDetailsButtons, findsAtLeastNWidgets(1));

    // Tap first view details button (Safe Cleanser)
    await tester.tap(viewDetailsButtons.first);
    await tester.pumpAndSettle();

    // Verify modal content
    expect(find.text('Product Details & AI Moderation'), findsOneWidget);
    expect(find.text('AI Evaluation Criteria Breakdown:'), findsOneWidget);
    expect(find.text('Product Name Length'), findsOneWidget);
    expect(find.text('Brand Information'), findsOneWidget);
    expect(find.text('Spam Detection'), findsOneWidget);
    expect(find.text('INCI Recognition Rate'), findsOneWidget);

    // Tap Approve inside modal
    final modalApproveButton = find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.widgetWithText(ElevatedButton, 'Approve'),
    );
    expect(modalApproveButton, findsOneWidget);

    await tester.tap(modalApproveButton);
    await tester.pumpAndSettle();

    // Verify product is approved and modal is dismissed
    expect(find.text('Product Details & AI Moderation'), findsNothing);
    expect(fakeSupabase.updatedStatuses.last['productId'], equals('p-high'));
    expect(fakeSupabase.updatedStatuses.last['status'], equals('approved'));
  });

  testWidgets('tapping View Details for medium confidence product shows unrecognized ingredients and allows reject', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // First run AI analysis
    await tester.tap(find.text('Start AI Analysis (3)'));
    await tester.pumpAndSettle();

    // Find card for Medium Lotion
    final lotionCard = find.text('Medium Lotion');
    expect(lotionCard, findsOneWidget);

    await tester.tap(lotionCard);
    await tester.pumpAndSettle();

    // Verify modal opened
    expect(find.text('Product Details & AI Moderation'), findsOneWidget);
    final modalScrollable = find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byType(Scrollable),
    );
    final unrecognizedFinder = find.text('1 unrecognized');
    await tester.scrollUntilVisible(unrecognizedFinder, 100, scrollable: modalScrollable);
    expect(unrecognizedFinder, findsOneWidget);

    final unknownIngrFinder = find.text('UnknownIngr');
    await tester.scrollUntilVisible(unknownIngrFinder, 100, scrollable: modalScrollable);
    expect(unknownIngrFinder, findsOneWidget);

    // Tap Reject inside modal
    final modalRejectButton = find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.widgetWithText(OutlinedButton, 'Reject'),
    );
    expect(modalRejectButton, findsOneWidget);

    await tester.tap(modalRejectButton);
    await tester.pumpAndSettle();

    // Verify product is rejected and modal is dismissed
    expect(find.text('Product Details & AI Moderation'), findsNothing);
    expect(fakeSupabase.updatedStatuses.last['productId'], equals('p-med'));
    expect(fakeSupabase.updatedStatuses.last['status'], equals('rejected'));
  });
}


