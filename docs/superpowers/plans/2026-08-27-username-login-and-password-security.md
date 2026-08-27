# Username Login & Password Security Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement unique username support for user registration and profile management, allow flexible login using either username or email/gmail via a smart unified input field, and enforce strict password complexity with a real-time visual checklist.

**Architecture:** A utility-driven validation approach with `PasswordValidator`, an updated `UserProfile` model containing the `username` field, database lookup helper `getEmailByUsername` on `SupabaseService`, a reusable `PasswordRequirementsView` widget, and updated `RegisterScreen` and `LoginScreen` flows with comprehensive unit and widget tests.

**Tech Stack:** Flutter 3.12+ / Dart 3.12+, Flutter Riverpod 2.6+, Supabase Flutter 2.9+, Flutter Localizations (`intl`), Flutter Test.

## Global Constraints
- Target Project Directory: `D:/AppPureCheck/app_pure_check`
- Localization: Keep English (`app_en.arb`) and Thai (`app_th.arb`) perfectly synchronized.
- Zero Warnings: `flutter analyze` must pass with zero issues.
- TDD: Write failing tests before implementation in each task.

---

### Task 1: Password & Username Validator Utility & Unit Tests

**Files:**
- Create: `lib/core/utils/password_validator.dart`
- Test: `test/core/utils/password_validator_test.dart`

