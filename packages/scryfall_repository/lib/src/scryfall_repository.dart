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

  Future<SearchCards> getCardFullText({required String cardName}) async {
    final cards = await _apiClient.getCardFullText(cardName);
    cards.data.removeWhere(
      (element) =>
          element.imageStatus == 'missing' || element.imageUris == null,
    );

    return cards;
  }
}
