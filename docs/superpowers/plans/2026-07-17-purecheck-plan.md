# PureCheck Flutter App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete Flutter mobile app (PureCheck) that lets Thai users scan cosmetic barcodes, get AI-powered ingredient safety analysis personalized to their skin profile and allergy history.

**Architecture:** Feature-first Flutter app with Riverpod state management, go_router navigation with auth guards, Supabase for auth+DB, Gemini AI for ingredient analysis, Open Beauty Facts API for ingredient data.

**Tech Stack:** Flutter 3.44.1, Dart 3.12.1, flutter_riverpod + riverpod_annotation, go_router, supabase_flutter, google_generative_ai, mobile_scanner, flutter_dotenv, google_fonts, lottie, flutter_localizations + intl

## Global Constraints

- Flutter 3.44.1 / Dart 3.12.1
- Project root: `D:\AppPureCheck\app_pure_check\`
- App name: `pure_check` (package: `com.purecheck.app`)
- All routes except `/splash`, `/intro`, `/login`, `/register` require authentication — enforced by go_router redirect
- After register → always go to `/onboarding` (mandatory, no skip to home)
- After login with complete profile → `/home`; after login with incomplete profile → `/onboarding`
- Traffic-light safety colors: safe=`0xFF4CAF82`, caution=`0xFFF5A623`, danger=`0xFFE53935`
- Brand sage green: `0xFF6DBF9E`; surface: `0xFFF7FBF8`; mint bg: `0xFFE8F5EE`
- Font: Noto Sans Thai (Google Fonts)
- API keys loaded via `flutter_dotenv` from `.env` file (copy from `D:\AppPureCheck\.env.local`)
- Supabase URL: `https://efvdfqntcudqjjowvonp.supabase.co`
- Supabase Anon Key: `<SUPABASE_ANON_KEY>`
- UI language: Thai primary with English toggle (l10n via ARB files)
- No guest mode — every in-app screen requires login

---

## File Structure

```
app_pure_check/
├── .env                          # API keys (copy from .env.local)
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── config/
│   │   └── app_config.dart       # API keys, constants
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart    # Colors, typography, spacing tokens
│   │   ├── router/
│   │   │   └── app_router.dart   # go_router with auth redirect
│   │   ├── l10n/
│   │   │   ├── app_en.arb
│   │   │   └── app_th.arb
│   │   ├── models/
│   │   │   ├── user_profile.dart
│   │   │   ├── allergen.dart
│   │   │   ├── product.dart
│   │   │   └── analysis_result.dart
│   │   └── services/
│   │       ├── supabase_service.dart
│   │       ├── gemini_service.dart
│   │       └── beauty_facts_service.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── providers/auth_provider.dart
│   │   │   └── screens/
│   │   │       ├── splash_screen.dart
│   │   │       ├── intro_screen.dart
│   │   │       ├── login_screen.dart
│   │   │       └── register_screen.dart
│   │   ├── onboarding/
│   │   │   ├── providers/onboarding_provider.dart
│   │   │   └── screens/
│   │   │       ├── onboarding_shell.dart       # stepper shell
│   │   │       ├── step_skin_type.dart
│   │   │       ├── step_skin_conditions.dart
│   │   │       ├── step_allergens.dart
│   │   │       ├── step_concerns.dart
│   │   │       └── onboarding_complete.dart
│   │   ├── scan/
│   │   │   ├── providers/scan_provider.dart
│   │   │   └── screens/
│   │   │       ├── camera_screen.dart
│   │   │       ├── verify_product_screen.dart
│   │   │       ├── manual_entry_screen.dart
│   │   │       ├── analyzing_screen.dart
│   │   │       └── result_screen.dart
│   │   ├── discovery/
│   │   │   ├── providers/search_provider.dart
│   │   │   └── screens/
│   │   │       ├── home_screen.dart
│   │   │       ├── search_screen.dart
│   │   │       ├── product_detail_screen.dart
│   │   │       └── ingredient_detail_screen.dart
│   │   └── account/
│   │       ├── providers/profile_provider.dart
│   │       └── screens/
│   │           ├── profile_screen.dart
│   │           ├── history_screen.dart
│   │           └── settings_screen.dart
│   └── shared/
│       └── widgets/
│           ├── safety_badge.dart        # traffic-light badge widget
│           ├── ingredient_chip.dart
│           └── loading_overlay.dart
└── test/
    └── ...
```

