# PureCheck — Flutter App Design Spec
**Date:** 2026-07-17  
**Status:** Approved  
**Stack:** Flutter + Riverpod + go_router + Supabase + Gemini AI + Open Beauty Facts API  
**Target Platform:** Mobile (iOS & Android, mobile-first)  
**Language:** Thai primary + English toggle (full l10n from the start)

---

## 1. Overview

PureCheck is a Thai-market mobile app that lets users scan cosmetic/skincare product barcodes and receive AI-powered, personalized ingredient safety analysis based on their skin profile and allergy history.

**Core value proposition:** Scan → AI analyzes → know instantly if this product is safe for YOUR skin.

**Brand tone:** Trusted personal assistant, clean, calm, clinical-soft/wellness feel. Chemistry made approachable.

**Mandatory auth:** Every screen inside the app requires authentication. No guest mode. No skip.

---

## 2. Architecture

```
Flutter App
├── Presentation Layer
│   ├── features/auth/        (splash, intro, register, login)
│   ├── features/onboarding/  (skin profile setup questionnaire)
│   ├── features/scan/        (camera, verify, loading, result)
│   ├── features/discovery/   (home, search, product detail, ingredient detail)
│   └── features/account/     (profile, history, settings)
├── Core Layer
│   ├── core/services/        (supabase_service, gemini_service, beauty_facts_service)
│   ├── core/models/          (user_profile, allergen, product, ingredient, scan_result)
│   ├── core/providers/       (auth_provider, profile_provider, scan_provider, ...)
│   ├── core/router/          (app_router.dart — go_router with auth redirect)
│   ├── core/theme/           (app_theme.dart — colors, typography, spacing)
│   └── core/l10n/            (app_en.arb, app_th.arb)
└── Config
    └── config/app_config.dart (Supabase URL, Anon Key, Gemini API Key — from env)
```

### State Management: Riverpod
- `AsyncNotifier` for all async operations (auth, scan, AI analysis)
- `Notifier` for synchronous state (profile editing, questionnaire steps)
- `StreamProvider` for Supabase auth state stream
- All providers annotated with `@riverpod` (code generation via riverpod_annotation)

### Routing: go_router
- Auth guard via `redirect` callback: checks `supabase.auth.currentSession`
- Onboarding guard: after login, check if `profiles` record exists and is complete
- Route structure:
  - `/splash` → public
  - `/intro` → public
  - `/login`, `/register` → public (redirects to `/home` if already logged in)
  - `/onboarding/*` → authenticated only, redirects to `/home` if profile complete
  - `/home`, `/scan/*`, `/search/*`, `/profile/*`, `/history`, `/settings` → authenticated only

---

## 3. Design System

### Colors
```dart
// Traffic-light safety system
safeGreen: Color(0xFF4CAF82)      // safe ingredients
cautionYellow: Color(0xFFF5A623)  // caution ingredients
dangerRed: Color(0xFFE53935)      // allergen/avoid detected

// Brand palette
primaryGreen: Color(0xFF6DBF9E)   // sage green — main brand color
lightMint: Color(0xFFE8F5EE)      // backgrounds, cards
white: Color(0xFFFFFFFF)
textPrimary: Color(0xFF1A2E22)    // dark green-tinted text
textSecondary: Color(0xFF6B8C75)  // muted text
surface: Color(0xFFF7FBF8)        // page background
```

### Typography
- Font: **Noto Sans Thai** (Google Fonts) — excellent Thai + Latin coverage
- Hierarchy: Product name (24sp bold) → Section header (18sp semibold) → Body (16sp regular) → Caption (13sp)

### Spacing
- 8pt grid system (4, 8, 12, 16, 24, 32, 48)
- Generous white space to reduce visual noise from complex ingredient data

---

## 4. Feature Specifications

### 4.1 Journey A — Onboarding (Mandatory)

#### SplashScreen
- Show PureCheck logo + tagline for 2s
- Check auth state:
  - Not logged in → `/intro`
  - Logged in, no profile → `/onboarding`
  - Logged in, profile complete → `/home`

