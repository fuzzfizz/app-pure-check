import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator - Individual Criteria', () {
    group('hasMinLength', () {
      test('returns true for 8 or more characters', () {
        expect(PasswordValidator.hasMinLength('12345678'), isTrue);
        expect(PasswordValidator.hasMinLength('123456789'), isTrue);
      });

      test('returns false for less than 8 characters', () {
        expect(PasswordValidator.hasMinLength(''), isFalse);
        expect(PasswordValidator.hasMinLength('1234567'), isFalse);
      });
    });

    group('hasUppercase', () {
      test('returns true when uppercase letter is present', () {
        expect(PasswordValidator.hasUppercase('A'), isTrue);
        expect(PasswordValidator.hasUppercase('abcD'), isTrue);
      });

      test('returns false when no uppercase letter is present', () {
        expect(PasswordValidator.hasUppercase(''), isFalse);
        expect(PasswordValidator.hasUppercase('abcd123!'), isFalse);
      });
    });

    group('hasLowercase', () {
      test('returns true when lowercase letter is present', () {
        expect(PasswordValidator.hasLowercase('a'), isTrue);
        expect(PasswordValidator.hasLowercase('ABCd'), isTrue);
      });

      test('returns false when no lowercase letter is present', () {
        expect(PasswordValidator.hasLowercase(''), isFalse);
        expect(PasswordValidator.hasLowercase('ABCD123!'), isFalse);
      });
    });

    group('hasNumber', () {
      test('returns true when number is present', () {
        expect(PasswordValidator.hasNumber('1'), isTrue);
        expect(PasswordValidator.hasNumber('abc1def'), isTrue);
      });

      test('returns false when no number is present', () {
        expect(PasswordValidator.hasNumber(''), isFalse);
        expect(PasswordValidator.hasNumber('abcdef!'), isFalse);
      });
    });

    group('hasSpecialChar', () {
      test('returns true when special character is present', () {
        final specialChars = [
          '!', '@', '#', '\$', '%', '^', '&', '*', '(', ')',
          ',', '.', '?', '"', ':', '{', '}', '|', '<', '>',
          '_', '-', '+', '=', '[', ']', '\\', '/', '~', '`',
          "'", ';'
        ];
        for (final char in specialChars) {
          expect(PasswordValidator.hasSpecialChar('abc${char}123'), isTrue,
              reason: 'Failed for special character: $char');
        }
      });

      test('returns false when no special character is present', () {
        expect(PasswordValidator.hasSpecialChar(''), isFalse);
        expect(PasswordValidator.hasSpecialChar('abcABC123'), isFalse);
      });
    });
  });

  group('PasswordValidator - isPasswordValid', () {
    test('returns true when all 5 criteria are met', () {
      expect(PasswordValidator.isPasswordValid('StrongP@ss1'), isTrue);
      expect(PasswordValidator.isPasswordValid('Val!d123Password'), isTrue);
    });

    test('returns false when any criterion is missing', () {
      // Missing min length (< 8)
      expect(PasswordValidator.isPasswordValid('Str@1p'), isFalse);
      // Missing uppercase
      expect(PasswordValidator.isPasswordValid('strongp@ss1'), isFalse);
      // Missing lowercase
      expect(PasswordValidator.isPasswordValid('STRONGP@SS1'), isFalse);
      // Missing number
      expect(PasswordValidator.isPasswordValid('StrongP@ss'), isFalse);
      // Missing special char
      expect(PasswordValidator.isPasswordValid('StrongPass1'), isFalse);
    });
  });

  group('PasswordValidator - isUsernameValid', () {
    test('returns true for valid usernames (3-20 chars, alphanumeric, _, -)', () {
      expect(PasswordValidator.isUsernameValid('abc'), isTrue);
      expect(PasswordValidator.isUsernameValid('user_123'), isTrue);
      expect(PasswordValidator.isUsernameValid('cool-name_99'), isTrue);
      expect(PasswordValidator.isUsernameValid('12345678901234567890'), isTrue); // 20 chars
      expect(PasswordValidator.isUsernameValid('  user_123  '), isTrue); // trims whitespace
    });

    test('returns false for usernames less than 3 chars or more than 20 chars', () {
      expect(PasswordValidator.isUsernameValid(''), isFalse);
      expect(PasswordValidator.isUsernameValid('ab'), isFalse);
      expect(PasswordValidator.isUsernameValid('123456789012345678901'), isFalse); // 21 chars
    });

    test('returns false for usernames with invalid characters', () {
      expect(PasswordValidator.isUsernameValid('user@name'), isFalse);
      expect(PasswordValidator.isUsernameValid('user name'), isFalse);
      expect(PasswordValidator.isUsernameValid('user!'), isFalse);
      expect(PasswordValidator.isUsernameValid('user.name'), isFalse);
    });
  });
}
