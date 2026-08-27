class PasswordValidator {
  PasswordValidator._();

  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _numberRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex =
      RegExp(r"""[!@#$%^&*(),.?":{}|<>_\-+=[\]\\\/~`';]""");
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
