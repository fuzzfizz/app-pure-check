import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pure_check/core/services/inci_search_service.dart';
import 'package:pure_check/core/services/supabase_service.dart';
import 'package:pure_check/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeHttpClient extends http.BaseClient {
  http.Request? lastRequest;
  Uri? lastUrl;
  dynamic jsonResponseData = [];
  int statusCode = 200;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url;
    if (request is http.Request) {
      lastRequest = request;
    }
    final bodyString = jsonEncode(jsonResponseData);
    final responseBytes = utf8.encode(bodyString);
    return http.StreamedResponse(
      Stream.value(responseBytes),
      statusCode,
      request: request,
      headers: {
        'content-type': 'application/json; charset=utf-8',
      },
    );
  }
}

void main() {
  group('InciSearchService', () {
    late FakeHttpClient fakeHttpClient;
    late SupabaseClient supabaseClient;
    late SupabaseService supabaseService;
    late InciSearchService service;

    setUp(() {
      fakeHttpClient = FakeHttpClient();
      supabaseClient = SupabaseClient(
        'https://fake.supabase.co',
        'fake_key',
        httpClient: fakeHttpClient,
      );
      supabaseService = SupabaseService(supabaseClient);
      service = InciSearchService(supabaseService);
    });

    test('searchIngredients returns local matches and queries remote when needed', () async {
      fakeHttpClient.jsonResponseData = [
        {'name': 'CustomRemoteIngr'},
      ];

      final results = await service.searchIngredients('CustomRemote', limit: 5);

      expect(results, contains('CustomRemoteIngr'));
      expect(fakeHttpClient.lastUrl, isNotNull);
      expect(fakeHttpClient.lastUrl!.path, contains('/rest/v1/inci_ingredients'));
    });

    test('searchIngredients returns instant local matches without network when limit met', () async {
      final results = await service.searchIngredients('Niacinamide', limit: 1);
      expect(results, equals(['Niacinamide']));
      expect(fakeHttpClient.lastUrl, isNull);
    });

    test('filterUnrecognizedIngredients recognizes standard INCI locally and queries remote for unknowns', () async {
      fakeHttpClient.jsonResponseData = [
        {'name': 'CustomRemoteApproved'},
      ];

      final input = ['Water', 'Glycerin', 'CustomRemoteApproved', 'UnknownIngredient123'];
      final unrecognized = await service.filterUnrecognizedIngredients(input);

      expect(unrecognized, equals(['UnknownIngredient123']));
      expect(fakeHttpClient.lastUrl, isNotNull);
      expect(fakeHttpClient.lastUrl!.path, contains('/rest/v1/inci_ingredients'));
      expect(fakeHttpClient.lastUrl!.queryParameters['name'], contains('in.'));
    });

    test('filterUnrecognizedIngredients returns empty when all ingredients are standard INCI', () async {
      final input = ['Water', 'Aqua', 'Glycerin', 'Niacinamide', 'Ceramide NP'];
      final unrecognized = await service.filterUnrecognizedIngredients(input);

      expect(unrecognized, isEmpty);
      expect(fakeHttpClient.lastUrl, isNull); // zero network calls required!
    });

    test('filterUnrecognizedIngredients handles case insensitivity', () async {
      final input = ['water', 'GLYCERIN', 'niacinamide', 'ceramide np'];
      final unrecognized = await service.filterUnrecognizedIngredients(input);

      expect(unrecognized, isEmpty);
      expect(fakeHttpClient.lastUrl, isNull);
    });

    test('filterUnrecognizedIngredients returns empty list when given empty input', () async {
      final unrecognized = await service.filterUnrecognizedIngredients([]);
      expect(unrecognized, isEmpty);
      expect(fakeHttpClient.lastUrl, isNull);
    });

    test('inciSearchServiceProvider creates InciSearchService instance', () {
      final container = ProviderContainer(
        overrides: [
          supabaseServiceProvider.overrideWithValue(supabaseService),
        ],
      );
      addTearDown(container.dispose);

      final inciService = container.read(inciSearchServiceProvider);
      expect(inciService, isA<InciSearchService>());
    });
  });
}
