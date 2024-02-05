import 'package:api_client/api_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/app/app.dart';
import 'package:magic_yeti/bootstrap.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

void main() async {
  await bootstrap(() async {
    final apiClient = ApiClient(
      baseUrl: 'https://api.scryfall.com',
    );

    final firebaseDatabase =
        FirebaseDatabaseRepository(firebase: FirebaseFirestore.instance);
    final scryfallRepository = ScryfallRepository(apiClient: apiClient);
    return App(
      apiClient: apiClient,
      firebaseDatabaseRepository: firebaseDatabase,
      scryfallRepository: scryfallRepository,
    );
  });
}
