// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_app_config_repository/fake_app_config_repository.dart';
import 'package:firebase_authentication_client/firebase_authentication_client.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/app/app.dart';
import 'package:magic_yeti/bootstrap.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  bootstrap(
    (FirebaseFirestore firebaseFirestore) async {
      final authenticationClient = FirebaseAuthenticationClient();

      final firebaseDatabaseRepository = FirebaseDatabaseRepository(
        firebase: FirebaseFirestore.instance,
      );
      final userRepository = UserRepository(
        authenticationClient: authenticationClient,
        firebaseDatabaseRepository: firebaseDatabaseRepository,
      );

      final scryfallRepository = ScryfallRepository();
      final user = await userRepository.user.first;
      final appConfigRepository = FakeAppConfigRepository();
      final playerRepository = PlayerRepository()..init();
      return App(
        userRepository: userRepository,
        user: user,
        firebaseDatabaseRepository: firebaseDatabaseRepository,
        scryfallRepository: scryfallRepository,
        appConfigRepository: appConfigRepository,
        playerRepository: playerRepository,
      );
    },
  );
}
