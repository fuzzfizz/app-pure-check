# Design Specification: Username Login & Robust Password Security

- **Date:** 2026-08-27
- **Status:** Approved
- **Scope:** PureCheck Flutter App (`app_pure_check`)

---

## 1. Overview & Goals

This specification outlines the enhancements for user registration, authentication, and profile management in PureCheck:
1. **Username Support:** Allow users to register with a unique username (3–20 characters, alphanumeric and underscore/hyphen) and store it in `UserProfile` and the database.
2. **Flexible Login:** Allow users to log in using either their `username` or their `email`/`gmail` via a smart unified input field.
3. **Password Security Enforcement:** Require strict password complexity during registration:
   - Minimum 8 characters
   - At least 1 uppercase letter (`[A-Z]`)
   - At least 1 lowercase letter (`[a-z]`)
   - At least 1 numeric digit (`[0-9]`)
   - At least 1 special character (`[!@#$%^&*(),.?":{}|<>\-_+=\[\]\\\/~`';]`)
4. **Real-time Password Validation UI:** Display a live checklist below the password input in the registration screen that dynamically checks off requirements with green checkmarks as the user types.

---

## 2. Architecture & Data Flow

### 2.1 Data Models & Database Migration
1. **`UserProfile` Model (`lib/core/models/user_profile.dart`)**:
   - Add nullable `final String? username;` field.
   - Update `fromJson`, `toJson`, `copyWith`, and `empty` factory.
2. **Supabase Database Migration (`docs/superpowers/specs/2026-08-27-username-migration.sql`)**:
   - Add column `username text UNIQUE` to `public.profiles`.
   - Create index `idx_profiles_username_lower ON public.profiles (lower(username));`
   - Add RPC `public.get_email_by_username(p_username text) RETURNS text` with `SECURITY DEFINER` allowing looking up the user's email for authentication when provided with a valid username.

### 2.2 Registration Flow
1. User enters:
   - **Username**: Validated for format `^[a-zA-Z0-9_-]{3,20}$` and non-empty.
   - **Email**: Validated with standard email pattern.
   - **Password**: Evaluated against the 5 security rules. Submit button is disabled or blocked if requirements are not met.
   - **Confirm Password**: Checked for equality with Password.
2. When submitting:
   - Calls `Supabase.instance.client.auth.signUp(email: email, password: password, data: {'username': username})`.
   - Upserts initial profile with `username`.

### 2.3 Login Flow (Smart Detection)
1. User enters identifier into unified input field (`_identifierCtrl`):
   - If input contains `@`: Treated directly as **Email**. Calls `signInWithPassword(email: input, password: password)`.
   - If input does NOT contain `@`: Treated as **Username**.
     - Looks up email via `SupabaseService.getEmailByUsername(username)` / RPC.
     - If email found, executes `signInWithPassword(email: resolvedEmail, password: password)`.
     - If no email found or error, displays localized error: "ไม่พบบัญชีผู้ใช้นี้ หรือรหัสผ่านไม่ถูกต้อง" ("Username not found or invalid credentials").

### 2.4 Localization (`app_en.arb` & `app_th.arb`)
- Add localized strings:
  - `username`: "ชื่อผู้ใช้" / "Username"
  - `emailOrUsername`: "อีเมล หรือ ชื่อผู้ใช้" / "Email or Username"
  - `enterEmailOrUsername`: "กรุณากรอกอีเมลหรือชื่อผู้ใช้" / "Please enter your email or username"
  - `usernameHint`: "เช่น user123 หรือ example@gmail.com" / "e.g. user123 or example@gmail.com"
  - `invalidUsername`: "ชื่อผู้ใช้ต้องมี 3-20 ตัวอักษร (A-Z, a-z, 0-9, _, -)" / "Username must be 3-20 characters (A-Z, a-z, 0-9, _, -)"
  - `passwordRuleMinLength`: "ความยาวอย่างน้อย 8 ตัวอักษร" / "At least 8 characters"
  - `passwordRuleUppercase`: "มีตัวอักษรพิมพ์ใหญ่ (A-Z)" / "At least 1 uppercase letter"
  - `passwordRuleLowercase`: "มีตัวอักษรพิมพ์เล็ก (a-z)" / "At least 1 lowercase letter"
  - `passwordRuleNumber`: "มีตัวเลข (0-9)" / "At least 1 number"
  - `passwordRuleSpecialChar`: "มีอักขระพิเศษ (เช่น !@#$%)" / "At least 1 special character"
  - `userNotFound`: "ไม่พบบัญชีผู้ใช้นี้" / "User account not found"

---

## 3. Component Details & UI

### 3.1 `PasswordValidator` Utility (`lib/core/utils/password_validator.dart`)
- Helper class that evaluates:
  - `hasMinLength(String p) => p.length >= 8`
  - `hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p)`
  - `hasLowercase(String p) => RegExp(r'[a-z]').hasMatch(p)`
  - `hasNumber(String p) => RegExp(r'[0-9]').hasMatch(p)`
  - `hasSpecialChar(String p) => RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=[\]\\\/~`'';]').hasMatch(p)`
  - `isValid(String p) => hasMinLength(p) && hasUppercase(p) && hasLowercase(p) && hasNumber(p) && hasSpecialChar(p)`

### 3.2 `PasswordRequirementsView` Widget (`lib/features/auth/widgets/password_requirements_view.dart`)
- Clean, compact list showing the 5 rules with animated or transition icons (Grey circle / Red when invalid -> Green checkmark when valid).

### 3.3 Registration Screen (`lib/features/auth/screens/register_screen.dart`)
- Added Username TextField.
- Integrated `PasswordRequirementsView`.
- Input validation preventing submission if any requirement fails.

### 3.4 Login Screen (`lib/features/auth/screens/login_screen.dart`)
- Single text field with label `emailOrUsername`.
- Seamless username-to-email resolution before authenticating.

---

## 4. Testing & Verification

1. **Unit Tests**:
   - `test/core/utils/password_validator_test.dart`: Test all permutations of password validity (missing uppercase, missing lowercase, missing number, missing special char, length < 8, valid password).
   - `test/core/models/user_profile_test.dart`: Test serialization/deserialization of `username`.
2. **Widget Tests**:
   - `test/features/auth/screens/register_screen_test.dart`: Verify Username field, password live checklist updates as user types, and form submission validation.
   - `test/features/auth/screens/login_screen_test.dart`: Verify login works with both email and username formats.
3. **End-to-End Verification**:
   - Run `flutter analyze` and `flutter test` across the full test suite.
