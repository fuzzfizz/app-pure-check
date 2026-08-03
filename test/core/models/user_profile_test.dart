import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/user_profile.dart';

void main() {
  group('UserProfile role and isAdmin tests', () {
    test('UserProfile.empty has default role "user" and isAdmin is false', () {
      final profile = UserProfile.empty('test-id');
      expect(profile.role, 'user');
      expect(profile.isAdmin, isFalse);
    });

    test('UserProfile.fromJson parses role "admin" and sets isAdmin to true', () {
      final json = {
        'id': 'test-id',
        'skin_type': 'normal',
        'role': 'admin',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.role, 'admin');
      expect(profile.isAdmin, isTrue);
    });

    test('UserProfile.fromJson defaults role to "user" if missing', () {
      final json = {
        'id': 'test-id',
        'skin_type': 'normal',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.role, 'user');
      expect(profile.isAdmin, isFalse);
    });

    test('UserProfile.toJson includes role', () {
      final profile = UserProfile.empty('test-id');
      final json = profile.toJson();
      expect(json['role'], 'user');
    });

    test('copyWith updates role correctly', () {
      final profile = UserProfile.empty('test-id');
      final updated = profile.copyWith(role: 'admin');
      expect(updated.role, 'admin');
      expect(updated.isAdmin, isTrue);
    });
  });
}
