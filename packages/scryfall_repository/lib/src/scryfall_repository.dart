import 'package:api_client/api_client.dart';
import 'package:scryfall_bulk_client/scryfall_bulk_client.dart';

/// {@template scryfall_repository}
/// Repository for Scryfall API
/// {@endtemplate}
class ScryfallRepository {
  /// {@macro scryfall_repository}
  ScryfallRepository({ApiClient? apiClient, ScryfallBulkClient? bulkClient})
      : _apiClient =
            apiClient ?? ApiClient(baseUrl: 'https://api.scryfall.com'),
        _bulkClient = bulkClient ?? ScryfallBulkClient();

  final ApiClient _apiClient;
  final ScryfallBulkClient _bulkClient;

  /// Looks up the oracle ID for a commander name using the local bulk data.
  ///
  /// Returns `null` if the card is not found.
  Future<String?> getOracleIdByName(String cardName) async {
    return _bulkClient.getOracleIdByName(cardName);
  }

  /// Retrieves full text search results for a specific card name.
  ///
  /// Searches the local bulk data asset first. If no results are found,
  /// falls back to the Scryfall API.
  ///
  /// Filters out cards with missing images and normalizes double-faced card
  /// image URIs before returning.
  Future<SearchCards> getCardFullText({required String cardName}) async {
    final localResults = await _bulkClient.searchCards(cardName);
    if (localResults.data.isNotEmpty) {
      return _normalizeCards(localResults);
    }

    final apiResults = await _apiClient.getCardFullText(cardName);
    return _normalizeCards(apiResults);
  }

  SearchCards _normalizeCards(SearchCards cards) {
    final filtered = cards.data
        .where(
          (card) =>
              !(card.imageStatus == 'missing' && card.imageUris == null),
        )
        .toList();

    final normalizedData = filtered.map((card) {
      if (card.imageUris == null) {
        final faceImageUris = card.cardFaces?.first.imageUris;
        if (faceImageUris != null) {
          return card.copyWith(imageUris: faceImageUris);
        }
      }
      return card;
    }).toList();

    return SearchCards(
      object: cards.object,
      totalCards: normalizedData.length,
      hasMore: cards.hasMore,
      nextPage: cards.nextPage,
      data: normalizedData,
    );
  }
}
