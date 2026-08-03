# Design Specification: INCI Auto-Complete & AI Pre-Clean ("Did You Mean...?")

**Date:** 2026-08-03  
**Status:** Approved for Implementation Planning  
**Target Application:** `app_pure_check` (Flutter + Supabase)

---

## 1. Executive Summary

This design specification introduces a two-tier ingredient validation and spell-checking system for manual skincare product entry in `app_pure_check`:
1. **Tier 1: Real-time Auto-Complete Suggestion Box**: As the user types in `manual_entry_screen.dart`, query a standard INCI ingredient database (`inci_ingredients`) using Supabase `pg_trgm` fuzzy searching (debounced 300ms) and show inline suggestions.
2. **Tier 2: AI Pre-Clean ("Did You Mean...?") Dialog**: On form submission, identify any ingredients that are missing from the INCI/Hazardous database, send only those unrecognized terms to Gemini AI for typo correction, and display an interactive confirmation dialog with before/after suggestions.

---

## 2. System Architecture & Data Flow

```
[ Tier 1: Real-Time Typing ]
User Types in ManualEntryScreen
       |
Debounce (300ms, >= 3 chars)
       |
Supabase Query (inci_ingredients + pg_trgm trigram search)
       |
Overlay / Dropdown Suggestions List ---> User Taps to Autocomplete

[ Tier 2: Form Submission ]
User Clicks "Done & Continue"
       |
Extract List of Ingredients: ["Niacinmid", "Glycerin", "Watar"]
       |
Local/Supabase Fast DB Check
       +---> Recognized: ["Glycerin"]
       +---> Unrecognized: ["Niacinmid", "Watar"]
       |
If Unrecognized terms exist:
       |
Call Edge Function / Service `checkIngredientTypos(["Niacinmid", "Watar"])`
       |
Gemini AI Returns Corrections JSON: {"Niacinmid": "Niacinamide", "Watar": "Water"}
       |
Display "Did You Mean...?" Modal Dialog
       +---> Accept Corrections: Replaces typos with corrected names & proceeds
       +---> Keep Original: Preserves user input & proceeds
```

---

## 3. Database Schema (`inci_ingredients` & `pg_trgm`)

* **Migration SQL File:** `docs/superpowers/specs/2026-08-03-inci-ingredients-migration.sql`
  ```sql
  CREATE EXTENSION IF NOT EXISTS pg_trgm;

  CREATE TABLE IF NOT EXISTS public.inci_ingredients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    category text,
    description_th text,
    created_at timestamptz DEFAULT now()
  );

  ALTER TABLE public.inci_ingredients ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Public read inci_ingredients" ON public.inci_ingredients FOR SELECT USING (true);

  CREATE INDEX IF NOT EXISTS idx_inci_ingredients_name_trgm 
    ON public.inci_ingredients USING gin (name gin_trgm_ops);
  ```

---

## 4. Detailed Component Design

### 4.1 Tier 1: Flutter Auto-Complete (`manual_entry_screen.dart` & `InciSearchService`)

* **`InciSearchService`**: `lib/core/services/inci_search_service.dart`
  * `Future<List<String>> searchIngredients(String query, {int limit = 5})`
  * Executes Supabase query: `.from('inci_ingredients').select('name').ilike('name', '%$query%').limit(limit)`
* **UI Behavior (`manual_entry_screen.dart`)**:
  * Detects current token being typed (after the last `,` or `;`).
  * Shows an Overlay / CompositedTransformFollower suggestions list below the ingredients text field.
  * Tapping a suggestion replaces the active partial token with the standard INCI name.

### 4.2 Tier 2: AI Pre-Clean ("Did You Mean...?")

* **Edge Function / Service Method**: `checkIngredientTypos(List<String> unknownIngredients)`
  * Send prompt to Gemini API:
    ```
    Correct these cosmetic ingredient typos to valid INCI standard names.
    Input: ["Niacinmid", "Watar"]
    Return ONLY a JSON map of typo -> corrected name:
    {
      "Niacinmid": "Niacinamide",
      "Watar": "Water"
    }
    If a term is not a typo or is a valid custom ingredient, omit it from the map.
    ```
* **UI Component (`typo_correction_dialog.dart`)**: `lib/features/scan/widgets/typo_correction_dialog.dart`
  * Renders original name alongside suggested replacement in a clean comparison list.
  * Buttons: "ใช้คำที่แก้ไขแล้ว (Accept Suggestions)" vs "ใช้คำเดิมตามที่พิมพ์ (Keep Original)".

---

## 5. Verification Strategy

1. **Unit Tests**:
   * Test `InciSearchService` with mock Supabase responses.
   * Test typo detection and replacement logic in `ManualEntryScreen`.
2. **Widget Tests**:
   * Test rendering of `TypoCorrectionDialog`.
3. **Integration & Analyze Verification**:
   * Verify zero lint errors with `flutter analyze`.
   * Verify test suite pass rate with `flutter test`.
