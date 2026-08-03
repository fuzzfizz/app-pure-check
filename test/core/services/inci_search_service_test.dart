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

    test('searchIngredients queries inci_ingredients table with ilike and limit', () async {
      fakeHttpClient.jsonResponseData = [
        {'name': 'Niacinamide'},
        {'name': 'Nicotinic Acid'},
      ];

      final results = await service.searchIngredients('Niacin', limit: 5);

      expect(results, equals(['Niacinamide', 'Nicotinic Acid']));
      expect(fakeHttpClient.lastUrl, isNotNull);
      expect(fakeHttpClient.lastUrl!.path, contains('/rest/v1/inci_ingredients'));
      expect(fakeHttpClient.lastUrl!.queryParameters['select'], equals('name'));
      expect(fakeHttpClient.lastUrl!.queryParameters['name'], equals('ilike.%Niacin%'));
      expect(fakeHttpClient.lastUrl!.queryParameters['limit'], equals('5'));
    });

    test('filterUnrecognizedIngredients identifies ingredients not in inci_ingredients', () async {
      fakeHttpClient.jsonResponseData = [
        {'name': 'Water'},
        {'name': 'Glycerin'},
      ];

      final input = ['Water', 'Glycerin', 'UnknownIngredient123'];
      final unrecognized = await service.filterUnrecognizedIngredients(input);

      expect(unrecognized, equals(['UnknownIngredient123']));
      expect(fakeHttpClient.lastUrl, isNotNull);
      expect(fakeHttpClient.lastUrl!.path, contains('/rest/v1/inci_ingredients'));
      expect(fakeHttpClient.lastUrl!.queryParameters['select'], equals('name'));
      expect(fakeHttpClient.lastUrl!.queryParameters['name'], contains('in.'));
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
