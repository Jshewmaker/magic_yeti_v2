import 'package:api_client/api_client.dart';
import 'package:magic_yeti/app/app.dart';
import 'package:magic_yeti/bootstrap.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

void main() async {
  await bootstrap(() async {
    final apiClient = ApiClient(
      baseUrl: 'https://api.scryfall.com',
    );

    final scryfallRepository = ScryfallRepository(apiClient: apiClient);
    return App(
      apiClient: apiClient,
      scryfallRepository: scryfallRepository,
    );
  });
}
