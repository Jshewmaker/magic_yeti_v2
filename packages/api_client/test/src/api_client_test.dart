// ignore_for_file: prefer_const_constructors
import 'package:api_client/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('ApiClient', () {
    late http.Client httpClient;
    late ApiClient apiClient;

    setUp(() {
      httpClient = _MockHttpClient();
      apiClient = ApiClient(
        baseUrl: 'https://api.scryfall.com',
        httpClient: httpClient,
      );
    });

    test('can be instantiated', () {
      expect(apiClient, isNotNull);
    });

    group('getOracleIdByName', () {
      test('returns the oracle ID for a matching card', () async {
        when(
          () => httpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => http.Response(
            '{"object":"card","name":"Lightning Bolt", '
            '"oracle_id":"4457ed35-7c10-48c8-9776-456485fdf070"}',
            200,
          ),
        );

        final oracleId = await apiClient.getOracleIdByName('Lightning Bolt');

        expect(oracleId, '4457ed35-7c10-48c8-9776-456485fdf070');
        final uri =
            verify(
                  () => httpClient.get(
                    captureAny(),
                    headers: any(named: 'headers'),
                  ),
                ).captured.single
                as Uri;
        expect(uri.path, '/cards/named');
        expect(uri.queryParameters, {'exact': 'Lightning Bolt'});
      });

      test('returns null when the card is not found', () async {
        when(
          () => httpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => http.Response('{"object":"error","status":404}', 404),
        );

        final oracleId = await apiClient.getOracleIdByName('Not A Card');

        expect(oracleId, isNull);
      });

      test('throws ApiClientError on non-404 failures', () async {
        when(
          () => httpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('server error', 500));

        expect(
          () => apiClient.getOracleIdByName('Lightning Bolt'),
          throwsA(isA<ApiClientError>()),
        );
      });

      test('throws ApiClientError when the request fails', () async {
        when(
          () => httpClient.get(any(), headers: any(named: 'headers')),
        ).thenThrow(http.ClientException('no network'));

        expect(
          () => apiClient.getOracleIdByName('Lightning Bolt'),
          throwsA(isA<ApiClientError>()),
        );
      });
    });
  });
}
