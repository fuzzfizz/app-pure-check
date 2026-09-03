# Admin Duplicate Product Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Detect duplicate products in the database during AI moderation analysis in the Admin Review Screen, deduct confidence score to prevent auto-approval, and display warning indicators to the administrator.

**Architecture:** `SupabaseService.findDuplicateProduct` queries the Supabase `products` table for existing approved products matching barcode or name + brand (excluding the current product). `AdminModerationService.evaluateProduct` calls this method, deducts 50 points, assigns the `duplicate_product` flag, and attaches duplicate product information to `ModerationEvaluation`. `AdminReviewScreen` presents a prominent warning banner on product cards and comparison details in the modal sheet.

**Tech Stack:** Flutter, Riverpod, Supabase Flutter Client (`supabase_flutter`), Flutter Test.

## Global Constraints
- Only compare against approved products (`status == 'approved'`) in the `products` table.
- Exclude the product being reviewed from the query (`id != product.id`).
- Deduct 50 points for duplicates so the confidence score is strictly < 80% (preventing auto-approval).
- Handle network/query errors gracefully without crashing or blocking AI analysis.
- Maintain documentation integrity and follow clean code conventions.

---

### Task 1: Duplicate Detection Query in `SupabaseService`

**Files:**
- Modify: `app_pure_check/lib/core/services/supabase_service.dart`
- Test: `app_pure_check/test/core/services/supabase_service_test.dart`

**Interfaces:**
- Produces: `DuplicateMatchResult` class and `findDuplicateProduct(Product product)` method in `SupabaseService`.
- Consumes: `Product` from `app_pure_check/lib/core/models/product.dart`.

- [ ] **Step 1: Write unit tests for `findDuplicateProduct` in `supabase_service_test.dart`**

Add tests for `findDuplicateProduct` verifying barcode match and name + brand match:
```dart
    test('DuplicateMatchResult stores existingProduct and reason', () {
      const existing = Product(id: 'p-exist', name: 'Existing Product', brand: 'Brand A');
      const result = DuplicateMatchResult(
        existingProduct: existing,
        reason: 'บาร์โค้ดตรงกับสินค้าในระบบ (1234567890123)',
      );
      expect(result.existingProduct.id, equals('p-exist'));
      expect(result.reason, contains('บาร์โค้ดตรงกับสินค้าในระบบ'));
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/supabase_service_test.dart`
Expected: FAIL with "Undefined name 'DuplicateMatchResult'".

- [ ] **Step 3: Implement `DuplicateMatchResult` and `findDuplicateProduct` in `supabase_service.dart`**

In `app_pure_check/lib/core/services/supabase_service.dart`:
```dart
class DuplicateMatchResult {
  final Product existingProduct;
  final String reason;

  const DuplicateMatchResult({
    required this.existingProduct,
    required this.reason,
  });
}
```

Add `findDuplicateProduct` to `SupabaseService`:
```dart
  Future<DuplicateMatchResult?> findDuplicateProduct(Product product) async {
    try {
      // 1. Check duplicate by barcode if provided
      final cleanBarcode = product.barcode?.trim();
      if (cleanBarcode != null && cleanBarcode.isNotEmpty) {
        var query = _client
            .from('products')
            .select()
            .eq('barcode', cleanBarcode)
            .eq('status', 'approved');

        if (product.id.isNotEmpty) {
          query = query.neq('id', product.id);
        }

        final res = await query.maybeSingle();
        if (res != null) {
          return DuplicateMatchResult(
            existingProduct: Product.fromJson(res),
            reason: 'บาร์โค้ดตรงกับสินค้าในระบบ ($cleanBarcode)',
          );
        }
      }

      // 2. Check duplicate by name & brand
      final cleanName = product.name.trim();
      if (cleanName.isNotEmpty) {
        var query = _client
            .from('products')
            .select()
            .ilike('name', cleanName)
            .eq('status', 'approved');

        if (product.id.isNotEmpty) {
          query = query.neq('id', product.id);
        }

        final cleanBrand = product.brand?.trim();
        if (cleanBrand != null && cleanBrand.isNotEmpty) {
          query = query.ilike('brand', cleanBrand);
        }

        final res = await query.limit(1).maybeSingle();
        if (res != null) {
          return DuplicateMatchResult(
            existingProduct: Product.fromJson(res),
            reason: cleanBrand != null && cleanBrand.isNotEmpty
                ? 'ชื่อสินค้าและแบรนด์ตรงกับสินค้าในระบบ'
                : 'ชื่อสินค้าตรงกับสินค้าในระบบ',
          );
        }
      }
    } catch (_) {
      // Catch network or DB errors gracefully
    }
    return null;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/supabase_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/services/supabase_service.dart test/core/services/supabase_service_test.dart
git commit -m "feat(service): add DuplicateMatchResult and findDuplicateProduct in SupabaseService"
```

