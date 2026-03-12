// Not required for test files
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_bulk_client/scryfall_bulk_client.dart';

void main() {
  group('ScryfallBulkClient', () {
    test('can be instantiated', () {
      expect(ScryfallBulkClient(), isNotNull);
    });
  });
}