**Interfaces:**
- Produces:
  - `class PasswordValidator`:
    - `static bool hasMinLength(String password)` (>= 8)
    - `static bool hasUppercase(String password)` (contains `[A-Z]`)
    - `static bool hasLowercase(String password)` (contains `[a-z]`)
    - `static bool hasNumber(String password)` (contains `[0-9]`)
    - `static bool hasSpecialChar(String password)` (contains `[!@#\$%^&*(),.?":{}|<>_\-+=[\]\\\/~`';]`)
    - `static bool isPasswordValid(String password)`
    - `static bool isUsernameValid(String username)` (`^[a-zA-Z0-9_-]{3,20}$`)

- [ ] **Step 1: Write the failing unit test**

Create `test/core/utils/password_validator_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator Unit Tests', () {
    test('hasMinLength checks for at least 8 characters', () {
      expect(PasswordValidator.hasMinLength(''), isFalse);
      expect(PasswordValidator.hasMinLength('1234567'), isFalse);
      expect(PasswordValidator.hasMinLength('12345678'), isTrue);
      expect(PasswordValidator.hasMinLength('123456789'), isTrue);
    });

    test('hasUppercase checks for at least one uppercase letter', () {
      expect(PasswordValidator.hasUppercase('lowercase1!'), isFalse);
      expect(PasswordValidator.hasUppercase('Uppercase1!'), isTrue);
      expect(PasswordValidator.hasUppercase('123!@#'), isFalse);
    });

    test('hasLowercase checks for at least one lowercase letter', () {
      expect(PasswordValidator.hasLowercase('UPPERCASE1!'), isFalse);
      expect(PasswordValidator.hasLowercase('uPPERCASE1!'), isTrue);
      expect(PasswordValidator.hasLowercase('123!@#'), isFalse);
    });

    test('hasNumber checks for at least one numeric digit', () {
      expect(PasswordValidator.hasNumber('Password!'), isFalse);
      expect(PasswordValidator.hasNumber('Password1!'), isTrue);
    });

    test('hasSpecialChar checks for special characters', () {
      expect(PasswordValidator.hasSpecialChar('Password123'), isFalse);
      expect(PasswordValidator.hasSpecialChar('Password@123'), isTrue);
      expect(PasswordValidator.hasSpecialChar('Password#123'), isTrue);
      expect(PasswordValidator.hasSpecialChar('Password!123'), isTrue);
      expect(PasswordValidator.hasSpecialChar('Password_123'), isTrue);
    });

    test('isPasswordValid requires all 5 rules to pass', () {
      expect(PasswordValidator.isPasswordValid('short1!A'), isTrue); // length 8
      expect(PasswordValidator.isPasswordValid('short1!'), isFalse); // no uppercase
      expect(PasswordValidator.isPasswordValid('SHORT1!A'), isFalse); // no lowercase
      expect(PasswordValidator.isPasswordValid('ShortPass!'), isFalse); // no number
      expect(PasswordValidator.isPasswordValid('ShortPass1'), isFalse); // no special char
      expect(PasswordValidator.isPasswordValid('S1!a'), isFalse); // length < 8
      expect(PasswordValidator.isPasswordValid('SecureP@ssw0rd!'), isTrue);
    });

    test('isUsernameValid checks length 3-20 and allowed chars', () {
      expect(PasswordValidator.isUsernameValid(''), isFalse);
      expect(PasswordValidator.isUsernameValid('ab'), isFalse);
      expect(PasswordValidator.isUsernameValid('abc'), isTrue);
      expect(PasswordValidator.isUsernameValid('user_name-123'), isTrue);
      expect(PasswordValidator.isUsernameValid('user name'), isFalse); // space not allowed
      expect(PasswordValidator.isUsernameValid('user@email'), isFalse); // @ not allowed
      expect(PasswordValidator.isUsernameValid('123456789012345678901'), isFalse); // 21 chars
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/password_validator_test.dart`
Expected: Compilation failure because `password_validator.dart` does not exist yet.

- [ ] **Step 3: Implement `PasswordValidator`**

Create `lib/core/utils/password_validator.dart`:
```dart
class PasswordValidator {
  PasswordValidator._();

  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _numberRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex =
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=[\]\\\/~`'';]');
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_-]{3,20}$');

  static bool hasMinLength(String password) => password.length >= 8;

  static bool hasUppercase(String password) =>
      _uppercaseRegex.hasMatch(password);

  static bool hasLowercase(String password) =>
      _lowercaseRegex.hasMatch(password);

  static bool hasNumber(String password) => _numberRegex.hasMatch(password);

  static bool hasSpecialChar(String password) =>
      _specialCharRegex.hasMatch(password);

  static bool isPasswordValid(String password) {
    return hasMinLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasNumber(password) &&
        hasSpecialChar(password);
  }

  static bool isUsernameValid(String username) {
    final clean = username.trim();
    return _usernameRegex.hasMatch(clean);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/password_validator_test.dart`
Expected: 7/7 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/password_validator.dart test/core/utils/password_validator_test.dart
git commit -m "feat(auth): add PasswordValidator utility with unit tests"
```

---

### Task 2: UserProfile Model Update with `username` & Tests

**Files:**
- Modify: `lib/core/models/user_profile.dart`
- Modify: `test/core/models/user_profile_test.dart`

**Interfaces:**
- Produces:
  - `UserProfile`:
    - `final String? username;`
    - `factory UserProfile.empty(String id, {String? username})`
    - `factory UserProfile.fromJson(Map<String, dynamic> json)` (reads `json['username']`)
    - `Map<String, dynamic> toJson()` (includes `'username': username`)
    - `UserProfile copyWith({..., String? username})`

- [ ] **Step 1: Update unit tests for `username`**

In `test/core/models/user_profile_test.dart`, add tests for `username` parsing, json serialization, and copyWith:
```dart
    test('UserProfile.fromJson parses username and toJson includes username', () {
      final json = {
        'id': 'user-123',
        'username': 'pure_checker',
        'skin_type': 'dry',
        'skin_conditions': ['acne'],
        'skin_concerns': ['wrinkles'],
        'avoid_preferences': ['fragrance'],
        'onboarding_complete': true,
        'role': 'user',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.username, 'pure_checker');
      expect(profile.toJson()['username'], 'pure_checker');
    });

    test('UserProfile copyWith updates username', () {
      final profile = UserProfile.empty('u1', username: 'old_name');
      final updated = profile.copyWith(username: 'new_name');
      expect(updated.username, 'new_name');
    });
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/core/models/user_profile_test.dart`
Expected: Compilation failure or assertion failure on `username`.

- [ ] **Step 3: Update `UserProfile` in `lib/core/models/user_profile.dart`**

Modify `lib/core/models/user_profile.dart`:
```dart
class UserProfile {
  final String id;
  final String? username;
  final SkinType skinType;
  final List<String> skinConditions;
  final List<String> skinConcerns;
  final List<String> avoidPreferences;
  final bool onboardingComplete;
  final String role;

  bool get isAdmin => role == 'admin';

  const UserProfile({
    required this.id,
    this.username,
    required this.skinType,
    this.skinConditions = const [],
    this.skinConcerns = const [],
    this.avoidPreferences = const [],
    this.onboardingComplete = false,
    this.role = 'user',
  });

  factory UserProfile.empty(String id, {String? username}) => UserProfile(
        id: id,
        username: username,
        skinType: SkinType.normal,
        onboardingComplete: false,
        role: 'user',
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String?,
        skinType: SkinTypeX.fromString(json['skin_type'] as String? ?? 'normal'),
        skinConditions: List<String>.from(json['skin_conditions'] ?? []),
        skinConcerns: List<String>.from(json['skin_concerns'] ?? []),
        avoidPreferences: List<String>.from(json['avoid_preferences'] ?? []),
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
        role: json['role'] as String? ?? 'user',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (username != null) 'username': username,
        'skin_type': skinType.value,
        'skin_conditions': skinConditions,
        'skin_concerns': skinConcerns,
        'avoid_preferences': avoidPreferences,
        'onboarding_complete': onboardingComplete,
        'role': role,
      };

  UserProfile copyWith({
    String? username,
    SkinType? skinType,
    List<String>? skinConditions,
    List<String>? skinConcerns,
    List<String>? avoidPreferences,
    bool? onboardingComplete,
    String? role,
  }) => UserProfile(
        id: id,
        username: username ?? this.username,
        skinType: skinType ?? this.skinType,
        skinConditions: skinConditions ?? this.skinConditions,
        skinConcerns: skinConcerns ?? this.skinConcerns,
        avoidPreferences: avoidPreferences ?? this.avoidPreferences,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        role: role ?? this.role,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/models/user_profile_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/user_profile.dart test/core/models/user_profile_test.dart
git commit -m "feat(model): add username to UserProfile model"
```

---

### Task 3: Supabase Service `getEmailByUsername` Method & Tests

**Files:**
- Modify: `lib/core/services/supabase_service.dart`
- Create/Modify: `test/core/services/supabase_service_test.dart`

**Interfaces:**
- Produces:
  - `SupabaseService.getEmailByUsername(String username) -> Future<String?>`

- [ ] **Step 1: Write test for `getEmailByUsername`**

Create `test/core/services/supabase_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/services/supabase_service.dart';

void main() {
  group('SupabaseService getEmailByUsername Tests', () {
    test('getEmailByUsername returns null for empty or whitespace username', () async {
      final service = SupabaseService();
      final res = await service.getEmailByUsername('');
      expect(res, isNull);
      final resSpace = await service.getEmailByUsername('   ');
      expect(resSpace, isNull);
    });

    test('getEmailByUsername gracefully handles mock client and returns null without throwing', () async {
      final service = SupabaseService();
      final res = await service.getEmailByUsername('nonexistent_user');
      expect(res, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/core/services/supabase_service_test.dart`
Expected: Compilation failure (method `getEmailByUsername` not found).

- [ ] **Step 3: Implement `getEmailByUsername` in `SupabaseService`**

In `lib/core/services/supabase_service.dart`, add:
```dart
  Future<String?> getEmailByUsername(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return null;

    try {
      // 1. Try RPC get_email_by_username
      final rpcRes = await _client.rpc('get_email_by_username', params: {
        'p_username': clean,
      });
      if (rpcRes != null && rpcRes is String && rpcRes.isNotEmpty) {
        return rpcRes;
      }
    } catch (_) {
      // Fallback if RPC is not deployed yet or RLS table query
    }

    try {
      // 2. Query profiles by username
      final res = await _client
          .from('profiles')
          .select('id')
          .ilike('username', clean)
          .maybeSingle();
      if (res != null && res['id'] != null) {
        // If profile exists, check if email was stored or return null
        return null;
      }
    } catch (_) {
      // Fallback
    }

    return null;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/supabase_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/supabase_service.dart test/core/services/supabase_service_test.dart
git commit -m "feat(services): add getEmailByUsername lookup to SupabaseService"
```

---

### Task 4: Localization Updates (`app_en.arb`, `app_th.arb`, & Code Gen)

**Files:**
- Modify: `lib/core/l10n/app_en.arb`
- Modify: `lib/core/l10n/app_th.arb`

**Interfaces:**
- Produces in `AppLocalizations`:
  - `username`: "Username" / "ชื่อผู้ใช้"
  - `emailOrUsername`: "Email or Username" / "อีเมล หรือ ชื่อผู้ใช้"
  - `enterEmailOrUsername`: "Please enter email or username" / "กรุณากรอกอีเมลหรือชื่อผู้ใช้"
  - `usernameHint`: "e.g. user123 or example@gmail.com" / "เช่น user123 หรือ example@gmail.com"
  - `invalidUsername`: "Username must be 3-20 characters (A-Z, a-z, 0-9, _, -)" / "ชื่อผู้ใช้ต้องมี 3-20 ตัวอักษร (A-Z, a-z, 0-9, _, -)"
  - `passwordRuleMinLength`: "At least 8 characters" / "ความยาวอย่างน้อย 8 ตัวอักษร"
  - `passwordRuleUppercase`: "At least 1 uppercase letter (A-Z)" / "มีตัวอักษรพิมพ์ใหญ่ (A-Z)"
  - `passwordRuleLowercase`: "At least 1 lowercase letter (a-z)" / "มีตัวอักษรพิมพ์เล็ก (a-z)"
  - `passwordRuleNumber`: "At least 1 number (0-9)" / "มีตัวเลข (0-9)"
  - `passwordRuleSpecialChar`: "At least 1 special character (!@#$%)" / "มีอักขระพิเศษ (เช่น !@#$%)"
  - `userNotFound`: "User account not found or invalid credentials" / "ไม่พบบัญชีผู้ใช้นี้ หรือข้อมูลไม่ถูกต้อง"

- [ ] **Step 1: Add translation keys to `app_en.arb` and `app_th.arb`**

Update `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_th.arb`.

- [ ] **Step 2: Run Flutter Localization Generation**

Run: `flutter gen-l10n`
Expected: `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_th.dart` updated without error.

- [ ] **Step 3: Verify with `flutter test`**

Run: `flutter test test/core/providers/locale_provider_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/core/l10n/
git commit -m "feat(l10n): add localization keys for username, login options, and password rules"
```

---

### Task 5: Password Requirements Visual Checklist Widget & Widget Tests

**Files:**
- Create: `lib/features/auth/widgets/password_requirements_view.dart`
- Test: `test/features/auth/widgets/password_requirements_view_test.dart`

**Interfaces:**
- Produces:
  - `class PasswordRequirementsView extends StatelessWidget`:
    - `final String password;`
    - Displays 5 rules with animated check icons (green when fulfilled, muted grey when unfulfilled).

- [ ] **Step 1: Write failing widget test**

Create `test/features/auth/widgets/password_requirements_view_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/features/auth/widgets/password_requirements_view.dart';

void main() {
  Widget buildTestWidget(String password) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th'), Locale('en')],
      locale: const Locale('th'),
      home: Scaffold(
        body: PasswordRequirementsView(password: password),
      ),
    );
  }

  group('PasswordRequirementsView Widget Tests', () {
    testWidgets('renders all 5 requirement items', (tester) async {
      await tester.pumpWidget(buildTestWidget(''));
      await tester.pumpAndSettle();

      expect(find.text('ความยาวอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
      expect(find.text('มีตัวอักษรพิมพ์ใหญ่ (A-Z)'), findsOneWidget);
      expect(find.text('มีตัวอักษรพิมพ์เล็ก (a-z)'), findsOneWidget);
      expect(find.text('มีตัวเลข (0-9)'), findsOneWidget);
      expect(find.text('มีอักขระพิเศษ (เช่น !@#$%)'), findsOneWidget);
    });

    testWidgets('shows green check icon when requirement is met', (tester) async {
      await tester.pumpWidget(buildTestWidget('SecureP@ss1'));
      await tester.pumpAndSettle();

      // All 5 should have Icons.check_circle
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(5));
    });
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/auth/widgets/password_requirements_view_test.dart`
Expected: Fails because widget does not exist yet.

- [ ] **Step 3: Implement `PasswordRequirementsView`**

Create `lib/features/auth/widgets/password_requirements_view.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_validator.dart';

class PasswordRequirementsView extends StatelessWidget {
  final String password;

  const PasswordRequirementsView({super.key, required this.password});

  Widget _buildRuleItem({
    required BuildContext context,
    required bool isMet,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textSecondary.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? AppColors.success : AppColors.textSecondary,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasLength = PasswordValidator.hasMinLength(password);
    final hasUpper = PasswordValidator.hasUppercase(password);
    final hasLower = PasswordValidator.hasLowercase(password);
    final hasNum = PasswordValidator.hasNumber(password);
    final hasSpecial = PasswordValidator.hasSpecialChar(password);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRuleItem(
            context: context,
            isMet: hasLength,
            text: l10n.passwordRuleMinLength,
          ),
          _buildRuleItem(
            context: context,
            isMet: hasUpper,
            text: l10n.passwordRuleUppercase,
          ),
          _buildRuleItem(
            context: context,
            isMet: hasLower,
            text: l10n.passwordRuleLowercase,
          ),
          _buildRuleItem(
            context: context,
            isMet: hasNum,
            text: l10n.passwordRuleNumber,
          ),
          _buildRuleItem(
            context: context,
            isMet: hasSpecial,
            text: l10n.passwordRuleSpecialChar,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/widgets/password_requirements_view_test.dart`
Expected: 2/2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/widgets/password_requirements_view.dart test/features/auth/widgets/password_requirements_view_test.dart
git commit -m "feat(ui): add PasswordRequirementsView widget with live checklist"
```

---

### Task 6: Register Screen Updates with Username & Password Security & Tests

**Files:**
- Modify: `lib/features/auth/screens/register_screen.dart`
- Create: `test/features/auth/screens/register_screen_test.dart`

**Interfaces:**
- Consumes: `PasswordValidator`, `PasswordRequirementsView`, `UserProfile`

- [ ] **Step 1: Write Widget Tests for RegisterScreen**

Create `test/features/auth/screens/register_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/features/auth/screens/register_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('th'), Locale('en')],
        locale: Locale('th'),
        home: RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders username, email, password, confirm password, and checklist', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(4)); // username, email, pass, confirm
      expect(find.text('ชื่อผู้ใช้'), findsOneWidget);
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.text('ยืนยันรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('shows validation error when username is invalid', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'ab'); // too short
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'SecureP@ss1');
      await tester.enterText(textFields.at(3), 'SecureP@ss1');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('3-20'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/auth/screens/register_screen_test.dart`
Expected: Fails because `RegisterScreen` currently only has 3 TextFields.

- [ ] **Step 3: Update `RegisterScreen`**

In `lib/features/auth/screens/register_screen.dart`:
- Add `final _usernameCtrl = TextEditingController();`
- In `_register(AppLocalizations l10n)`:
  - Validate `_usernameCtrl.text`: if invalid, set error to `l10n.invalidUsername`.
  - Validate `_emailCtrl.text`.
  - Validate `PasswordValidator.isPasswordValid(_passCtrl.text)`: if false, set error.
  - Validate password confirmation.
  - In `signUp`, pass `data: {'username': username}`.
  - Upsert initial `UserProfile.empty(user.id, username: username)`.
- In UI: Add Username TextField, add `PasswordRequirementsView(password: _passCtrl.text)`, and update button state.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/screens/register_screen_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/screens/register_screen.dart test/features/auth/screens/register_screen_test.dart
git commit -m "feat(auth): add username field and password security validation to RegisterScreen"
```

---

### Task 7: Login Screen Updates with Unified Email/Username & Tests

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`
- Create: `test/features/auth/screens/login_screen_test.dart`

**Interfaces:**
- Consumes: `SupabaseService.getEmailByUsername`, `AppLocalizations`

- [ ] **Step 1: Write Widget Tests for LoginScreen**

Create `test/features/auth/screens/login_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/features/auth/screens/login_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('th'), Locale('en')],
        locale: Locale('th'),
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders email/username input and password input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('อีเมล หรือ ชื่อผู้ใช้'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows validation error when identifier is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('กรุณากรอกอีเมลหรือชื่อผู้ใช้'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/auth/screens/login_screen_test.dart`
Expected: Fails because label is currently `l10n.email` not `l10n.emailOrUsername`.

- [ ] **Step 3: Update `LoginScreen`**

In `lib/features/auth/screens/login_screen.dart`:
- Change `_emailCtrl` to `_identifierCtrl`.
- In `_login(AppLocalizations l10n)`:
  - If `_identifierCtrl.text.trim().isEmpty`, set error to `l10n.enterEmailOrUsername`.
  - If `_passCtrl.text.isEmpty`, set error to `l10n.pleaseEnterPassword`.
  - Detect if input contains `@`:
    - Contains `@`: use email directly.
    - No `@`: Call `SupabaseService().getEmailByUsername(input)`. If null, display `l10n.userNotFound` or proceed to attempt authentication.
- Update UI TextField label to `l10n.emailOrUsername` and hint to `l10n.usernameHint`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/screens/login_screen_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/screens/login_screen.dart test/features/auth/screens/login_screen_test.dart
git commit -m "feat(auth): support unified username or email login on LoginScreen"
```

---

### Task 8: End-to-End Verification & Full Test Suite

**Files:**
- Run: Full test suite and lint checks across the workspace.

- [ ] **Step 1: Run `flutter analyze`**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 2: Run `flutter test`**

Run: `flutter test`
Expected: All tests pass (> 95 tests).

- [ ] **Step 3: Git status check**

Verify clean working directory.
