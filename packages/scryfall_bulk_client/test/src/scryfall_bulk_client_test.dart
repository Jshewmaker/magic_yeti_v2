import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scryfall_bulk_client/scryfall_bulk_client.dart';

class _MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScryfallBulkClient', () {
    late AssetBundle assetBundle;
    late ScryfallBulkClient client;

    setUp(() {
      assetBundle = _MockAssetBundle();
      when(() => assetBundle.loadString(any())).thenAnswer(
        (_) async => File(
          'test/src/fixtures/cards_fixture.json',
        ).readAsStringSync(),
      );
      client = ScryfallBulkClient(assetBundle: assetBundle);
    });

    test('can be instantiated', () {
      expect(ScryfallBulkClient(), isNotNull);
    });

    group('getOracleIdByName', () {
      test('returns oracle ID for an exact name match', () async {
        final oracleId = await client.getOracleIdByName(
          "Atraxa, Praetors' Voice",
        );
        expect(oracleId, '7e6b9b59-8767-4b3d-b3b5-1a4c72e0a1e5');
      });

      test('matches names case-insensitively', () async {
        final oracleId = await client.getOracleIdByName(
          "ATRAXA, PRAETORS' VOICE",
        );
        expect(oracleId, '7e6b9b59-8767-4b3d-b3b5-1a4c72e0a1e5');
      });

      test('returns null when no card matches', () async {
        final oracleId = await client.getOracleIdByName('Lightning Bolt');
        expect(oracleId, isNull);
      });

      test('matches double-faced card by full name', () async {
        final oracleId = await client.getOracleIdByName(
          'Esika, God of the Tree // The Prismatic Bridge',
        );
        expect(oracleId, '9d4dcbbd-7e1e-4b0d-8f8e-9a5f3c2d1e0f');
      });
    });

    group('searchCards', () {
      test('returns cards whose name contains the query', () async {
        final results = await client.searchCards('atraxa');
        expect(results.totalCards, 2);
        expect(
          results.data.map((card) => card.artist),
          ['Victor Adame Minguez', 'Magali Villeneuve'],
        );
      });

      test('matches case-insensitively', () async {
        final results = await client.searchCards('RAISED BY');
        expect(results.totalCards, 1);
        expect(results.data.first.name, 'Raised by Giants');
      });

      test('returns an empty result set when nothing matches', () async {
        final results = await client.searchCards('storm crow');
        expect(results.totalCards, 0);
        expect(results.data, isEmpty);
        expect(results.hasMore, false);
      });

      test('parses index entries into usable MagicCard fields', () async {
        final results = await client.searchCards('Raised by Giants');
        final card = results.data.first;
        expect(card.oracleId, '02f1dbb2-4ffd-45f9-ba1a-a2765ee2f0d0');
        expect(card.typeLine, 'Legendary Enchantment — Background');
        expect(card.colors, ['G']);
        expect(card.colorIdentity, ['G']);
        expect(card.manaCost, '{2}{G}');
        expect(
          card.imageUris?.artCrop,
          'https://cards.scryfall.io/art_crop/front/raised-by-giants.jpg',
        );
        expect(card.imageStatus, isNot('missing'));
        expect(card.edhrecRank, 8123);
      });

      test('tolerates entries with missing optional fields', () async {
        final results = await client.searchCards('Esika');
        final card = results.data.first;
        expect(card.colors, isNull);
        expect(card.manaCost, isNull);
        expect(card.power, isNull);
        expect(card.oracleText, isNull);
      });
    });

    test('loads the asset only once across calls', () async {
      await client.searchCards('atraxa');
      await client.getOracleIdByName('Raised by Giants');
      await client.searchCards('esika');
      verify(() => assetBundle.loadString(any())).called(1);
    });

    test('deduplicates concurrent first calls into a single load', () async {
      await Future.wait([
        client.searchCards('atraxa'),
        client.getOracleIdByName('Raised by Giants'),
      ]);
      verify(() => assetBundle.loadString(any())).called(1);
    });
  });
}
