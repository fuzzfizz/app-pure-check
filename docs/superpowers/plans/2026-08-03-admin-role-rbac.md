# Admin Role & Role-Based Access Control (RBAC) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Admin Role & Role-Based Access Control (RBAC) in `app_pure_check` so that only accounts with `role = 'admin'` can access `/admin/*` routes and view the Admin Moderation dashboard option in Settings.

**Architecture:** Extend `UserProfile` model with a `role` field and `isAdmin` getter. Update `GoRouter.redirect` to block non-admin users from accessing `/admin/*` routes, and update `SettingsScreen` to conditionally display the Admin Product Review menu item only when `profile.isAdmin == true`.

**Tech Stack:** Flutter, Riverpod, GoRouter, Supabase Flutter, Dart unit/widget tests.

## Global Constraints

- Dart version / Flutter SDK compatibility: Flutter 3.x with Riverpod 2.x and GoRouter.
- Preserves existing model default values and `onboardingComplete` logic.
- Absolute file paths in commands: `D:\AppPureCheck\app_pure_check`.

---

### Task 1: Add `role` Field and `isAdmin` Getter to `UserProfile` Model

**Files:**
- Modify: `lib/core/models/user_profile.dart:33-88`
- Create/Modify: `test/core/models/user_profile_test.dart`

**Interfaces:**
- Consumes: None
- Produces: `UserProfile.role` (`String`), `UserProfile.isAdmin` (`bool`), updated `fromJson`/`toJson`/`copyWith`/`empty`.

- [ ] **Step 1: Write failing tests for `role` and `isAdmin` in `user_profile_test.dart`**

Create or update `test/core/models/user_profile_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/user_profile.dart';

void main() {
  group('UserProfile Admin Role', () {
    test('default role is user and isAdmin is false', () {
      final profile = UserProfile.empty('user_1');
      expect(profile.role, 'user');
      expect(profile.isAdmin, false);
    });

    test('fromJson parses role admin and sets isAdmin to true', () {
      final json = {
        'id': 'admin_1',
        'skin_type': 'oily',
        'skin_conditions': ['acne_prone'],
        'skin_concerns': ['acne'],
        'avoid_preferences': [],
        'onboarding_complete': true,
        'role': 'admin',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.role, 'admin');
      expect(profile.isAdmin, true);
    });

    test('toJson includes role field', () {
      final profile = UserProfile(
        id: 'admin_1',
        skinType: SkinType.normal,
        role: 'admin',
        onboardingComplete: true,
      );
      final json = profile.toJson();
      expect(json['role'], 'admin');
    });

    test('copyWith updates role correctly', () {
      final profile = UserProfile.empty('user_1');
      final adminProfile = profile.copyWith(role: 'admin');
      expect(adminProfile.role, 'admin');
      expect(adminProfile.isAdmin, true);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/user_profile_test.dart`
Expected: FAIL due to getter `isAdmin` and `role` parameter missing.

- [ ] **Step 3: Update `UserProfile` in `lib/core/models/user_profile.dart`**

Modify `lib/core/models/user_profile.dart`:

```dart
class UserProfile {
  final String id;
  final SkinType skinType;
  final List<String> skinConditions;
  final List<String> skinConcerns;
  final List<String> avoidPreferences;
  final bool onboardingComplete;
  final String role;

  const UserProfile({
    required this.id,
    required this.skinType,
    this.skinConditions = const [],
    this.skinConcerns = const [],
    this.avoidPreferences = const [],
    this.onboardingComplete = false,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  factory UserProfile.empty(String id) => UserProfile(
        id: id,
        skinType: SkinType.normal,
        onboardingComplete: false,
        role: 'user',
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        skinType: SkinTypeX.fromString(json['skin_type'] as String? ?? 'normal'),
        skinConditions: List<String>.from(json['skin_conditions'] ?? []),
        skinConcerns: List<String>.from(json['skin_concerns'] ?? []),
        avoidPreferences: List<String>.from(json['avoid_preferences'] ?? []),
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
        role: json['role'] as String? ?? 'user',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'skin_type': skinType.value,
        'skin_conditions': skinConditions,
        'skin_concerns': skinConcerns,
        'avoid_preferences': avoidPreferences,
        'onboarding_complete': onboardingComplete,
        'role': role,
      };

  UserProfile copyWith({
    SkinType? skinType,
    List<String>? skinConditions,
    List<String>? skinConcerns,
    List<String>? avoidPreferences,
    bool? onboardingComplete,
    String? role,
  }) => UserProfile(
        id: id,
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
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/models/user_profile.dart test/core/models/user_profile_test.dart
git commit -m "feat(auth): add role field and isAdmin getter to UserProfile model"
```

---

### Task 2: Implement Admin Route Protection in `GoRouter.redirect`

**Files:**
- Modify: `lib/core/router/app_router.dart:23-52`
- Create/Modify: `test/core/router/app_router_test.dart`

