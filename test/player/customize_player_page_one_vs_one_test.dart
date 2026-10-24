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
import 'package:magic_yeti/player/view/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../helpers/pump_app.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class _MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

class _MockPlayerRepository extends Mock implements PlayerRepository {}

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

const _player = Player(
  id: 'p1',
  name: 'Sarah',
  playerNumber: 0,
  lifePoints: 20,
  color: 0xFF378ADD,
  opponents: [],
  state: PlayerModelState.active,
);

void main() {
  group('CustomizePlayerView in a two-player game', () {
    late _MockAppBloc appBloc;
    late _MockFriendBloc friendBloc;
    late _MockPlayerBloc playerBloc;
    late _MockPlayerRepository playerRepository;

    setUp(() {
      appBloc = _MockAppBloc();
      friendBloc = _MockFriendBloc();
      playerBloc = _MockPlayerBloc();
      playerRepository = _MockPlayerRepository();

      when(() => playerRepository.getPlayerById('p1')).thenReturn(_player);
      when(
        () => playerBloc.state,
      ).thenReturn(const PlayerState(player: _player));
      when(
        () => appBloc.state,
      ).thenReturn(const AppState.authenticated(User(id: 'alice')));
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([]));
    });

    Future<void> pumpPage(
      WidgetTester tester, {
      required Size size,
      bool isCommanderGame = false,
    }) async {
      tester.view.physicalSize = size;
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
                scryfallRepository: _MockScryfallRepository(),
                firebaseDatabaseRepository: _MockFirebaseDatabaseRepository(),
                commanderLibraryRepository: _FakeCommanderLibraryRepository(),
                isCommanderGame: isCommanderGame,
              ),
            ),
          ],
          child: RepositoryProvider<PlayerRepository>.value(
            value: playerRepository,
            child: CustomizePlayerView(
              playerId: 'p1',
              isCommanderGame: isCommanderGame,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('asks for a deck card, with no commander controls', (
      tester,
    ) async {
      await pumpPage(tester, size: const Size(375, 667));

      expect(find.text('Deck card'), findsOneWidget);
      expect(find.text('No card selected'), findsOneWidget);
      expect(find.text('Commander'), findsNothing);
      expect(find.byType(TrackingPreview), findsNothing);
      expect(find.byType(SegmentedButton<Object>), findsNothing);
      expect(
        find.widgetWithText(TextField, 'Search for a card'),
        findsOneWidget,
      );
    });

    testWidgets('stacks the panels on a small portrait phone', (tester) async {
      await pumpPage(tester, size: const Size(320, 568));

      final identityTop = tester.getTopLeft(find.byType(PlayerIdentityPanel));
      final pickerTop = tester.getTopLeft(find.byType(CommanderPickerPanel));
      expect(pickerTop.dy, greaterThan(identityTop.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the panels side by side in landscape', (tester) async {
      await pumpPage(
        tester,
        size: const Size(844, 390),
        isCommanderGame: true,
      );

      final identityLeft = tester.getTopLeft(find.byType(PlayerIdentityPanel));
      final pickerLeft = tester.getTopLeft(find.byType(CommanderPickerPanel));
      expect(pickerLeft.dx, greaterThan(identityLeft.dx));
      expect(find.text('Commander'), findsOneWidget);
    });
  });
}