---

## Task 1: Flutter Project Scaffold + Theme + Config

**Files:**
- Create: `pubspec.yaml`
- Create: `.env`
- Create: `lib/main.dart`
- Create: `lib/config/app_config.dart`
- Create: `lib/core/theme/app_theme.dart`

**Interfaces:**
- Produces: `AppTheme.light()` → `ThemeData`; `AppConfig.supabaseUrl`, `AppConfig.supabaseAnonKey`, `AppConfig.geminiApiKey` (static String)

- [ ] **Step 1: Create the Flutter project**

```powershell
cd D:\AppPureCheck\app_pure_check
flutter create . --org com.purecheck --project-name pure_check --platforms android,ios
```

Expected: Flutter project files created (lib/main.dart, pubspec.yaml, android/, ios/, etc.)

- [ ] **Step 2: Update `pubspec.yaml` with all dependencies**

Replace the generated `pubspec.yaml` with:

```yaml
name: pure_check
description: AI-powered cosmetic ingredient analyzer for Thai users
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.12.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Navigation
  go_router: ^14.8.1

  # Supabase
  supabase_flutter: ^2.9.0

  # AI
  google_generative_ai: ^0.4.6

  # Barcode scanner
  mobile_scanner: ^6.0.5

  # HTTP
  http: ^1.2.2

  # UI
  google_fonts: ^6.2.1
  lottie: ^3.1.2
  cached_network_image: ^3.4.1

  # Config
  flutter_dotenv: ^5.2.1

  # Utils
  shared_preferences: ^2.3.3
  intl: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  riverpod_generator: ^2.6.1
  build_runner: ^2.4.13
  json_serializable: ^6.8.0

flutter:
  uses-material-design: true
  assets:
    - .env
  generate: true
```

- [ ] **Step 3: Create `.env` file**

Create `D:\AppPureCheck\app_pure_check\.env`:
```
SUPABASE_URL=<SUPABASE_URL>
SUPABASE_ANON_KEY=<SUPABASE_ANON_KEY>
GEMINI_API_KEY=<GEMINI_API_KEY>
```

