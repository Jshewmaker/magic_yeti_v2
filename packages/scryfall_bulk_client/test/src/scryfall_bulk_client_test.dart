import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_bulk_client/scryfall_bulk_client.dart';

/// An [AssetBundle] that serves the small test fixture instead of the real
/// bulk data asset, and records how many times the asset bytes are loaded.
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._bytes);

  final Uint8List _bytes;
  int loadCount = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCount++;
    return ByteData.sublistView(_bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAssetBundle assetBundle;
  late ScryfallBulkClient client;

  setUp(() {
    final fixture = File('test/src/fixtures/cards_fixture.json');
    assetBundle = _FakeAssetBundle(fixture.readAsBytesSync());
    client = ScryfallBulkClient(assetBundle: assetBundle);
  });

  group('ScryfallBulkClient', () {
    test('can be instantiated', () {
      expect(ScryfallBulkClient(), isNotNull);
    });

    group('getOracleIdByName', () {
      test('returns the oracle id for an exact name match', () async {
        final oracleId = await client.getOracleIdByName(
          "Atraxa, Praetors' Voice",
        );
        expect(oracleId, equals('oracle-atraxa'));
      });

      test('matches names case-insensitively', () async {
        final oracleId = await client.getOracleIdByName(
          "atraxa, praetors' voice",
        );
        expect(oracleId, equals('oracle-atraxa'));
      });

      test('returns null when no card matches', () async {
        final oracleId = await client.getOracleIdByName('Not A Real Card');
        expect(oracleId, isNull);
      });

      test('loads the asset only once across repeated lookups', () async {
        await client.getOracleIdByName('Forest');
        await client.getOracleIdByName("Atraxa, Praetors' Voice");
        await client.getOracleIdByName('Forest');
        expect(assetBundle.loadCount, equals(1));
      });

      test('deduplicates concurrent lookups into a single load', () async {
        final results = await Future.wait([
          client.getOracleIdByName('Forest'),
          client.getOracleIdByName("Atraxa, Praetors' Voice"),
        ]);
        expect(results, equals(['oracle-forest', 'oracle-atraxa']));
        expect(assetBundle.loadCount, equals(1));
      });
    });

    group('searchCards', () {
      test('returns cards whose names contain the query', () async {
        final result = await client.searchCards('atraxa');
        expect(result.totalCards, equals(1));
        expect(result.data.single.name, equals("Atraxa, Praetors' Voice"));
      });

      test('returns an empty result set when nothing matches', () async {
        final result = await client.searchCards('zzzzz');
        expect(result.totalCards, equals(0));
        expect(result.data, isEmpty);
      });

      test('caches the parsed card list across searches', () async {
        await client.searchCards('atraxa');
        await client.searchCards('forest');
        expect(assetBundle.loadCount, equals(1));
      });

      test('decodes json with a utf8 byte order that round-trips', () async {
        // Sanity check that byte-level decoding matches the fixture contents.
        final fixture =
            jsonDecode(
                  File(
                    'test/src/fixtures/cards_fixture.json',
                  ).readAsStringSync(),
                )
                as List<dynamic>;
        final result = await client.searchCards('');
        expect(result.totalCards, equals(fixture.length));
      });
    });
  });
}
