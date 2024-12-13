import 'package:api_client/api_client.dart';

/// {@template scryfall_repository}
/// Repository for Scryfall API
/// {@endtemplate}
class ScryfallRepository {
  /// {@macro scryfall_repository}
  ScryfallRepository({ApiClient? apiClient})
      : _apiClient =
            apiClient ?? ApiClient(baseUrl: 'https://api.scryfall.com');

  final ApiClient _apiClient;

  /// Retrieves full text search results for a specific card name from Scryfall API.
  ///
  /// This method performs a full-text search for a card and filters out cards with:
  /// - Missing image status
  /// - Null image URIs
  ///
  /// [cardName] The name of the card to search for.
  ///
  /// Returns a [SearchCards] object containing filtered card results.
  ///
  /// Filters out cards that do not have valid images to ensure only
  /// displayable cards are returned.
  ///
  /// Throws an exception if the API call fails or network issues occur.
  Future<SearchCards> getCardFullText({required String cardName}) async {
    final cards = await _apiClient.getCardFullText(cardName);
    cards.data.removeWhere(
      (element) =>
          element.imageStatus == 'missing' || element.imageUris == null,
    );

    return cards;
  }
}
