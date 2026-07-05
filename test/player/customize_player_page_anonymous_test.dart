import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/customize_player_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../helpers/pump_app.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockScryfallRepository extends Mock implements ScryfallRepository {}

class MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class FakeCommanderLibraryRepository implements CommanderLibraryRepository {
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
  group('CustomizePlayerView anonymous placeholder', () {
    late MockAppBloc appBloc;
    late MockFriendBloc friendBloc;
    late MockPlayerBloc playerBloc;
    late MockPlayerRepository playerRepository;

    const player = Player(
      id: 'p1',
      name: 'Sarah',
      playerNumber: 0,
      lifePoints: 40,
      color: 0xFF378ADD,
      opponents: [],
      state: PlayerModelState.active,
    );

    const bob = FriendModel(
      userId: 'bob',
      username: 'Bob',
      profilePictureUrl: 'http://x/bob.png',
      friendCode: 'YETI-B0B1',
    );

    setUp(() {
      appBloc = MockAppBloc();
      friendBloc = MockFriendBloc();
      playerBloc = MockPlayerBloc();
      playerRepository = MockPlayerRepository();

      when(() => playerRepository.getPlayerById('p1')).thenReturn(player);
      when(() => playerBloc.state)
          .thenReturn(const PlayerState(player: player));
    });

    Future<void> pumpCustomizePlayer(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<FriendBloc>.value(value: friendBloc),
            BlocProvider<PlayerBloc>.value(value: playerBloc),
            BlocProvider<PlayerCustomizationBloc>(
              create: (context) => PlayerCustomizationBloc(
                scryfallRepository: MockScryfallRepository(),
                firebaseDatabaseRepository: MockFirebaseDatabaseRepository(),
                commanderLibraryRepository: FakeCommanderLibraryRepository(),
              ),
            ),
          ],
          child: RepositoryProvider<PlayerRepository>.value(
            value: playerRepository,
            child: const CustomizePlayerView(playerId: 'p1'),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
        'shows signInToLinkFriends copy instead of the friend list '
        'when anonymous', (tester) async {
      when(() => appBloc.state).thenReturn(
        const AppState.anonymous(User(id: 'anon1')),
      );
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([bob]));

      await pumpCustomizePlayer(tester);

      expect(find.text('Sign in to link friends to players.'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
    });

    testWidgets(
        'shows the friend list (not the anonymous placeholder) '
        'when authenticated', (tester) async {
      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'alice')),
      );
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([bob]));

      await pumpCustomizePlayer(tester);

      expect(
        find.text('Sign in to link friends to players.'),
        findsNothing,
      );
      expect(find.text('Bob'), findsOneWidget);
    });
  });
}
