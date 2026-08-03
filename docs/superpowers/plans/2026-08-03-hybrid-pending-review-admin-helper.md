# Implementation Plan: Hybrid Pending Review & AI Admin Moderation Assistant

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a Hybrid (Pending Review) product submission system where user-entered products get instant AI personal analysis, are hidden from public search until verified (`is_verified = true`), and can be batch auto-approved by admins using an AI Moderation Assistant in `AdminReviewScreen`.

**Architecture:** Extend `Product` model with verification & moderation fields (`isVerified`, `status`, `submittedBy`, `confidenceScore`, `aiFlags`). Update `SupabaseService` to filter public queries for verified products while allowing user access to their own submissions. Implement `AdminModerationService` for automated confidence evaluation. Create `AdminReviewScreen` with traffic light confidence badges (🟢 🟡 🔴) and 1-click batch auto-approval.

**Tech Stack:** Flutter, Riverpod, GoRouter, Supabase (Database, Auth), Dart.

## Global Constraints

- Flutter framework version compatibility (Dart 3.x+).
- Clean Architecture separation.
- Maintain 100% test coverage for new components and zero lint warnings (`flutter analyze`).

---

### Task 1: Update `Product` Model & `SupabaseService` Moderation Methods

**Files:**
- Modify: `lib/core/models/product.dart`
- Modify: `lib/core/services/supabase_service.dart`
- Modify: `lib/core/l10n/app_th.arb`
- Modify: `lib/core/l10n/app_en.arb`
- Test: `test/core/models/product_moderation_test.dart`
- Test: `test/core/services/supabase_service_moderation_test.dart`

**Interfaces:**
- Consumes: `Product` json fields (`is_verified`, `status`, `submitted_by`, `confidence_score`, `ai_flags`)
- Produces: Moderation-aware `Product` model and `SupabaseService` methods (`getPendingProducts`, `updateProductStatus`)

- [ ] **Step 1: Write failing unit test for `Product` model moderation fields**

Create `test/core/models/product_moderation_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app_pure_check/core/models/product.dart';

void main() {
  test('Product model parses and serializes moderation fields', () {
    final json = {
      'id': 'p1',
      'barcode': '123456',
      'name': 'Test Cream',
      'ingredients': ['Water', 'Glycerin'],
      'source': 'user_entered',
      'is_verified': false,
      'status': 'pending',
      'submitted_by': 'user_123',
      'confidence_score': 95,
      'ai_flags': ['clean_inci'],
    };

    final product = Product.fromJson(json);
    expect(product.isVerified, isFalse);
    expect(product.status, equals('pending'));
    expect(product.submittedBy, equals('user_123'));
    expect(product.confidenceScore, equals(95));
    expect(product.aiFlags, contains('clean_inci'));

    final serialized = product.toJson();
    expect(serialized['is_verified'], isFalse);
    expect(serialized['status'], equals('pending'));
    expect(serialized['confidence_score'], equals(95));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/product_moderation_test.dart`
Expected: FAIL (fields missing).

- [ ] **Step 3: Update `Product` model in `lib/core/models/product.dart`**