---

### Task 2: Duplicate Product Detection in `AdminModerationService`

**Files:**
- Modify: `app_pure_check/lib/core/services/admin_moderation_service.dart`
- Test: `app_pure_check/test/core/services/admin_moderation_service_test.dart`

**Interfaces:**
- Consumes: `DuplicateMatchResult` and `findDuplicateProduct` from `SupabaseService`.
- Produces: `ModerationEvaluation.duplicateMatch` field, deduction logic (-50 points), and summary text in `reasonSummaries`.

- [ ] **Step 1: Write failing unit tests for duplicate detection in `admin_moderation_service_test.dart`**

Add tests:
```dart
    test('evaluateProduct detects duplicate product, deducts 50 points, and sets duplicate_product flag', () async {
      final fakeInci = FakeInciSearchService(unrecognizedReturn: []);
      final fakeSupabase = FakeSupabaseServiceWithDuplicate(
        duplicateToReturn: const DuplicateMatchResult(
          existingProduct: Product(
            id: 'existing-123',
            name: 'Moisturizing Cream',
            brand: 'Beauty Care',
            barcode: '8851234567890',
          ),
          reason: 'บาร์โค้ดตรงกับสินค้าในระบบ (8851234567890)',
        ),
      );

      final moderationService = AdminModerationService(
        fakeInci,
        null,
        fakeSupabase,
      );

      const product = Product(
        id: 'p-new',
        name: 'Moisturizing Cream',
        brand: 'Beauty Care',
        barcode: '8851234567890',
        ingredients: ['Water', 'Glycerin'],
      );

      final eval = await moderationService.evaluateProduct(product);

      expect(eval.flags, contains('duplicate_product'));
      expect(eval.duplicateMatch, isNotNull);
      expect(eval.confidenceScore, equals(50)); // 100 - 50 = 50
      expect(eval.isHighConfidence, isFalse);
      expect(eval.reasonSummaries.any((r) => r.contains('ตรวจพบข้อมูลซ้ำซ้อนในระบบ')), isTrue);
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/admin_moderation_service_test.dart`
Expected: FAIL with `duplicateMatch` not found or constructor mismatch.

- [ ] **Step 3: Update `ModerationEvaluation` and `AdminModerationService`**