- [ ] **Step 4: Create `lib/config/app_config.dart`**

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
```

- [ ] **Step 5: Create `lib/core/theme/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Safety traffic-light
  static const safe = Color(0xFF4CAF82);
  static const caution = Color(0xFFF5A623);
  static const danger = Color(0xFFE53935);

  // Brand
  static const primary = Color(0xFF6DBF9E);
  static const primaryDark = Color(0xFF4A9E7F);
  static const mintBg = Color(0xFFE8F5EE);
  static const surface = Color(0xFFF7FBF8);
  static const white = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF1A2E22);
  static const textSecondary = Color(0xFF6B8C75);
  static const textHint = Color(0xFFAAC4B0);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.notoSansThaiTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.notoSansThai(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.notoSansThai(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.notoSansThai(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.notoSansThai(
          fontSize: 16, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.notoSansThai(
          fontSize: 14, color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.notoSansThai(
          fontSize: 12, color: AppColors.textHint,
        ),
      ),
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.notoSansThai(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.mintBg),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Update `lib/main.dart`** (minimal — router not wired yet, just theme + dotenv init)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: PureCheckApp()));
}

class PureCheckApp extends StatelessWidget {
  const PureCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PureCheck',
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(child: Text('PureCheck — Loading...')),
      ),
    );
  }
}
```

- [ ] **Step 7: Run `flutter pub get` and verify it builds**

```powershell
cd D:\AppPureCheck\app_pure_check
flutter pub get
flutter analyze
```

Expected: No errors. Warnings OK.

- [ ] **Step 8: Commit**

```powershell
git add -A
git commit -m "feat: project scaffold with theme, config, Supabase init"
```

---

## Task 2: Data Models + Core Services

**Files:**
- Create: `lib/core/models/user_profile.dart`
- Create: `lib/core/models/allergen.dart`
- Create: `lib/core/models/product.dart`
- Create: `lib/core/models/analysis_result.dart`
- Create: `lib/core/services/supabase_service.dart`
- Create: `lib/core/services/beauty_facts_service.dart`
- Create: `lib/core/services/gemini_service.dart`

**Interfaces:**
- Consumes: `AppConfig.supabaseUrl/anonKey/geminiApiKey`
- Produces:
  - `UserProfile.fromJson(Map)`, `UserProfile.toJson()`, `UserProfile.empty()`
  - `Allergen.fromJson(Map)`, `Allergen.toJson()`
  - `Product.fromJson(Map)`, `Product.toJson()`
  - `AnalysisResult.fromJson(Map)`, enum `SafetyLevel { safe, caution, danger }`
  - `SupabaseService` — singleton, methods: `getProfile(userId)`, `upsertProfile(profile)`, `getAllergens(userId)`, `addAllergen(allergen)`, `deleteAllergen(id)`, `getProductByBarcode(barcode)`, `upsertProduct(product)`, `addScanHistory(userId, productId, result)`, `getScanHistory(userId)`
  - `BeautyFactsService.fetchByBarcode(barcode)` → `Product?`
  - `GeminiService.analyzeIngredients(profile, allergens, ingredients)` → `AnalysisResult`

- [ ] **Step 1: Create `lib/core/models/user_profile.dart`**

```dart
enum SkinType { oily, dry, combination, normal, sensitive }

extension SkinTypeX on SkinType {
  String get labelTh {
    switch (this) {
      case SkinType.oily: return 'มัน';
      case SkinType.dry: return 'แห้ง';
      case SkinType.combination: return 'ผสม';
      case SkinType.normal: return 'ธรรมดา';
      case SkinType.sensitive: return 'แพ้ง่าย';
    }
  }
  String get value => name;
  static SkinType fromString(String s) =>
      SkinType.values.firstWhere((e) => e.name == s, orElse: () => SkinType.normal);
}

class UserProfile {
  final String id;
  final SkinType skinType;
  final List<String> skinConditions;
  final List<String> skinConcerns;
  final List<String> avoidPreferences;
  final bool onboardingComplete;

  const UserProfile({
    required this.id,
    required this.skinType,
    this.skinConditions = const [],
    this.skinConcerns = const [],
    this.avoidPreferences = const [],
    this.onboardingComplete = false,
  });

  factory UserProfile.empty(String id) => UserProfile(
        id: id,
        skinType: SkinType.normal,
        onboardingComplete: false,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        skinType: SkinTypeX.fromString(json['skin_type'] as String? ?? 'normal'),
        skinConditions: List<String>.from(json['skin_conditions'] ?? []),
        skinConcerns: List<String>.from(json['skin_concerns'] ?? []),
        avoidPreferences: List<String>.from(json['avoid_preferences'] ?? []),
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'skin_type': skinType.value,
        'skin_conditions': skinConditions,
        'skin_concerns': skinConcerns,
        'avoid_preferences': avoidPreferences,
        'onboarding_complete': onboardingComplete,
      };

  UserProfile copyWith({
    SkinType? skinType,
    List<String>? skinConditions,
    List<String>? skinConcerns,
    List<String>? avoidPreferences,
    bool? onboardingComplete,
  }) => UserProfile(
        id: id,
        skinType: skinType ?? this.skinType,
        skinConditions: skinConditions ?? this.skinConditions,
        skinConcerns: skinConcerns ?? this.skinConcerns,
        avoidPreferences: avoidPreferences ?? this.avoidPreferences,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );
}
```

- [ ] **Step 2: Create `lib/core/models/allergen.dart`**

```dart
enum AllergenSeverity { mild, moderate, severe }
enum AllergenSource { known, suspected }

