// ignore_for_file: prefer_const_constructors
import 'package:api_client/api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:test/test.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  group('ScryfallRepository', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = _MockApiClient();
    });
    test('can be instantiated', () {
      expect(ScryfallRepository(apiClient: apiClient), isNotNull);
    });
  });
}