#### IntroScreen (2–3 slides)
- Slide 1: "สแกนแล้วรู้ว่าแพ้ไหม" + illustration
- Slide 2: "AI วิเคราะห์เฉพาะโปรไฟล์ผิวคุณ" + illustration
- Slide 3: "ส่วนผสมครบ ตรงไปตรงมา" + illustration
- Single CTA button: "เริ่มต้นใช้งาน" → `/register`

#### RegisterScreen / LoginScreen
- Email + password auth via Supabase
- No "skip" or "guest" button
- After register: navigate to `/onboarding/skin-type`
- After login: navigate based on profile completeness

#### Onboarding Questionnaire (multi-step stepper)
Progress bar at top. No back-out to home mid-questionnaire.

**Step 1 — Skin Type** (required, single choice)
- Options: มัน / แห้ง / ผสม / ธรรมดา / แพ้ง่าย
- Large tappable cards with icon + label

**Step 2 — Skin Conditions & Health Flags** (required, multi-select chips)
- Skin conditions: Eczema / Rosacea / Psoriasis / Acne-prone / None
- Health flags: Pregnant / Breastfeeding / Using prescribed actives

**Step 3 — Allergen Configuration** (required step, "none" is valid)
Three entry paths:
1. **รู้ว่าแพ้อะไร** → search ingredients, add chips with symptom tags + severity
2. **ไม่แน่ใจ** → quick-check from common irritant groups; AI uses cautious mode
3. **ไม่มีที่ทราบ** → confirm and proceed; allergen list empty

**Step 4 — Skin Concerns & Avoid Preferences** (skippable)
- Concerns: สิว / ฝ้า / ริ้วรอย / รูขุมขน / ผิวหมองคล้ำ / ผิวแดง / ผิวขาดน้ำ
- Avoid prefs: fragrance / alcohol / paraben / silicone / mineral oil / essential oils (toggles)

**Completion Screen**
- Profile summary + CTA: "เริ่มสแกนเลย!" → `/home`

---

### 4.2 Journey B — Scan & AI Analysis (Hero Flow)

#### CameraScreen
- `mobile_scanner` package; animated aiming frame
- Fallback: manual search button

#### VerifyProductScreen
- Product name + brand + ingredients list (editable)
- "ยืนยันและวิเคราะห์" CTA

#### Fetch Ingredient Data (service logic)
1. Check local `products` table
2. Call Open Beauty Facts API: `https://world.openfoodfacts.org/api/v2/product/{barcode}.json`
3. Fallback: `ManualEntryScreen`

#### AI Analyzing State
- Lottie animation + reassuring copy
- Structured Gemini API call with user profile + ingredient list
- Returns JSON: `{ overall_safety, summary_th, summary_en, flagged_ingredients[], ingredient_breakdown[] }`

#### ResultScreen ⭐
- Traffic light banner (overall safety)
- Red alert cards for detected allergens
- AI summary card (Thai/English)
- Ingredient list grouped by risk level (Danger → Caution → Safe), each expandable
- Actions: "แจ้งว่าแพ้สารนี้" / "แชร์ผล" / "ช่วยชุมชน: ยืนยันส่งข้อมูล"

---

### 4.3 Journey C — Discovery (Search)

#### HomeScreen
- Centered large scan FAB (primary action)
- Search bar: products or ingredients
- Recent scans carousel

#### SearchScreen
- Debounced 300ms search
- Tab: Products | Ingredients

#### ProductDetailScreen / IngredientDetailScreen
- Full details + "วิเคราะห์สำหรับผิวฉัน" → ResultScreen

---

### 4.4 Journey D — Profile & History

#### ProfileScreen
- Edit skin type, conditions, concerns
- Manage allergens (add/remove/edit)

#### HistoryScreen
- Past scans: product name + safety color badge + date
- Tap → view cached result

#### SettingsScreen
- Language toggle (ไทย / English)
- Notification preferences
- About / Sign out

---

## 5. Supabase Schema

