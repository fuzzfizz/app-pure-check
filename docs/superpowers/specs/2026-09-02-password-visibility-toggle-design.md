# Password Visibility Toggle Design

## Overview
Add password visibility toggle functionality to the Login and Registration screens so users can easily verify their typed passwords before submission.

## Requirements
1. **Login Screen (`login_screen.dart`)**:
   - Add state variable `bool _obscurePassword = true;`
   - In password `TextField`, bind `obscureText: _obscurePassword`
   - Provide a suffix `IconButton` that switches between `Icons.visibility_off` (when obscured) and `Icons.visibility` (when visible).
   - Tapping the icon toggles `_obscurePassword` using `setState`.

2. **Register Screen (`register_screen.dart`)**:
   - Add state variables `bool _obscurePassword = true;` and `bool _obscureConfirmPassword = true;`
   - For password `TextField`, bind `obscureText: _obscurePassword` with suffix `IconButton`.
   - For confirm password `TextField`, bind `obscureText: _obscureConfirmPassword` with independent suffix `IconButton`.
   - Ensure dynamic checklist updates in `PasswordRequirementsView` continue to function identically.

3. **Widget Testing**:
   - Add test cases in `login_screen_test.dart` to verify initial password obscure state and toggle on tap.
   - Add test cases in `register_screen_test.dart` to verify independent password and confirm password obscure states and toggles on tap.