class Allergen {
  final String id;
  final String userId;
  final String ingredientName;
  final List<String> reactionSymptoms;
  final AllergenSeverity severity;
  final AllergenSource source;

  const Allergen({
    required this.id,
    required this.userId,
    required this.ingredientName,
    this.reactionSymptoms = const [],
    this.severity = AllergenSeverity.mild,
    this.source = AllergenSource.known,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) => Allergen(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        ingredientName: json['ingredient_name'] as String,
        reactionSymptoms: List<String>.from(json['reaction_symptoms'] ?? []),
        severity: AllergenSeverity.values.firstWhere(
          (e) => e.name == (json['severity'] ?? 'mild'),
          orElse: () => AllergenSeverity.mild,
        ),
        source: AllergenSource.values.firstWhere(
          (e) => e.name == (json['source'] ?? 'known'),
          orElse: () => AllergenSource.known,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'ingredient_name': ingredientName,
        'reaction_symptoms': reactionSymptoms,
        'severity': severity.name,
        'source': source.name,
      };
}
```

- [ ] **Step 3: Create `lib/core/models/product.dart`**

```dart
enum ProductSource { local, openBeautyFacts, userEntered }

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
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        barcode: json['barcode'] as String?,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        ingredients: List<String>.from(json['ingredients'] ?? []),
        rawIngredientsText: json['raw_ingredients_text'] as String?,
        source: ProductSource.values.firstWhere(
          (e) => e.name == (json['source'] ?? 'local'),
          orElse: () => ProductSource.local,
        ),
        verifiedCount: json['verified_count'] as int? ?? 0,
        imageUrl: json['image_url'] as String?,
      );

  factory Product.fromOpenBeautyFacts(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final ingredientsText = product['ingredients_text'] as String? ?? '';
    final ingredients = ingredientsText
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return Product(
      id: '',
      barcode: product['code'] as String? ?? json['code'] as String?,
      name: product['product_name'] as String? ?? 'Unknown Product',
      brand: product['brands'] as String?,
      ingredients: ingredients,
      rawIngredientsText: ingredientsText,
      source: ProductSource.openBeautyFacts,
      imageUrl: product['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'ingredients': ingredients,
        'raw_ingredients_text': rawIngredientsText,
        'source': source.name,
        'image_url': imageUrl,
      };

  Product copyWith({String? id, List<String>? ingredients, String? name, String? brand}) =>
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
      );
}
```

- [ ] **Step 4: Create `lib/core/models/analysis_result.dart`**

```dart
enum SafetyLevel { safe, caution, danger }

extension SafetyLevelX on SafetyLevel {
  String get labelTh {
    switch (this) {
      case SafetyLevel.safe: return 'ปลอดภัย';
      case SafetyLevel.caution: return 'ควรระวัง';
      case SafetyLevel.danger: return 'พบสารที่แพ้';
    }
  }
  static SafetyLevel fromString(String s) => SafetyLevel.values.firstWhere(
        (e) => e.name == s,
        orElse: () => SafetyLevel.caution,
      );
}

class FlaggedIngredient {
  final String name;
  final String reason;
  final SafetyLevel riskLevel;

  const FlaggedIngredient({
    required this.name,
    required this.reason,
    required this.riskLevel,
  });

  factory FlaggedIngredient.fromJson(Map<String, dynamic> json) => FlaggedIngredient(
        name: json['name'] as String,
        reason: json['reason'] as String,
        riskLevel: SafetyLevelX.fromString(json['risk_level'] as String? ?? 'caution'),
      );
}

class IngredientBreakdown {
  final String name;
  final String? function;
  final SafetyLevel riskLevel;

