# Design Specification: Admin Role & Role-Based Access Control (RBAC)

**Date:** 2026-08-03  
**Status:** Approved by User  
**Target Application:** `app_pure_check` (Flutter + Supabase)

---

## 1. Executive Summary

This specification establishes **Role-Based Access Control (RBAC)** for admin features in `app_pure_check`. 
User accounts with `role = 'admin'` will have access to admin-only capabilities, including:
1. **Router Protection (`app_router.dart`)**: Non-admin users attempting to access `/admin/*` routes are automatically redirected to `/home`.
2. **Conditional UI Visibility (`SettingsScreen`)**: The "Admin Tools / Admin Product Review" tile is displayed **only** for users with `role = 'admin'`.
3. **Data & Profile Integration (`UserProfile`)**: The `profiles` table in Supabase and the `UserProfile` Dart model are updated to support user roles (`'user'` | `'admin'`).

---

## 2. Database Schema & Migration

* **SQL Migration File:** `docs/superpowers/specs/2026-08-03-admin-role-rbac-migration.sql`

```sql
-- Add role column to profiles table if not exists
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS role text DEFAULT 'user' CHECK (role IN ('user', 'admin'));

-- Index role for performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
```

---

## 3. Component Architecture & Changes

### 3.1 Data Layer (`lib/core/models/user_profile.dart`)
* Add field `final String role` (default `'user'`).
* Add getter `bool get isAdmin => role == 'admin';`.
* Update `UserProfile.fromJson`, `toJson`, `copyWith`, and `UserProfile.empty`.

### 3.2 Router Guard (`lib/core/router/app_router.dart`)
* Update `GoRouter.redirect` logic:
  - Check if `state.matchedLocation.startsWith('/admin')`.
  - If target is an `/admin` route and `profile == null || !profile.isAdmin`, return `'/home'` (access denied).

### 3.3 UI Feature Visibility (`lib/features/account/screens/settings_screen.dart`)
* Inspect `ref.watch(currentProfileProvider)`.
* If `profile?.isAdmin == true`, render the **Admin Tools** section:
  - **Tile Title:** `Admin Product Review`
  - **Subtitle:** `Review & approve user-submitted products`
  - **Icon:** `Icons.admin_panel_settings_outlined`
  - **Navigation:** `context.push('/admin/review')`
* If `profile?.isAdmin != true`, suppress the section completely.

---

## 4. Verification & Testing Strategy

1. **Unit Tests (`test/core/models/user_profile_test.dart`)**:
   - Verify `UserProfile.fromJson` parses `role: 'admin'` correctly.
   - Verify `isAdmin` returns `true` for `'admin'` and `false` for `'user'`.
2. **Widget Tests (`test/features/account/screens/settings_screen_test.dart`)**:
   - Verify Admin tile is visible when `profile.isAdmin == true`.
   - Verify Admin tile is hidden when `profile.isAdmin == false`.
3. **Router Integration Tests (`test/core/router/app_router_test.dart`)**:
   - Verify non-admin user accessing `/admin/review` is redirected to `/home`.

---
