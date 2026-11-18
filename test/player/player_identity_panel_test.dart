import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/player_identity_panel.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class _MockScryfall extends Mock implements ScryfallRepository {}

class _MockDb extends Mock implements FirebaseDatabaseRepository {}

class _FakeLibrary implements CommanderLibraryRepository {
  @override
  Future<void> addRecent(Commander c) async {}
  @override
  Future<List<Commander>> getRecents() async => [];
  @override
  Future<List<Commander>> getFavorites() async => [];
  @override
  Future<bool> isFavorite(Commander c) async => false;
  @override
  Future<bool> toggleFavorite(Commander c) async => false;
}

void main() {
  testWidgets(
    'PlayerIdentityPanel lays out inside an unbounded-height scroll view',
    (tester) async {
      final bloc = PlayerCustomizationBloc(
        scryfallRepository: _MockScryfall(),
        firebaseDatabaseRepository: _MockDb(),
        commanderLibraryRepository: _FakeLibrary(),
      );
      addTearDown(bloc.close);

      final nameController = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(nameController.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider.value(
                value: bloc,
                child: PlayerIdentityPanel(
                  nameController: nameController,
                  nameFocusNode: focusNode,
                  playerColor: 0xFF378ADD,
                  onSave: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Before the fix this threw a RenderFlex unbounded-height assertion.
      expect(tester.takeException(), isNull);
      expect(find.byType(PlayerIdentityPanel), findsOneWidget);
    },
  );
}