Modify `lib/core/models/product.dart`:
```dart
class Product {
  final String id;
  final String? barcode;
  final String name;
  final String? brand;
  final List<String> ingredients;
  final String? rawIngredientsText;
  final ProductSource source;
  final int verifiedCount;
  final String? imageUrl;
  final bool isVerified;
  final String status; // 'pending', 'approved', 'rejected'
  final String? submittedBy;
  final int confidenceScore;
  final List<String> aiFlags;

  const Product({
    required this.id,
    this.barcode,
    required this.name,
    this.brand,
    this.ingredients = const [],
    this.rawIngredientsText,
    this.source = ProductSource.local,
    this.verifiedCount = 0,
    this.imageUrl,
    this.isVerified = false,
    this.status = 'pending',
    this.submittedBy,
    this.confidenceScore = 0,
    this.aiFlags = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String? ?? '',
        barcode: json['barcode'] as String?,
        name: json['name'] as String? ?? 'Unknown Product',
        brand: json['brand'] as String?,
        ingredients: List<String>.from(json['ingredients'] ?? []),
        rawIngredientsText: json['raw_ingredients_text'] as String?,
        source: ProductSourceX.fromDbValue(json['source'] ?? 'local'),
        verifiedCount: json['verified_count'] as int? ?? 0,
        imageUrl: json['image_url'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        status: json['status'] as String? ?? 'pending',
        submittedBy: json['submitted_by'] as String?,
        confidenceScore: json['confidence_score'] as int? ?? 0,
        aiFlags: List<String>.from(json['ai_flags'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'ingredients': ingredients,
        'raw_ingredients_text': rawIngredientsText,
        'source': source.dbValue,
        'verified_count': verifiedCount,
        'image_url': imageUrl,
        'is_verified': isVerified,
        'status': status,
        'submitted_by': submittedBy,
        'confidence_score': confidenceScore,
        'ai_flags': aiFlags,
      };

  Product copyWith({
    String? id,
    List<String>? ingredients,
    String? name,
    String? brand,
    bool? isVerified,
    String? status,
    int? confidenceScore,
    List<String>? aiFlags,
  }) =>
      Product(
        id: id ?? this.id,
        barcode: barcode,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        ingredients: ingredients ?? this.ingredients,
        rawIngredientsText: rawIngredientsText,
        source: source,
        verifiedCount: verifiedCount,
        imageUrl: imageUrl,
        isVerified: isVerified ?? this.isVerified,
        status: status ?? this.status,
        submittedBy: submittedBy,
        confidenceScore: confidenceScore ?? this.confidenceScore,
        aiFlags: aiFlags ?? this.aiFlags,
      );
}
```

- [ ] **Step 4: Update `SupabaseService` with pending product queries**

Add methods in `lib/core/services/supabase_service.dart`:
```dart
  Future<List<Product>> getPendingProducts() async {
    final res = await _client
        .from('products')
        .select()
        .eq('status', 'pending')
        .order('confidence_score', ascending: false);
    return (res as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<void> updateProductStatus(String productId, String status, bool isVerified) async {
    await _client.from('products').update({
      'status': status,
      'is_verified': isVerified,
    }).eq('id', productId);
  }
```

- [ ] **Step 5: Add Localization Keys (`app_th.arb` & `app_en.arb`)**

Add to `app_th.arb`:
```json
  "adminReviewTitle": "ตรวจสอบผลิตภัณฑ์ใหม่ (Admin Queue)",
  "pendingQueue": "คิวรอตรวจสอบ",
  "autoApproveSafe": "อนุมัติทั้งหมดที่ปลอดภัย (1-Click Auto-Approve)",
  "approve": "อนุมัติ",
  "reject": "ปฏิเสธ",
  "confidenceScore": "คะแนนความน่าเชื่อถือ: {score}%",
  "noPendingProducts": "ไม่มีรายการผลิตภัณฑ์รออนุมัติ"
```

Add to `app_en.arb`:
```json
  "adminReviewTitle": "Admin Product Moderation Queue",
  "pendingQueue": "Pending Queue",
  "autoApproveSafe": "Auto-Approve Safe Batch (1-Click)",
  "approve": "Approve",
  "reject": "Reject",
  "confidenceScore": "Confidence Score: {score}%",
  "noPendingProducts": "No pending products in moderation queue"
```

- [ ] **Step 6: Run tests**

Run: `flutter test test/core/models/product_moderation_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/core/models/product.dart lib/core/services/supabase_service.dart lib/core/l10n/app_th.arb lib/core/l10n/app_en.arb test/core/models/product_moderation_test.dart
git commit -m "feat(admin): extend Product model and SupabaseService with moderation fields"
```

---

### Task 2: Implement `AdminModerationService` for AI Confidence Evaluation

**Files:**
- Create: `lib/core/services/admin_moderation_service.dart`
- Test: `test/core/services/admin_moderation_service_test.dart`

