# Design Specification: Hybrid Pending Review & AI Admin Moderation Assistant

**Date:** 2026-08-03  
**Status:** Approved for Implementation Planning  
**Target Application:** `app_pure_check` (Flutter + Supabase)

---

## 1. Executive Summary

This design specification introduces a **Hybrid (Pending Review)** moderation system for user-submitted cosmetic/skincare products in `app_pure_check`, complete with an **AI Admin Moderation Assistant**:
1. **User Submission & Instant Analysis**: Users can submit unlisted products manually or via barcode scan and receive immediate AI personal analysis without waiting for admin approval.
2. **Privacy & Visibility Scoping**: New user-submitted products receive `is_verified = false` and `status = 'pending'`. RLS policies restrict public search/lookup so unverified items are visible only to their creator until approved by an admin.
3. **AI Admin Moderation Assistant**: Admin dashboard (`admin_review_screen.dart`) features automated confidence scoring (INCI match rate, Open Beauty Facts cross-check, spam/profanity detection), visual traffic light badges (Green/Yellow/Red), 1-click batch auto-approval, and AI 1-click auto-sanitize.

---

## 2. Database Schema & RLS Security

* **Migration SQL File:** `docs/superpowers/specs/2026-08-03-hybrid-pending-review-migration.sql`
  ```sql
  -- Add verification & moderation columns to products table
  ALTER TABLE public.products 
    ADD COLUMN IF NOT EXISTS is_verified boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS status text CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS submitted_by uuid REFERENCES public.profiles(id),
    ADD COLUMN IF NOT EXISTS confidence_score int DEFAULT 0,
    ADD COLUMN IF NOT EXISTS ai_flags text[] DEFAULT '{}';

  -- Set existing products as verified/approved
  UPDATE public.products 
    SET is_verified = true, status = 'approved', confidence_score = 100 
    WHERE is_verified IS NULL OR status IS NULL;

  -- Update RLS Policy: Public read only for verified products OR own submissions
  DROP POLICY IF EXISTS "Public read products" ON public.products;
  CREATE POLICY "Public read verified products or own submission" ON public.products
    FOR SELECT USING (is_verified = true OR submitted_by = auth.uid());
  ```

---

## 3. Detailed Component Architecture

### 3.1 Data Layer & Service Extensions (`SupabaseService` & `ProductRepository`)

* **`Product` Model Update (`product.dart`)**:
  * Add fields: `bool isVerified`, `String status`, `String? submittedBy`, `int confidenceScore`, `List<String> aiFlags`.
* **`SupabaseService` Updates**:
  * `getProductByBarcode(String barcode)`: filters `is_verified = true OR submitted_by = current_user_id`.
  * `searchProducts(String query)`: filters `is_verified = true OR submitted_by = current_user_id`.
  * `getPendingProducts()`: fetches all products where `status = 'pending'` (for Admin Review Screen).
  * `updateProductStatus(String productId, String status, bool isVerified)`: updates status to `'approved'` or `'rejected'`.

### 3.2 AI Admin Moderation Assistant (`AdminModerationService`)

* **Location:** `lib/core/services/admin_moderation_service.dart`
* **Automated Confidence Evaluation (`calculateConfidenceScore`)**:
  1. **INCI Match Rate**: Calculate percentage of ingredients present in `inci_ingredients` database.
  2. **Profanity / Nonsense Check**: Detect spam patterns (e.g. repeated characters, gibberish strings).
  3. **Score & Flags**:
     * Score >= 90: Green Badge (High Confidence, safe for 1-click batch auto-approve).
     * Score 60 - 89: Yellow Badge (Needs Inspection, suspect ingredients highlighted).
     * Score < 60: Red Badge (Flagged, spam or invalid).

### 3.3 Admin Review UI (`admin_review_screen.dart`)

* **Route:** `/admin/review`
* **UI Features**:
  * List view of pending products sorted by confidence score.
  * Traffic light badges (🟢 🟡 🔴) displaying confidence percentage and AI flags.
  * **"Auto-Approve All Safe (🟢)"** button for 1-click batch approval of high-confidence items.
  * **"Approve"** and **"Reject"** buttons per item card.
  * **"AI Auto-Sanitize"** button to clean up product formatting before approving.

---

## 4. Verification & Testing Strategy

1. **Unit Tests**:
   * Test `Product` model serialization with `is_verified`, `status`, `submitted_by`, `confidence_score`.
   * Test `AdminModerationService` confidence scoring logic.
   * Test `SupabaseService` product filtering for public vs creator visibility.
2. **Widget & Screen Tests**:
   * Test `AdminReviewScreen` queue rendering, confidence badge styling, and approval action triggers.
3. **Analyze Verification**:
   * Verify zero lint errors with `flutter analyze`.
   * Verify 100% test pass rate with `flutter test`.