  const IngredientBreakdown({
    required this.name,
    this.function,
    required this.riskLevel,
  });

  factory IngredientBreakdown.fromJson(Map<String, dynamic> json) => IngredientBreakdown(
        name: json['name'] as String,
        function: json['function'] as String?,
        riskLevel: SafetyLevelX.fromString(json['risk_level'] as String? ?? 'safe'),
      );
}

class AnalysisResult {
  final SafetyLevel overallSafety;
  final String summaryTh;
  final String summaryEn;
  final List<FlaggedIngredient> flaggedIngredients;
  final List<IngredientBreakdown> ingredientBreakdown;

  const AnalysisResult({
    required this.overallSafety,
    required this.summaryTh,
    required this.summaryEn,
    this.flaggedIngredients = const [],
    this.ingredientBreakdown = const [],
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        overallSafety: SafetyLevelX.fromString(json['overall_safety'] as String? ?? 'caution'),
        summaryTh: json['summary_th'] as String? ?? '',
        summaryEn: json['summary_en'] as String? ?? '',
        flaggedIngredients: (json['flagged_ingredients'] as List<dynamic>? ?? [])
            .map((e) => FlaggedIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        ingredientBreakdown: (json['ingredient_breakdown'] as List<dynamic>? ?? [])
            .map((e) => IngredientBreakdown.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'overall_safety': overallSafety.name,
        'summary_th': summaryTh,
        'summary_en': summaryEn,
        'flagged_ingredients': flaggedIngredients
            .map((e) => {'name': e.name, 'reason': e.reason, 'risk_level': e.riskLevel.name})
            .toList(),
        'ingredient_breakdown': ingredientBreakdown
            .map((e) => {'name': e.name, 'function': e.function, 'risk_level': e.riskLevel.name})
            .toList(),
      };
}
```

- [ ] **Step 5: Create `lib/core/services/supabase_service.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Profile
  Future<UserProfile?> getProfile(String userId) async {
    final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (res == null) return null;
    return UserProfile.fromJson(res);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await _client.from('profiles').upsert(profile.toJson());
  }

  // Allergens
  Future<List<Allergen>> getAllergens(String userId) async {
    final res = await _client.from('user_allergens').select().eq('user_id', userId);
    return (res as List).map((e) => Allergen.fromJson(e)).toList();
  }

  Future<void> addAllergen(Allergen allergen) async {
    final data = allergen.toJson();
    data.remove('id'); // let DB generate
    await _client.from('user_allergens').insert(data);
  }

  Future<void> deleteAllergen(String id) async {
    await _client.from('user_allergens').delete().eq('id', id);
  }

  // Products
  Future<Product?> getProductByBarcode(String barcode) async {
    final res = await _client.from('products').select().eq('barcode', barcode).maybeSingle();
    if (res == null) return null;
    return Product.fromJson(res);
  }

  Future<Product> upsertProduct(Product product) async {
    final data = product.toJson();
    final res = await _client.from('products').upsert(data, onConflict: 'barcode').select().single();
    return Product.fromJson(res);
  }

  Future<List<Product>> searchProducts(String query) async {
    final res = await _client
        .from('products')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    return (res as List).map((e) => Product.fromJson(e)).toList();
  }

  // Scan history
  Future<void> addScanHistory({
    required String userId,
    required String productId,
    required AnalysisResult result,
  }) async {
    await _client.from('scan_history').insert({
      'user_id': userId,
      'product_id': productId,
      'safety_level': result.overallSafety.name,
      'ai_analysis': result.toJson(),
    });
  }

  Future<List<Map<String, dynamic>>> getScanHistory(String userId) async {
    final res = await _client
        .from('scan_history')
        .select('*, products(*)')
        .eq('user_id', userId)
        .order('scanned_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  }
}
```

- [ ] **Step 6: Create `lib/core/services/beauty_facts_service.dart`**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class BeautyFactsService {
  static const _baseUrl = 'https://world.openbeautyfacts.org/api/v2/product';

  Future<Product?> fetchByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 1) return null;
      return Product.fromOpenBeautyFacts(json);
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 7: Create `lib/core/services/gemini_service.dart`**

```dart
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/app_config.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../models/analysis_result.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }

  Future<AnalysisResult> analyzeIngredients({
    required UserProfile profile,
    required List<Allergen> allergens,
    required List<String> ingredients,
  }) async {
    final allergenNames = allergens.map((a) => a.ingredientName).join(', ');
    final prompt = '''
Analyze these cosmetic/skincare product ingredients for a user with the following profile:
- Skin type: ${profile.skinType.value}
- Skin conditions: ${profile.skinConditions.join(', ')}
- Known allergens: $allergenNames
- Skin concerns: ${profile.skinConcerns.join(', ')}
- Ingredients to avoid (preference): ${profile.avoidPreferences.join(', ')}

Product ingredients list: ${ingredients.join(', ')}

Return ONLY valid JSON in this exact format:
{
  "overall_safety": "safe|caution|danger",
  "summary_th": "คำอธิบายภาษาไทย 2-3 ประโยค",
  "summary_en": "English explanation 2-3 sentences",
  "flagged_ingredients": [
    {"name": "ingredient name", "reason": "why flagged", "risk_level": "caution|danger"}
  ],
  "ingredient_breakdown": [
    {"name": "ingredient name", "function": "what it does", "risk_level": "safe|caution|danger"}
  ]
}

Rules:
- overall_safety = "danger" if any known allergen is found
- overall_safety = "caution" if concerning ingredients found but no known allergens
- overall_safety = "safe" if no allergens and no significant concerns
- List ALL ingredients in ingredient_breakdown
- Only flag ingredients that are genuinely concerning for this user's profile
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return AnalysisResult.fromJson(json);
    } catch (_) {
      return const AnalysisResult(
        overallSafety: SafetyLevel.caution,
        summaryTh: 'ไม่สามารถวิเคราะห์ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
        summaryEn: 'Unable to analyze at this time. Please try again.',
      );
    }
  }
}
```

- [ ] **Step 8: Run `flutter analyze`**

```powershell
cd D:\AppPureCheck\app_pure_check
flutter analyze
```

Expected: No errors (warnings about unused imports OK for now)

- [ ] **Step 9: Commit**

```powershell
git add -A
git commit -m "feat: data models and core services (Supabase, Gemini, OpenBeautyFacts)"
```

---

## Task 3: Router + Auth Screens

**Files:**
- Create: `lib/core/router/app_router.dart`
- Create: `lib/features/auth/providers/auth_provider.dart`
- Create: `lib/features/auth/screens/splash_screen.dart`
- Create: `lib/features/auth/screens/intro_screen.dart`
- Create: `lib/features/auth/screens/login_screen.dart`
- Create: `lib/features/auth/screens/register_screen.dart`
- Modify: `lib/main.dart` (wire up router)

**Interfaces:**
- Consumes: `AppTheme.light()`, `SupabaseService`, `UserProfile`
- Produces: `AppRouter.router` (GoRouter), `authProvider` (StreamProvider<User?>), `currentUserProvider`

- [ ] **Step 1: Create `lib/features/auth/providers/auth_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.read(supabaseServiceProvider);
  return service.getProfile(user.id);
});
```

- [ ] **Step 2: Create `lib/core/router/app_router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/intro_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/onboarding/screens/onboarding_shell.dart';
import '../../features/discovery/screens/home_screen.dart';
import '../../features/scan/screens/camera_screen.dart';
import '../../features/scan/screens/result_screen.dart';
import '../../features/discovery/screens/search_screen.dart';
import '../../features/account/screens/profile_screen.dart';
import '../../features/account/screens/history_screen.dart';
import '../../features/account/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = Supabase.instance.client.auth.currentUser;
      final publicRoutes = ['/splash', '/intro', '/login', '/register'];
      final isPublic = publicRoutes.any((r) => state.matchedLocation.startsWith(r));

      if (user == null && !isPublic) return '/login';

      if (user != null && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/intro', builder: (_, __) => const IntroScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingShell()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/scan', builder: (_, __) => const CameraScreen()),
      GoRoute(
        path: '/result',
        builder: (_, state) => ResultScreen(extra: state.extra),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
```

- [ ] **Step 3: Create placeholder screen files** (stubs so router compiles)

Create each with minimal content. For example `lib/features/auth/screens/splash_screen.dart`:

```dart
// lib/features/auth/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/intro');
    } else {
      // Check profile completeness
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 56),
            ),
            const SizedBox(height: 24),
            Text('PureCheck',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.white)),
            const SizedBox(height: 8),
            Text('วิเคราะห์ส่วนผสม รู้ก่อนแพ้',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}
```

Create stubs for all other missing screens (IntroScreen, LoginScreen, RegisterScreen, OnboardingShell, HomeScreen, CameraScreen, ResultScreen, SearchScreen, ProfileScreen, HistoryScreen, SettingsScreen) — each just a `Scaffold(appBar: AppBar(title: Text('...')), body: const Center(child: Text('Coming soon')))`.

- [ ] **Step 4: Build full `LoginScreen`**

```dart
// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text('ยินดีต้อนรับกลับ', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('เข้าสู่ระบบเพื่อใช้งาน PureCheck',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'อีเมล', hintText: 'example@email.com'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('เข้าสู่ระบบ'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Build full `RegisterScreen`** (same pattern as Login but calls `signUp`)

```dart
// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'รหัสผ่านไม่ตรงกัน');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/onboarding');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text('สร้างบัญชีใหม่', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('สมัครสมาชิกเพื่อเริ่มวิเคราะห์ส่วนผสม',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'อีเมล'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่าน'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('สมัครสมาชิก'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Build `IntroScreen`**

```dart
// lib/features/auth/screens/intro_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class _Slide {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Slide(this.title, this.subtitle, this.icon);
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    _Slide('สแกนแล้วรู้ว่าแพ้ไหม', 'สแกนบาร์โค้ดผลิตภัณฑ์ รู้ส่วนผสมทันที', Icons.qr_code_scanner_rounded),
    _Slide('AI วิเคราะห์เฉพาะคุณ', 'ผลวิเคราะห์ปรับตามโปรไฟล์ผิวและประวัติการแพ้ของคุณ', Icons.auto_awesome_rounded),
    _Slide('ส่วนผสมครบ ตรงไปตรงมา', 'ข้อมูลส่วนผสมชัดเจน พร้อมคำอธิบายเข้าใจง่าย', Icons.science_rounded),
  ];

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(s.icon, size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(s.title,
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(s.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.textHint,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => context.go('/register'),
                child: const Text('เริ่มต้นใช้งาน'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Update `main.dart` to use router**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: PureCheckApp()));
}

class PureCheckApp extends ConsumerWidget {
  const PureCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'PureCheck',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 8: Run flutter analyze and verify build**

```powershell
flutter analyze
flutter build apk --debug 2>&1 | head -30
```

- [ ] **Step 9: Commit**

```powershell
git add -A
git commit -m "feat: router with auth guard, splash/intro/login/register screens"
```

---

## Task 4: Onboarding Questionnaire (4 Steps)

**Files:**
- Create: `lib/features/onboarding/providers/onboarding_provider.dart`
- Create: `lib/features/onboarding/screens/onboarding_shell.dart`
- Create: `lib/features/onboarding/screens/step_skin_type.dart`
- Create: `lib/features/onboarding/screens/step_skin_conditions.dart`
- Create: `lib/features/onboarding/screens/step_allergens.dart`
- Create: `lib/features/onboarding/screens/step_concerns.dart`
- Create: `lib/features/onboarding/screens/onboarding_complete.dart`

**Interfaces:**
- Consumes: `UserProfile`, `SkinType`, `SupabaseService`, `Allergen`
- Produces: Completed `UserProfile` saved to Supabase, user navigated to `/home` on finish

Step details: multi-step stepper with progress bar, tap-to-select cards for skin type, multi-select chips for conditions, allergen search+add with symptom tags, skippable concerns step. All writes go to Supabase via `SupabaseService.upsertProfile()` on completion.

---

## Task 5: Home Screen + Shared Widgets

**Files:**
- Create: `lib/shared/widgets/safety_badge.dart`
- Create: `lib/shared/widgets/ingredient_chip.dart`
- Create: `lib/shared/widgets/loading_overlay.dart`
- Create: `lib/features/discovery/screens/home_screen.dart`

**Interfaces:**
- Produces: `SafetyBadge(level: SafetyLevel)`, `IngredientChip(name, riskLevel)`, `HomeScreen` with large scan FAB, search bar, recent scans carousel

---

## Task 6: Camera + Scan Flow

**Files:**
- Create: `lib/features/scan/providers/scan_provider.dart`
- Create: `lib/features/scan/screens/camera_screen.dart`
- Create: `lib/features/scan/screens/verify_product_screen.dart`
- Create: `lib/features/scan/screens/manual_entry_screen.dart`
- Create: `lib/features/scan/screens/analyzing_screen.dart`

**Interfaces:**
- Consumes: `SupabaseService`, `BeautyFactsService`, `GeminiService`, `UserProfile`, `List<Allergen>`
- Produces: `ScanProvider` (AsyncNotifier) — state transitions: idle → scanning → verifying → fetching → analyzing → done; navigates to `/result` on success

---

## Task 7: Result Screen ⭐

**Files:**
- Create: `lib/features/scan/screens/result_screen.dart`

**Interfaces:**
- Consumes: `AnalysisResult`, `Product`, `List<Allergen>` (passed via GoRouter extra)
- Produces: ResultScreen displaying traffic-light banner, flagged allergens (red cards), AI summary, grouped ingredient list (danger/caution/safe), "Report Allergy" button → adds to user allergens, auto-saves to scan_history

---

## Task 8: Search + Discovery Screens

**Files:**
- Create: `lib/features/discovery/providers/search_provider.dart`
- Create: `lib/features/discovery/screens/search_screen.dart`
- Create: `lib/features/discovery/screens/product_detail_screen.dart`
- Create: `lib/features/discovery/screens/ingredient_detail_screen.dart`

**Interfaces:**
- Consumes: `SupabaseService.searchProducts()`, `BeautyFactsService`
- Produces: Debounced search (300ms), product/ingredient tabs, detail screens with "Analyze for my profile" button

---

## Task 9: Profile, History, Settings

**Files:**
- Create: `lib/features/account/providers/profile_provider.dart`
- Create: `lib/features/account/screens/profile_screen.dart`
- Create: `lib/features/account/screens/history_screen.dart`
- Create: `lib/features/account/screens/settings_screen.dart`

**Interfaces:**
- Consumes: `SupabaseService`, `UserProfile`, `Allergen`
- Produces: Editable profile (skin type, conditions, concerns), allergen management (add/remove), scan history list with safety badges, settings with language toggle + sign out

---

## Task 10: Localization (Thai + English) + Supabase DB Migration

**Files:**
- Create: `lib/l10n.yaml`
- Create: `lib/core/l10n/app_en.arb`
- Create: `lib/core/l10n/app_th.arb`
- Create: `docs/superpowers/specs/supabase-migration.sql`

**Interfaces:**
- Produces: All UI strings available in both Thai and English, language toggle working in Settings, Supabase SQL migration ready to run

The SQL migration creates all 4 tables (profiles, user_allergens, products, scan_history) with RLS policies as defined in the design spec.