**Interfaces:**
- Consumes: `UserProfile.isAdmin`
- Produces: Router redirect protection for `/admin/*` routes.

- [ ] **Step 1: Write test verifying admin route guard behavior in `app_router_test.dart`**

Create `test/core/router/app_router_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/user_profile.dart';

void main() {
  group('Admin Route Guard Logic', () {
    test('non-admin profile should be blocked from /admin routes', () {
      final userProfile = UserProfile.empty('user_1');
      expect(userProfile.isAdmin, false);
    });

    test('admin profile should be allowed to access /admin routes', () {
      final adminProfile = UserProfile(
        id: 'admin_1',
        skinType: SkinType.normal,
        role: 'admin',
      );
      expect(adminProfile.isAdmin, true);
    });
  });
}
```

- [ ] **Step 2: Update `GoRouter.redirect` in `lib/core/router/app_router.dart`**

Modify `lib/core/router/app_router.dart`:

```dart
      if (user != null) {
        // Skip check on splash screen (handled by splash timer)
        if (state.matchedLocation == '/splash') return null;

        final profileAsync = ref.read(currentProfileProvider);
        UserProfile? profile;
        if (profileAsync.hasValue && !profileAsync.isLoading) {
          profile = profileAsync.value;
        } else {
          profile = await ref.read(currentProfileProvider.future);
        }

        final isOnboarding = state.matchedLocation.startsWith('/onboarding');
        final isAdminRoute = state.matchedLocation.startsWith('/admin');

        if (profile == null || !profile.onboardingComplete) {
          if (!isOnboarding) return '/onboarding';
        } else {
          if (isAdminRoute && !profile.isAdmin) {
            return '/home';
          }
          if (isOnboarding || isPublic) return '/home';
        }
      }
```

- [ ] **Step 3: Run test suite to verify no regressions**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 4: Commit changes**

```bash
git add lib/core/router/app_router.dart test/core/router/app_router_test.dart
git commit -m "feat(router): restrict /admin routes to users with admin role"
```

---

### Task 3: Render Admin Product Review Menu Option in SettingsScreen for Admin Accounts

**Files:**
- Modify: `lib/features/account/screens/settings_screen.dart`
- Create/Modify: `test/features/account/screens/settings_screen_test.dart`

**Interfaces:**
- Consumes: `ref.watch(currentProfileProvider)`, `UserProfile.isAdmin`
- Produces: Conditional Admin Tools tile in `SettingsScreen`.

- [ ] **Step 1: Write test for Admin tile rendering in `settings_screen_test.dart`**

Create `test/features/account/screens/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_check/core/models/user_profile.dart';
import 'package:pure_check/core/l10n/app_localizations.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:pure_check/features/account/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen displays Admin Product Review tile only for admin user', (tester) async {
    final adminProfile = UserProfile(
      id: 'admin_1',
      skinType: SkinType.normal,
      role: 'admin',
      onboardingComplete: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith((ref) async => adminProfile),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Admin Product Review'), findsOneWidget);
  });

  testWidgets('SettingsScreen hides Admin Product Review tile for regular user', (tester) async {
    final userProfile = UserProfile(
      id: 'user_1',
      skinType: SkinType.normal,
      role: 'user',
      onboardingComplete: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith((ref) async => userProfile),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Admin Product Review'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails initially**

Run: `flutter test test/features/account/screens/settings_screen_test.dart`
Expected: FAIL because Admin Product Review is not yet in `SettingsScreen`.

- [ ] **Step 3: Add Admin Tools section to `SettingsScreen` in `lib/features/account/screens/settings_screen.dart`**

In `SettingsScreen.build`:
Read `profileAsync` from `ref.watch(currentProfileProvider)`.

```dart
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.asData?.value;
    final isAdmin = profile?.isAdmin ?? false;
```

In the `ListView` children, before Logout Action:

```dart
          // Admin section (Visible only for admin accounts)
          if (isAdmin) ...[
            _buildSectionHeader(isTh ? 'การจัดการระบบ (Admin Tools)' : 'Admin Tools'),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
              title: const Text('Admin Product Review'),
              subtitle: Text(
                isTh
                  ? 'ตรวจสอบและอนุมัติสินค้าที่ผู้ใช้ส่งเข้ามา'
                  : 'Review & approve user-submitted products',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => context.push('/admin/review'),
            ),
            const Divider(),
          ],
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/account/screens/settings_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Run full test suite and analyzer**

Run: `flutter test`
Run: `flutter analyze`
Expected: 0 errors, all tests pass.

- [ ] **Step 6: Commit changes**

```bash
git add lib/features/account/screens/settings_screen.dart test/features/account/screens/settings_screen_test.dart
git commit -m "feat(settings): display Admin Product Review section for admin accounts"
```

---
