# Design Specification: Admin Duplicate Product Detection

**Date:** 2026-09-03  
**Status:** Approved for Implementation Planning  
**Target Application:** `app_pure_check` (Flutter + Riverpod + Supabase)

---

## 1. Executive Summary

In the Admin Review Screen (`admin_review_screen.dart`), administrators review user-submitted pending products. Previously, the AI moderation analysis evaluated product name length, brand presence, spam patterns, and INCI ingredient matches, but did not check if the product was already registered in the database.

This feature adds duplicate product detection to the AI analysis workflow:
1. **Duplicate Detection in Supabase**: Queries the database to check if another approved product already exists with the same barcode, or with the same product name and brand.
2. **Deduction & Auto-Approve Prevention**: If a duplicate is found, the product receives a 50-point deduction and a `duplicate_product` flag. This caps the confidence score below 80% (categorizing it as Yellow or Red), ensuring it cannot be auto-approved by the "Auto-Approve Safe" batch action.
3. **Admin Visibility & Context**: The admin card and detail modal display clear duplicate warning indicators along with the details of the conflicting existing product, allowing administrators to make an informed decision (Reject or manually review).

---

## 2. Architecture & Component Design

```
[AdminReviewScreen]
       │
       ▼ triggers AI Analysis
[AdminModerationService.evaluateProduct]
       │
       ├─► Check Name Length, Brand, Spam, INCI Rate
       │
       ├─► [SupabaseService.findDuplicateProduct]
       │          │
       │          ├─► 1. Query by barcode (if barcode present)
       │          └─► 2. Query by name & brand (case-insensitive, trimmed)
       │          │
       │          └─► Returns DuplicateMatchResult?
       │
       ├─► If duplicate found:
       │      - flags.add('duplicate_product')
       │      - score -= 50
       │      - deductions['duplicate_product'] = -50
       │      - attach duplicateMatch info
       │
       ▼
[ModerationEvaluation]
       │
       ▼ displays on UI
[AdminReviewScreen]
       ├─► Product Card: Prominent duplicate warning banner
       └─► Detail Modal: Comparison card with existing product details & criteria breakdown
```

---

## 3. Detailed Component Specifications

### 3.1 Data Layer (`DuplicateMatchResult` & `SupabaseService`)

* **Model Class (`lib/core/services/supabase_service.dart` or `admin_moderation_service.dart`)**:
  ```dart
  class DuplicateMatchResult {
    final Product existingProduct;
    final String reason; // e.g. 'บาร์โค้ดตรงกับสินค้าในระบบ' or 'ชื่อและแบรนด์ตรงกับสินค้าในระบบ'

    const DuplicateMatchResult({
      required this.existingProduct,
      required this.reason,
    });
  }
  ```

* **`SupabaseService.findDuplicateProduct(Product product)`**:
  - Parameters: `Product product`
  - Returns: `Future<DuplicateMatchResult?>`
  - Logic:
    1. **Barcode Check**:
       - If `product.barcode != null && product.barcode!.trim().isNotEmpty`:
       - Query `products` table where `barcode == product.barcode!.trim()` AND `id != product.id` AND `status == 'approved'`.
       - If match found, return `DuplicateMatchResult(existingProduct: matchedProduct, reason: 'บาร์โค้ดตรงกับสินค้าในระบบ (${product.barcode})')`.
    2. **Name & Brand Check**:
       - Normalize name: `cleanName = product.name.trim()`
       - Normalize brand: `cleanBrand = product.brand?.trim()`
       - If `cleanName` is not empty:
         - Query `products` table where `name ilike cleanName` AND `id != product.id` AND `status == 'approved'`.
         - If `cleanBrand` is not null and not empty: filter where `brand ilike cleanBrand`.
         - If match found, return `DuplicateMatchResult(existingProduct: matchedProduct, reason: 'ชื่อและแบรนด์ตรงกับสินค้าในระบบ')`.
    3. Return `null` if no matching product is found.
    4. Network error tolerance: If query throws, catch gracefully and return `null` so analysis is not blocked.

