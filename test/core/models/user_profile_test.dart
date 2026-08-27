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

  group('UserProfile username tests', () {
    test('UserProfile.empty can accept username or defaults to null', () {
      final profileDefault = UserProfile.empty('u1');
      expect(profileDefault.username, isNull);

      final profileWithUsername = UserProfile.empty('u1', username: 'johndoe');
      expect(profileWithUsername.username, 'johndoe');
    });

    test('UserProfile.fromJson parses username when present and handles null', () {
      final jsonWithUsername = {
        'id': 'u1',
        'username': 'johndoe',
        'skin_type': 'normal',
      };
      final profile1 = UserProfile.fromJson(jsonWithUsername);
      expect(profile1.username, 'johndoe');

      final jsonWithoutUsername = {
        'id': 'u1',
        'skin_type': 'normal',
      };
      final profile2 = UserProfile.fromJson(jsonWithoutUsername);
      expect(profile2.username, isNull);
    });

    test('UserProfile.toJson includes username when present', () {
      final profile = UserProfile.empty('u1', username: 'johndoe');
      final json = profile.toJson();
      expect(json['username'], 'johndoe');
    });

    test('copyWith updates username correctly', () {
      final profile = UserProfile.empty('u1');
      expect(profile.username, isNull);

      final updated = profile.copyWith(username: 'new_username');
      expect(updated.username, 'new_username');

      final unchanged = updated.copyWith(role: 'admin');
      expect(unchanged.username, 'new_username');
    });
  });
}
