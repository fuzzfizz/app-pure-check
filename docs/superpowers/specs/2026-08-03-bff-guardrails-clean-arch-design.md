# Design Specification: BFF Pattern, Guardrails & Clean Architecture Refactoring

**Date:** 2026-08-03  
**Status:** Approved for Implementation Planning  
**Target Application:** `app_pure_check` (Flutter + Supabase)

---

## 1. Executive Summary

This design specification upgrades `app_pure_check` to address security, reliability, maintainability, and safety concerns:
1. **BFF Pattern (Backend for Frontend)**: Move direct Gemini API calls out of the Flutter client into a Supabase Edge Function (`analyze-ingredients`), keeping `GEMINI_API_KEY` hidden on the backend.
2. **Database Guardrails & Blacklist**: Introduce a `hazardous_chemicals` table in Supabase to maintain a list of known toxic/harmful ingredients. Cross-check product ingredients against this blacklist alongside Gemini AI analysis.
3. **Structured Prompt Engineering**: Enforce strict JSON output from Gemini AI with validation and fallback schemas.
4. **Clean Architecture (Repository Pattern)**: Refactor `scan_provider.dart` to use a `ScanRepository` abstraction, separating UI state management from network/database interactions.
5. **Health Disclaimer**: Display a medical disclaimer banner in `result_screen.dart` to clarify that AI outputs do not replace medical advice.

---

## 2. Architecture & Data Flow

```
[ Current ]
ScanNotifier ---> Direct Supabase Service
            ---> Direct Open Beauty Facts HTTP
            ---> Direct Gemini API Call (Exposes API Key)

[ New Architecture ]
UI (result_screen.dart, camera_screen.dart)
       |
ScanNotifier (State Management)
       |
ScanRepository (Abstract Interface)
       |
ScanRepositoryImpl (Data Handling & Coordination)
       +---> SupabaseService (Product DB & Scan History)
       +---> BeautyFactsService (Open Beauty Facts API)
       +---> Supabase Edge Function "analyze-ingredients" (BFF)
                  |
                  +---> Supabase DB (hazardous_chemicals check)
                  +---> Gemini 1.5/2.0 API (Secure Server-side key)
```

---

## 3. Detailed Component Designs

### 3.1 BFF Pattern (Supabase Edge Function: `analyze-ingredients`)

* **Location:** `supabase/functions/analyze-ingredients/index.ts`
* **Input Payload:**
  ```json
  {
    "profile": {
      "skinType": "sensitive",
      "skinConditions": ["eczema"],
      "skinConcerns": ["redness"],
      "avoidPreferences": ["parabens"]
    },
    "allergens": ["Fragrance", "Limonene"],
    "ingredients": ["Water", "Glycerin", "Limonene", "Parabens"]
  }
  ```
* **Processing Steps:**
  1. Authenticate caller (using Supabase Auth JWT header).
  2. Query `hazardous_chemicals` table in Supabase DB for any ingredient matching the input list (case-insensitive substring/regex match).
  3. Formulate strict prompt for Gemini API incorporating user profile, allergens, and blacklisted chemicals found.
  4. Call Gemini API using server-side secret `GEMINI_API_KEY`.
  5. Post-process response: If any known user allergen or blacklisted chemical is present, force `overall_safety` to `"danger"` or `"caution"` regardless of Gemini output.
  6. Return finalized JSON response to client.

### 3.2 Database Migration (`hazardous_chemicals` Table)

* **Migration SQL:** `docs/superpowers/specs/2026-08-03-hazardous-chemicals.sql`
  ```sql
  CREATE TABLE IF NOT EXISTS public.hazardous_chemicals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    chemical_name text NOT NULL UNIQUE,
    aliases text[] DEFAULT '{}',
    risk_level text CHECK (risk_level IN ('caution', 'danger')) DEFAULT 'danger',
    hazard_category text, -- e.g., 'Carcinogen', 'Endocrine Disruptor', 'Severe Allergen'
    description_th text,
    description_en text,
    created_at timestamptz DEFAULT now()
  );

  ALTER TABLE public.hazardous_chemicals ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Public read hazardous chemicals" ON public.hazardous_chemicals FOR SELECT USING (true);
  ```

### 3.3 Clean Architecture: Repository Pattern

* **Interface:** `lib/features/scan/domain/repositories/scan_repository.dart`
  ```dart
  abstract class ScanRepository {
    Future<Product?> fetchProductByBarcode(String barcode);
    Future<Product> upsertProduct(Product product);
    Future<AnalysisResult> analyzeIngredients({
      required UserProfile profile,
      required List<Allergen> allergens,
      required List<String> ingredients,
    });
    Future<void> saveScanHistory({
      required String userId,
      required String productId,
      required AnalysisResult result,
    });
  }
  ```
* **Implementation:** `lib/features/scan/data/repositories/scan_repository_impl.dart`
  * Implements `ScanRepository`.
  * Calls `SupabaseService`, `BeautyFactsService`, and Supabase Edge Function `analyze-ingredients` (with fallback to client `GeminiService` if Edge Function is unavailable or in offline dev mode).
* **Provider Integration:** Update `scanNotifierProvider` in `lib/features/scan/providers/scan_provider.dart` to consume `scanRepositoryProvider`.

### 3.4 Health Disclaimer UI & Localization

* **Localization (`app_th.arb` & `app_en.arb`)**:
  * `healthDisclaimer`: `"ผลลัพธ์นี้ประมวลผลโดย AI ควรปรึกษาแพทย์หรือผู้เชี่ยวชาญหากมีอาการแพ้รุนแรง"`
  * `healthDisclaimerEn`: `"This result is generated by AI. Please consult a doctor or healthcare professional if you experience severe allergic reactions."`
* **UI Component (`result_screen.dart`)**:
  * Positioned prominent medical warning banner right below the main safety badge banner.
  * Styled with subtle warning background, info/shield icon, and clean typography.

---

## 4. Migration & Compatibility

1. **Backwards Compatibility**: Client `GeminiService` will be preserved as a fallback data source if Supabase Edge Functions environment variable is not configured or in local development.
2. **Database Migration**: The SQL script will be added to `docs/superpowers/specs/2026-08-03-hazardous-chemicals.sql` for easy deployment to Supabase console or CLI.

---

## 5. Verification & Testing Strategy

1. **Unit Tests**:
   * Test `ScanNotifier` using mock `ScanRepository`.
   * Test `ScanRepositoryImpl` fallback logic.
2. **Integration Verification**:
   * Verify Flutter `flutter analyze` passes without lint errors.
   * Verify UI rendering of disclaimer banner on `ResultScreen`.
