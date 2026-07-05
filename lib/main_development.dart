// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_app_config_repository/fake_app_config_repository.dart';
import 'package:firebase_authentication_client/firebase_authentication_client.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/app/app.dart';
import 'package:magic_yeti/bootstrap.dart';
import 'package:magic_yeti/commander_library/shared_preferences_commander_library_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  bootstrap(
    (FirebaseFirestore firebaseFirestore) async {
      final authenticationClient = FirebaseAuthenticationClient();
      final playerRepository = PlayerRepository();
      final firebaseDatabaseRepository = FirebaseDatabaseRepository(
        firebase: FirebaseFirestore.instance,
        functions: FirebaseFunctions.instance,
      );

      final userRepository = UserRepository(
        authenticationClient: authenticationClient,
        firebaseDatabaseRepository: firebaseDatabaseRepository,
      );
      final scryfallRepository = ScryfallRepository();
      final commanderLibraryRepository =
          SharedPreferencesCommanderLibraryRepository(
        await SharedPreferences.getInstance(),
      );
      final user = await userRepository.user.first;
      final appConfigRepository = FakeAppConfigRepository();
      playerRepository.init();
      return App(
        userRepository: userRepository,
        user: user,
        firebaseDatabaseRepository: firebaseDatabaseRepository,
        scryfallRepository: scryfallRepository,
        appConfigRepository: appConfigRepository,
        playerRepository: playerRepository,
        commanderLibraryRepository: commanderLibraryRepository,
      );
    },
  );
}
