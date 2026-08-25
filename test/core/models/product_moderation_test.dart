import 'package:flutter_test/flutter_test.dart';
import 'package:pure_check/core/models/product.dart';

void main() {
  group('Product Moderation Fields Test', () {
    test('fromJson parses moderation fields correctly when present', () {
      final json = {
        'id': 'prod-001',
        'barcode': '8851234567890',
        'name': 'Moisturizing Cream',
        'brand': 'Beauty Lab',
        'ingredients': ['Water', 'Glycerin', 'Niacinamide'],
        'raw_ingredients_text': 'Water, Glycerin, Niacinamide',
        'source': 'user_entered',
        'verified_count': 5,
        'image_url': 'https://example.com/image.png',
        'is_verified': true,
        'status': 'pending',
        'submitted_by': 'user_abc123',
        'confidence_score': 85,
        'ai_flags': ['unverified_brand', 'potential_allergen'],
      };

      final product = Product.fromJson(json);

      expect(product.id, 'prod-001');
      expect(product.isVerified, true);
      expect(product.status, 'pending');
      expect(product.submittedBy, 'user_abc123');
      expect(product.confidenceScore, 85);
      expect(product.aiFlags, ['unverified_brand', 'potential_allergen']);
    });

    test('fromJson provides sensible defaults when moderation fields are omitted', () {
      final json = {
        'id': 'prod-002',
        'name': 'Simple Sunscreen',
        'ingredients': ['Zinc Oxide'],
      };

      final product = Product.fromJson(json);

      expect(product.isVerified, false);
      expect(product.status, 'approved');
      expect(product.submittedBy, isNull);
      expect(product.confidenceScore, 100);
      expect(product.aiFlags, isEmpty);
    });

    test('toJson includes moderation fields', () {
      const product = Product(
        id: 'prod-003',
        name: 'Cleansing Foam',
        isVerified: true,
        status: 'rejected',
        submittedBy: 'user_xyz',
        confidenceScore: 40,
        aiFlags: ['suspicious_ingredients'],
      );

      final json = product.toJson();

      expect(json['is_verified'], true);
      expect(json['status'], 'rejected');
      expect(json['submitted_by'], 'user_xyz');
      expect(json['confidence_score'], 40);
      expect(json['ai_flags'], ['suspicious_ingredients']);
    });

    test('toJson omits empty id and empty barcode to prevent postgres uuid syntax error', () {
      const product = Product(
        id: '',
        name: 'OpenBeautyProduct',
        ingredients: ['Water'],
      );

      final json = product.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('barcode'), isFalse);
      expect(json['name'], 'OpenBeautyProduct');
    });

    test('copyWith correctly updates moderation fields', () {
      const product = Product(
        id: 'prod-004',
        name: 'Serum',
        isVerified: false,
        status: 'pending',
        submittedBy: 'user_1',
        confidenceScore: 70,
        aiFlags: ['flag1'],
      );

      final updated = product.copyWith(
        isVerified: true,
        status: 'approved',
        submittedBy: 'admin_1',
        confidenceScore: 95,
        aiFlags: ['flag1', 'flag2'],
      );

      expect(updated.id, 'prod-004');
      expect(updated.name, 'Serum');
      expect(updated.isVerified, true);
      expect(updated.status, 'approved');
      expect(updated.submittedBy, 'admin_1');
      expect(updated.confidenceScore, 95);
      expect(updated.aiFlags, ['flag1', 'flag2']);
    });
  });
}