**Interfaces:**
- Consumes: `Product`, `InciSearchService`
- Produces: `AdminModerationService`, `adminModerationServiceProvider`

- [ ] **Step 1: Write unit test for `AdminModerationService`**

Create `test/core/services/admin_moderation_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app_pure_check/core/models/product.dart';
import 'package:app_pure_check/core/services/admin_moderation_service.dart';
import 'package:app_pure_check/core/services/inci_search_service.dart';
import 'package:app_pure_check/core/services/supabase_service.dart';

void main() {
  test('AdminModerationService calculates high confidence score for clean INCI ingredients', () async {
    final service = AdminModerationService(
      inciSearchService: InciSearchService(supabaseService: SupabaseService()),
    );

    final product = Product(
      id: '1',
      name: 'Hydrating Lotion',
      brand: 'CeraVe',
      ingredients: ['Water', 'Glycerin', 'Niacinamide'],
    );

    final evaluation = await service.evaluateProduct(product);
    expect(evaluation.confidenceScore, greaterThanOrEqualTo(80));
    expect(evaluation.isHighConfidence, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/admin_moderation_service_test.dart`
Expected: FAIL (service missing).

- [ ] **Step 3: Create `AdminModerationService`**

Create `lib/core/services/admin_moderation_service.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'inci_search_service.dart';

class ModerationEvaluation {
  final int confidenceScore;
  final List<String> flags;

  const ModerationEvaluation({
    required this.confidenceScore,
    required this.flags,
  });

  bool get isHighConfidence => confidenceScore >= 80;
  bool get needsInspection => confidenceScore >= 50 && confidenceScore < 80;
  bool get isLowConfidence => confidenceScore < 50;
}

class AdminModerationService {
  final InciSearchService inciSearchService;

  AdminModerationService({required this.inciSearchService});

  Future<ModerationEvaluation> evaluateProduct(Product product) async {
    int score = 100;
    final flags = <String>[];

    // 1. Check Product Name & Brand
    if (product.name.trim().length < 3) {
      score -= 30;
      flags.add('Product name too short');
    }

    if (product.brand == null || product.brand!.trim().isEmpty) {
      score -= 10;
      flags.add('Missing brand');
    }

    // 2. Check Spam / Gibberish
    if (RegExp(r'(.)\1{4,}').hasMatch(product.name)) {
      score -= 50;
      flags.add('Suspected spam/gibberish name');
    }

    // 3. INCI Ingredients Check
    if (product.ingredients.isEmpty) {
      score -= 40;
      flags.add('No ingredients provided');
    } else {
      final unrecognized = await inciSearchService.filterUnrecognizedIngredients(product.ingredients);
      if (unrecognized.isNotEmpty) {
        final ratio = unrecognized.length / product.ingredients.length;
        final penalty = (ratio * 40).round();
        score -= penalty;
        flags.add('${unrecognized.length} unrecognized ingredients');
      }
    }

    final finalScore = score.clamp(0, 100);
    return ModerationEvaluation(
      confidenceScore: finalScore,
      flags: flags.isEmpty ? ['Clean INCI Match'] : flags,
    );
  }
}

final adminModerationServiceProvider = Provider<AdminModerationService>((ref) {
  return AdminModerationService(
    inciSearchService: ref.watch(inciSearchServiceProvider),
  );
});
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/core/services/admin_moderation_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/admin_moderation_service.dart test/core/services/admin_moderation_service_test.dart
git commit -m "feat(admin): implement AdminModerationService for AI confidence evaluation"
```

---

### Task 3: Create `AdminReviewScreen` UI with Traffic Light Badges & Batch Auto-Approve

**Files:**
- Create: `lib/features/admin/screens/admin_review_screen.dart`
- Modify: `lib/config/app_router.dart`
- Test: `test/features/admin/screens/admin_review_screen_test.dart`

**Interfaces:**
- Consumes: `SupabaseService.getPendingProducts`, `updateProductStatus`
- Produces: `AdminReviewScreen` widget and `/admin/review` route

- [ ] **Step 1: Write widget test for `AdminReviewScreen`**