```sql
-- profiles (1:1 with auth.users)
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  skin_type text CHECK (skin_type IN ('oily','dry','combination','normal','sensitive')),
  skin_conditions text[] DEFAULT '{}',
  skin_concerns text[] DEFAULT '{}',
  avoid_preferences text[] DEFAULT '{}',
  onboarding_complete boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_profile" ON profiles USING (auth.uid() = id);

-- user_allergens (1:many)
CREATE TABLE user_allergens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles ON DELETE CASCADE,
  ingredient_name text NOT NULL,
  reaction_symptoms text[] DEFAULT '{}',
  severity text CHECK (severity IN ('mild','moderate','severe')) DEFAULT 'mild',
  source text CHECK (source IN ('known','suspected')) DEFAULT 'known',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE user_allergens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_allergens" ON user_allergens USING (auth.uid() = user_id);

-- products (shared, community-built)
CREATE TABLE products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode text UNIQUE,
  name text NOT NULL,
  brand text,
  ingredients text[] DEFAULT '{}',
  raw_ingredients_text text,
  source text CHECK (source IN ('local','open_beauty_facts','user_entered')) DEFAULT 'local',
  verified_count int DEFAULT 0,
  image_url text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read" ON products FOR SELECT USING (true);
CREATE POLICY "auth_insert" ON products FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- scan_history (per user)
CREATE TABLE scan_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles ON DELETE CASCADE,
  product_id uuid REFERENCES products,
  safety_level text CHECK (safety_level IN ('safe','caution','danger')),
  ai_analysis jsonb,
  scanned_at timestamptz DEFAULT now()
);
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_history" ON scan_history USING (auth.uid() = user_id);
```

---

## 6. Key Dart Models

```dart
enum SafetyLevel { safe, caution, danger }
enum SkinType { oily, dry, combination, normal, sensitive }

class UserProfile {
  final String id;
  final String skinType;
  final List<String> skinConditions;
  final List<String> skinConcerns;
  final List<String> avoidPreferences;
  final bool onboardingComplete;
}

class Allergen {
  final String id;
  final String ingredientName;
  final List<String> reactionSymptoms;
  final String severity;  // mild | moderate | severe
  final String source;    // known | suspected
}

class Product {
  final String id;
  final String? barcode;
  final String name;
  final String? brand;
  final List<String> ingredients;
  final String source;
  final int verifiedCount;
  final String? imageUrl;
}

class AnalysisResult {
  final SafetyLevel overallSafety;
  final String summaryTh;
  final String summaryEn;
  final List<FlaggedIngredient> flaggedIngredients;
  final List<IngredientBreakdown> ingredientBreakdown;
}

class FlaggedIngredient {
  final String name;
  final String reason;
  final SafetyLevel riskLevel;
}

class IngredientBreakdown {
  final String name;
  final String? function;
  final SafetyLevel riskLevel;
}
```

---

## 7. Empty / Loading / Error States

| State | UI behavior |
|---|---|
| Not logged in | go_router redirects all inner routes to `/login` |
| Profile incomplete | Redirect to `/onboarding` after login |
| No allergens set | AI uses cautious mode; note shown on result screen |
| Product not found | Navigate to ManualEntryScreen |
| AI analyzing | Lottie animation + reassuring Thai copy |
| No allergens in product | Green "ไม่พบสารที่คุณแพ้" banner |
| Network error | Friendly error card with retry button |

---

## 8. Localization

```
lib/core/l10n/
  app_en.arb
  app_th.arb
```
Language toggle stored in `SharedPreferences`. Applied via `MaterialApp.locale`.

---

## 9. Config & API Keys

```dart
// lib/config/app_config.dart
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}
```

Dev: use `flutter_dotenv` or VS Code launch config with `--dart-define-from-file=.env.local`.

Values from `.env.local`:
- `SUPABASE_URL=<SUPABASE_URL>`
- `SUPABASE_ANON_KEY=<SUPABASE_ANON_KEY>`
- `GEMINI_API_KEY=<from .env.local>`

---

## 10. Build Order (Priority)

1. Project scaffold (Flutter create + theme + routing + config)
2. Auth screens (Splash, Intro, Register, Login)
3. Onboarding questionnaire (4 steps + completion)
4. Home screen
5. Camera/Scan screen
6. Verify Product screen
7. Fetch service (local DB → Open Beauty Facts → manual entry)
8. Gemini AI service + AI Analyzing state
9. **Result/Analysis screen** ⭐
10. Search + Product/Ingredient detail screens
11. Profile + Allergen management
12. History screen
13. Settings + language toggle
14. Polish: Lottie animations, skeleton loading, error states, l10n strings