### 3.2 Moderation Service Layer (`AdminModerationService`)

* **Provider Update**:
  - Inject `SupabaseService` into `AdminModerationService`:
    ```dart
    final adminModerationServiceProvider = Provider<AdminModerationService>((ref) {
      final inciSearchService = ref.watch(inciSearchServiceProvider);
      final cosIngService = ref.watch(cosIngVerificationServiceProvider);
      final supabaseService = ref.watch(supabaseServiceProvider);
      return AdminModerationService(inciSearchService, cosIngService, supabaseService);
    });
    ```

* **`ModerationEvaluation` Model**:
  - Add field: `final DuplicateMatchResult? duplicateMatch;`
  - Add getter/summary:
    ```dart
    if (deductions.containsKey('duplicate_product')) {
      list.add('ตรวจพบข้อมูลซ้ำซ้อนในระบบ: ${duplicateMatch?.reason ?? ""} [หัก 50 คะแนน]');
    }
    ```

* **`evaluateProduct(Product product)`**:
  - Call `_supabaseService?.findDuplicateProduct(product)`
  - If a duplicate match is returned:
    - `flags.add('duplicate_product')`
    - `score -= 50`
    - `deductions['duplicate_product'] = -50`
    - Set `duplicateMatch: match` on returned `ModerationEvaluation`.

### 3.3 UI Layer (`AdminReviewScreen`)

* **Product Card (`_buildProductCard`)**:
  - If `eval != null && eval.duplicateMatch != null`:
    - Render an amber/orange warning container above or inside the summary box:
      - Icon: `Icons.warning_amber_rounded`
      - Title: `⚠️ ตรวจพบข้อมูลซ้ำซ้อนในระบบ`
      - Details: `ซ้ำกับ: "${eval.duplicateMatch!.existingProduct.name}" (${eval.duplicateMatch!.reason})`
    - Score deduction is shown in the reason bullet points (`[หัก 50 คะแนน]`).

* **Detail Modal (`_showProductDetailModal`)**:
  - If `eval?.duplicateMatch != null`:
    - Display a dedicated "Duplicate Product Detected" section:
      - Warning styling with existing product name, brand, barcode, and existing product ID.
  - In "AI Evaluation Criteria Breakdown":
    - Include `_buildCriterionRow`:
      - Label: `Duplicate Check`
      - Passed: `eval.duplicateMatch == null`
      - Detail: `eval.duplicateMatch == null ? 'Passed (No duplicate in database)' : 'Duplicate found: ${eval.duplicateMatch!.reason} (-50 pts)'`

---

## 4. Edge Cases & Error Handling

1. **Self-match Prevention**: The query explicitly filters `id != product.id` to avoid matching the current pending product against itself.
2. **Whitespace and Case Sensitivity**: Product names and brands are trimmed and queried using PostgreSQL `ilike` (case-insensitive).
3. **Missing Barcode or Brand**: If a product has no barcode, the barcode query is skipped and only the name & brand matching is performed. If brand is null/empty, matching checks for exact case-insensitive product name.
4. **Offline / Network Resilience**: If the Supabase query encounters a network glitch or timeout, the error is caught, returning `null` so the rest of the AI evaluation (INCI analysis, name length, etc.) continues without crashing.
5. **Auto-Approve Immunity**: By deducting 50 points, maximum possible score is 50, preventing the item from qualifying for `isHighConfidence` (>= 80%) and guaranteeing it will not be auto-approved by the batch action.

---

## 5. Verification & Testing Plan

1. **Unit Tests (`test/features/admin/duplicate_product_test.dart`)**:
   - Test `AdminModerationService.evaluateProduct` with a mock `SupabaseService` returning a duplicate product.
   - Verify `duplicate_product` flag is added, 50 points are deducted, and score is capped under 80.
   - Verify `evaluateProduct` when no duplicate exists keeps high score (if valid).
2. **Analysis & Compilation**:
   - Run `flutter analyze` to ensure zero compilation or lint errors.
   - Run `flutter test` to ensure all existing and new tests pass.
