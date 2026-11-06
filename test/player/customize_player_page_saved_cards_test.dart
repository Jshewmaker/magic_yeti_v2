import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/customize_player_page.dart';
import 'package:magic_yeti/player/view/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../helpers/pump_app.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockScryfallRepository extends Mock implements ScryfallRepository {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _FakeCommanderLibraryRepository implements CommanderLibraryRepository {
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

Commander _card(String name, {List<String> keywords = const []}) => Commander(
  name: name,
  colors: const [],
  cardType: 'Legendary Creature',
  imageUrl: 'https://example.com/$name.jpg',
  manaCost: '',
  oracleText: '',
  artist: '',
  keywords: keywords,
);

void main() {
  group('CustomizePlayerPage with saved cards', () {
    final thrasios = _card('Thrasios', keywords: const ['Partner']);
    final tymna = _card('Tymna', keywords: const ['Partner']);

    late PlayerRepository repository;
    late PlayerBloc playerBloc;
    late _MockAppBloc appBloc;
    late _MockFirebaseDatabaseRepository database;

    setUp(() {
      appBloc = _MockAppBloc();
      database = _MockFirebaseDatabaseRepository();
      when(
        () => appBloc.state,
      ).thenReturn(const AppState.authenticated(User(id: 'alice')));
      when(
        () => database.watchFriends(any()),
      ).thenAnswer((_) => const Stream.empty());
    });

    Future<void> openPage(
      WidgetTester tester, {
      Commander? partner,
      Commander? background,
    }) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      repository = PlayerRepository()
        ..createPlayer(
          Player(
            id: 'p1',
            name: 'Sarah',
            playerNumber: 0,
            lifePoints: 40,
            color: 0xFF378ADD,
            opponents: const [],
            state: PlayerModelState.active,
            commander: thrasios,
            partner: partner,
            background: background,
          ),
        );
      playerBloc = PlayerBloc(playerRepository: repository, playerId: 'p1');
      addTearDown(playerBloc.close);

      await tester.pumpApp(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<PlayerRepository>.value(value: repository),
            RepositoryProvider<ScryfallRepository>.value(
              value: _MockScryfallRepository(),
            ),
            RepositoryProvider<FirebaseDatabaseRepository>.value(
              value: database,
            ),
            RepositoryProvider<CommanderLibraryRepository>.value(
              value: _FakeCommanderLibraryRepository(),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppBloc>.value(value: appBloc),
              BlocProvider<PlayerBloc>.value(value: playerBloc),
            ],
            child: const CustomizePlayerPage(playerId: 'p1'),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> save(WidgetTester tester) async {
      final panel = tester.widget<PlayerIdentityPanel>(
        find.byType(PlayerIdentityPanel),
      );
      panel.onSave();
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a save with no card change keeps the partner', (tester) async {
      await openPage(tester, partner: tymna);

      await save(tester);

      expect(repository.getPlayerById('p1').partner, tymna);
      expect(repository.getPlayerById('p1').commander, thrasios);
    });

    testWidgets('a save with no card change keeps the background', (
      tester,
    ) async {
      final background = _card('Cult of Rakdos');
      await openPage(tester, background: background);

      await save(tester);

      expect(repository.getPlayerById('p1').background, background);
    });

    testWidgets('a saved partner commander can still add its partner', (
      tester,
    ) async {
      await openPage(tester);

      final context = tester.element(find.byType(PlayerIdentityPanel));
      expect(
        context.read<PlayerCustomizationBloc>().state.availablePairing,
        CommanderPairing.partner,
      );
    });
  });
}
