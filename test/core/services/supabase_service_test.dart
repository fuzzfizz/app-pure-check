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
