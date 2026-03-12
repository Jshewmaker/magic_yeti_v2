import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:flutter/services.dart';

/// {@template scryfall_bulk_client}
/// Client for searching the locally bundled Scryfall bulk data asset.
///
/// Parses and caches the unique-artwork bulk data JSON on first use,
/// then provides fast in-memory card name search.
/// {@endtemplate}
class ScryfallBulkClient {
  /// {@macro scryfall_bulk_client}
  ScryfallBulkClient({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  static const _assetPath =
      'packages/scryfall_bulk_client/assets/cards/unique-artwork-20260223220632.json';

  List<MagicCard>? _cachedCards;

  /// Loads and caches the bulk data asset on first call.
  Future<List<MagicCard>> _loadCards() async {
    if (_cachedCards != null) return _cachedCards!;
    final jsonString = await _assetBundle.loadString(_assetPath);
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    _cachedCards = jsonList
        .map((e) => MagicCard.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cachedCards!;
  }

  /// Searches the local bulk data for cards whose name contains [query].
  ///
  /// Returns a [SearchCards] object compatible with the rest of the data layer.
  /// Returns an empty result set if no cards match.
  Future<SearchCards> searchCards(String query) async {
    final cards = await _loadCards();
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
}