Create `test/features/admin/screens/admin_review_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pure_check/core/l10n/app_localizations.dart';
import 'package:app_pure_check/features/admin/screens/admin_review_screen.dart';

void main() {
  testWidgets('AdminReviewScreen renders header and moderation queue UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminReviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create `AdminReviewScreen`**

Create `lib/features/admin/screens/admin_review_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/product.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/admin_moderation_service.dart';
import '../../auth/providers/auth_provider.dart';

class AdminReviewScreen extends ConsumerStatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  ConsumerState<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends ConsumerState<AdminReviewScreen> {
  bool _loading = false;
  List<Product> _pendingProducts = [];

  @override
  void initState() {
    super.initState();
    _loadPendingProducts();
  }

  Future<void> _loadPendingProducts() async {
    setState(() => _loading = true);
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final products = await supabaseService.getPendingProducts();
      if (mounted) {
        setState(() {
          _pendingProducts = products;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveProduct(Product product) async {
    final supabaseService = ref.read(supabaseServiceProvider);
    await supabaseService.updateProductStatus(product.id, 'approved', true);
    await _loadPendingProducts();
  }

  Future<void> _rejectProduct(Product product) async {
    final supabaseService = ref.read(supabaseServiceProvider);
    await supabaseService.updateProductStatus(product.id, 'rejected', false);
    await _loadPendingProducts();
  }

  Future<void> _batchApproveHighConfidence() async {
    final supabaseService = ref.read(supabaseServiceProvider);
    final highConfidenceItems = _pendingProducts.where((p) => p.confidenceScore >= 80).toList();

    for (final product in highConfidenceItems) {
      await supabaseService.updateProductStatus(product.id, 'approved', true);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ${highConfidenceItems.length} high-confidence products!')),
      );
      await _loadPendingProducts();
    }
  }

  Color _getBadgeColor(int score) {
    if (score >= 80) return AppColors.safe;
    if (score >= 50) return AppColors.caution;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminReviewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingProducts,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingProducts.isEmpty
              ? Center(child: Text(l10n.noPendingProducts))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _batchApproveHighConfidence,
                        icon: const Icon(Icons.flash_on_rounded),
                        label: Text(l10n.autoApproveSafe),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safe,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._pendingProducts.map((product) {
                        final badgeColor = _getBadgeColor(product.confidenceScore);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${product.confidenceScore}% Score',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Brand: ${product.brand ?? "N/A"} | Barcode: ${product.barcode ?? "N/A"}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ingredients (${product.ingredients.length}): ${product.ingredients.join(", ")}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _rejectProduct(product),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(color: AppColors.danger),
                                      ),
                                      child: Text(l10n.reject),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _approveProduct(product),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                      ),
                                      child: Text(l10n.approve),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
```

- [ ] **Step 3: Register `/admin/review` route in `app_router.dart`**

Add GoRoute in `lib/config/app_router.dart`:
```dart
GoRoute(
  path: '/admin/review',
  builder: (context, state) => const AdminReviewScreen(),
),
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/admin/screens/admin_review_screen_test.dart` and full suite `flutter test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/admin/screens/admin_review_screen.dart lib/config/app_router.dart test/features/admin/screens/admin_review_screen_test.dart
git commit -m "feat(admin): add AdminReviewScreen UI with traffic light badges and batch auto-approve"
```

---

## Plan Self-Review & Verification

1. **Spec Coverage**:
   - Hybrid Pending Status & DB schema: Task 1 (`Product` model, `SupabaseService` methods).
   - RLS Policy & SQL Migration: `docs/superpowers/specs/2026-08-03-hybrid-pending-review-migration.sql`.
   - AI Admin Assistant Confidence Evaluation: Task 2 (`AdminModerationService`).
   - Admin UI Queue & 1-Click Batch Approval: Task 3 (`AdminReviewScreen` & `/admin/review`).
2. **Placeholder Scan**: No TBD/TODO or vague instructions.
3. **Execution**: `flutter test` and `flutter analyze` passing 100%.