In `app_pure_check/lib/core/services/admin_moderation_service.dart`:
1. Update `adminModerationServiceProvider`:
```dart
final adminModerationServiceProvider = Provider<AdminModerationService>((ref) {
  final inciSearchService = ref.watch(inciSearchServiceProvider);
  final cosIngService = ref.watch(cosIngVerificationServiceProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AdminModerationService(inciSearchService, cosIngService, supabaseService);
});
```
2. Update `ModerationEvaluation`:
- Add field `final DuplicateMatchResult? duplicateMatch;`
- In `reasonSummaries`:
```dart
    if (deductions.containsKey('duplicate_product')) {
      final detail = duplicateMatch?.reason ?? 'ข้อมูลซ้ำกับสินค้าในระบบ';
      final existingName = duplicateMatch?.existingProduct.name ?? '';
      final nameSuffix = existingName.isNotEmpty ? ' ("$existingName")' : '';
      list.add('ตรวจพบข้อมูลซ้ำซ้อน: $detail$nameSuffix [หัก 50 คะแนน]');
    }
```
3. Update `AdminModerationService`:
- Add `final SupabaseService? _supabaseService;` to constructor:
```dart
  AdminModerationService(
    this._inciSearchService, [
    this._cosIngVerificationService,
    this._supabaseService,
  ]);
```
- In `evaluateProduct(Product product)`:
```dart
    // 0. Duplicate check in database
    DuplicateMatchResult? duplicateMatch;
    if (_supabaseService != null) {
      duplicateMatch = await _supabaseService.findDuplicateProduct(product);
      if (duplicateMatch != null) {
        flags.add('duplicate_product');
        score -= 50;
        deductions['duplicate_product'] = -50;
      }
    }
```
- Pass `duplicateMatch: duplicateMatch` when constructing `ModerationEvaluation`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/admin_moderation_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/services/admin_moderation_service.dart test/core/services/admin_moderation_service_test.dart
git commit -m "feat(moderation): integrate duplicate check and deduction into AdminModerationService"
```

---

### Task 3: Display Duplicate Indicators in `AdminReviewScreen`

**Files:**
- Modify: `app_pure_check/lib/features/admin/screens/admin_review_screen.dart`
- Test: `app_pure_check/test/features/admin/screens/admin_review_screen_test.dart`

**Interfaces:**
- Consumes: `eval.duplicateMatch` from `ProductWithEvaluation.evaluation`.
- Produces: Warning banner on product cards and duplicate comparison row in details modal.

- [ ] **Step 1: Write widget test for duplicate display in `admin_review_screen_test.dart`**

Add test checking that duplicate warning banner appears on card and inside modal:
```dart
  testWidgets('displays duplicate warning banner on card and in detail modal when duplicate detected', (WidgetTester tester) async {
    final duplicateProduct = const Product(
      id: 'p-dup',
      name: 'Existing Cream',
      brand: 'Existing Brand',
      barcode: '8850000000001',
      ingredients: ['Water'],
      status: 'pending',
    );

    fakeSupabase = FakeSupabaseServiceWithDuplicate(
      pendingProducts: [duplicateProduct],
      duplicateToReturn: const DuplicateMatchResult(
        existingProduct: Product(
          id: 'p-approved-1',
          name: 'Existing Cream Original',
          brand: 'Existing Brand',
          barcode: '8850000000001',
          status: 'approved',
        ),
        reason: 'บาร์โค้ดตรงกับสินค้าในระบบ (8850000000001)',
      ),
    );

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Run AI analysis on the duplicate product
    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();

    // Verify warning banner on card
    expect(find.text('⚠️ ตรวจพบข้อมูลซ้ำซ้อนในระบบ'), findsOneWidget);
    expect(find.textContaining('Existing Cream Original'), findsOneWidget);

    // Open detail modal
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();

    // Verify duplicate info in modal
    expect(find.text('Duplicate Check'), findsOneWidget);
    expect(find.textContaining('Duplicate detected: บาร์โค้ดตรงกับสินค้าในระบบ'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/admin/screens/admin_review_screen_test.dart`
Expected: FAIL with banner not found.

- [ ] **Step 3: Implement duplicate warning banner and modal detail in `admin_review_screen.dart`**

In `_buildProductCard`:
- If `eval?.duplicateMatch != null`:
```dart
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ ตรวจพบข้อมูลซ้ำซ้อนในระบบ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ซ้ำกับ: "${eval.duplicateMatch!.existingProduct.name}" (${eval.duplicateMatch!.reason})',
                              style: TextStyle(
                                color: Colors.amber.shade950,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
```

In `_showProductDetailModal`:
- Under criteria breakdown:
```dart
                _buildCriterionRow(
                  label: 'Duplicate Check',
                  passed: eval.duplicateMatch == null,
                  detail: eval.duplicateMatch == null
                      ? 'No duplicates found in database'
                      : 'Duplicate detected: ${eval.duplicateMatch!.reason} (-50 pts)',
                ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/admin/screens/admin_review_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/admin/screens/admin_review_screen.dart test/features/admin/screens/admin_review_screen_test.dart
git commit -m "feat(ui): display duplicate warning indicators on admin review cards and detail modal"
```

---

### Task 4: Full Verification and Lint Check

**Files:** None (testing and analysis)

- [ ] **Step 1: Run code analyzer**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Run all unit and widget tests**

Run: `flutter test`
Expected: All tests pass with 0 failures.
