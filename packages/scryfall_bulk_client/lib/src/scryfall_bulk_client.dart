import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// {@template scryfall_bulk_client}
/// Client for searching the locally bundled Scryfall bulk data asset.
///
/// The bulk data asset is very large (hundreds of MB), so all JSON decoding
/// and model parsing happens on a background isolate via [compute]. Only the
/// results (a name → oracle-id index, or the parsed card list) are retained
/// on the main isolate, and each is loaded at most once.
/// {@endtemplate}
class ScryfallBulkClient {
  /// {@macro scryfall_bulk_client}
  ScryfallBulkClient({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  static const _assetPath =
      'packages/scryfall_bulk_client/assets/cards/unique-artwork-20260223220632.json';

  /// Lazily-built index of lowercase card name → oracle id.
  ///
  /// Kept separate from [_cardsFuture] so name lookups (used by stats) don't
  /// pin the full parsed card list in memory.
  Future<Map<String, String>>? _nameIndexFuture;

  /// Lazily-parsed full card list, used by [searchCards].
  Future<List<MagicCard>>? _cardsFuture;

  /// Finds a card by exact name (case-insensitive) and returns its oracle ID.
  ///
  /// Returns `null` if no card matches the exact name.
  Future<String?> getOracleIdByName(String cardName) async {
    _nameIndexFuture ??= _buildNameIndex();
    final index = await _nameIndexFuture!;
    return index[cardName.toLowerCase()];
  }

  /// Searches the local bulk data for cards whose name contains [query].
  ///
  /// Returns a [SearchCards] object compatible with the rest of the data
  /// layer. Returns an empty result set if no cards match.
  Future<SearchCards> searchCards(String query) async {
    _cardsFuture ??= _parseCards();
    final cards = await _cardsFuture!;
    final lowerQuery = query.toLowerCase();
    final matches = cards
        .where((card) => card.name.toLowerCase().contains(lowerQuery))
        .toList();
    return SearchCards(
      object: 'list',
      totalCards: matches.length,
      hasMore: false,
      nextPage: null,
      data: matches,
    );
  }

  Future<Map<String, String>> _buildNameIndex() async {
    final data = await _assetBundle.load(_assetPath);
    return compute(_decodeNameIndex, data);
  }

  Future<List<MagicCard>> _parseCards() async {
    final data = await _assetBundle.load(_assetPath);
    return compute(_decodeCards, data);
  }

  static List<dynamic> _decodeJsonList(ByteData data) {
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return jsonDecode(utf8.decode(bytes)) as List<dynamic>;
  }

  /// Isolate entry point: decodes the bulk JSON and returns only the
  /// name → oracle-id index, letting the raw card data be garbage collected
  /// with the isolate.
  static Map<String, String> _decodeNameIndex(ByteData data) {
    final jsonList = _decodeJsonList(data);
    return {
      for (final entry in jsonList.cast<Map<String, dynamic>>())
        if (entry
            case {
              'name': final String name,
              'oracle_id': final String oracleId,
            })
          name.toLowerCase(): oracleId,
    };
  }

  /// Isolate entry point: decodes the bulk JSON into the full card list.
  static List<MagicCard> _decodeCards(ByteData data) {
    return _decodeJsonList(data)
        .map((e) => MagicCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
