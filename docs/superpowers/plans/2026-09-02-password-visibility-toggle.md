# Password Visibility Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add password visibility toggle functionality to both the Login and Registration screens so users can show or hide password text.

**Architecture:** Update `_LoginScreenState` and `_RegisterScreenState` to manage toggle visibility states and supply suffix `IconButton` with visibility icons to password `TextField` widgets.

**Tech Stack:** Flutter, Flutter Riverpod, Material Icons.

## Global Constraints
- Do not break existing form validation or authentication logic.
- Keep password and confirm password toggles independent on the registration screen.

---

### Task 1: Password Visibility Toggle on Login Screen

**Files:**
- Modify: `app_pure_check/lib/features/auth/screens/login_screen.dart`
- Test: `app_pure_check/test/features/auth/screens/login_screen_test.dart`

**Interfaces:**
- Consumes: `AppColors.textSecondary`
- Produces: `_obscurePassword` state and suffix `IconButton` in `login_screen.dart`

- [ ] **Step 1: Write widget test for password toggle in LoginScreen**

Add a test case in `app_pure_check/test/features/auth/screens/login_screen_test.dart`:
```dart
    testWidgets('toggles password visibility when toggle button is tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final passwordFieldFinder = find.widgetWithText(TextField, 'รหัสผ่าน');
      TextField passwordField = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      final toggleButton = find.byIcon(Icons.visibility_off);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      passwordField = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      passwordField = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/screens/login_screen_test.dart`
Expected: FAIL with `Icons.visibility_off` not found.

- [ ] **Step 3: Implement password visibility toggle in LoginScreen**

In `app_pure_check/lib/features/auth/screens/login_screen.dart`:
Add `bool _obscurePassword = true;` to `_LoginScreenState`.
Update password TextField decoration:
```dart
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/screens/login_screen_test.dart`
Expected: PASS

---

### Task 2: Password and Confirm Password Visibility Toggles on Register Screen

**Files:**
- Modify: `app_pure_check/lib/features/auth/screens/register_screen.dart`
- Test: `app_pure_check/test/features/auth/screens/register_screen_test.dart`

**Interfaces:**
- Consumes: `AppColors.textSecondary`
- Produces: `_obscurePassword` and `_obscureConfirmPassword` states in `register_screen.dart`

- [ ] **Step 1: Write widget test for independent password toggles in RegisterScreen**

Add test in `app_pure_check/test/features/auth/screens/register_screen_test.dart`:
```dart
    testWidgets('toggles password and confirm password visibility independently', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      TextField passField = tester.widget<TextField>(textFields.at(2));
      TextField confirmField = tester.widget<TextField>(textFields.at(3));

      expect(passField.obscureText, isTrue);
      expect(confirmField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));

      // Tap first toggle button (password)
      final toggles = find.byIcon(Icons.visibility_off);
      await tester.tap(toggles.first);
      await tester.pumpAndSettle();

      passField = tester.widget<TextField>(textFields.at(2));
      confirmField = tester.widget<TextField>(textFields.at(3));
      expect(passField.obscureText, isFalse);
      expect(confirmField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap second toggle button (confirm password)
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      passField = tester.widget<TextField>(textFields.at(2));
      confirmField = tester.widget<TextField>(textFields.at(3));
      expect(passField.obscureText, isFalse);
      expect(confirmField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/screens/register_screen_test.dart`
Expected: FAIL with `Icons.visibility_off` not found.

- [ ] **Step 3: Implement password visibility toggles in RegisterScreen**

In `app_pure_check/lib/features/auth/screens/register_screen.dart`:
Add `bool _obscurePassword = true;` and `bool _obscureConfirmPassword = true;` to `_RegisterScreenState`.
Update password and confirm password TextFields:
```dart
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PasswordRequirementsView(password: _passCtrl.text),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/screens/register_screen_test.dart`
Expected: PASS

---

### Task 3: Full Test Suite Verification

- [ ] **Step 1: Run all tests**

Run: `flutter test`
Expected: All tests pass (0 failures).
