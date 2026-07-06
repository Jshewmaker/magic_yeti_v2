import 'dart:async';

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

const testPlayer = Player(
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
  profilePictureUrl: '',
  friendCode: 'YETI-B0B1',
);

void main() {
  group('CustomizePlayerView PIN dialog', () {
    late MockAppBloc appBloc;
    late MockFriendBloc friendBloc;
    late MockPlayerBloc playerBloc;
    late MockPlayerRepository playerRepository;
    late MockFirebaseDatabaseRepository db;

    setUp(() {
      appBloc = MockAppBloc();
      friendBloc = MockFriendBloc();
      playerBloc = MockPlayerBloc();
      playerRepository = MockPlayerRepository();
      db = MockFirebaseDatabaseRepository();

      when(() => playerRepository.getPlayerById('p1')).thenReturn(testPlayer);
      when(() => playerBloc.state)
          .thenReturn(const PlayerState(player: testPlayer));
      when(() => appBloc.state)
          .thenReturn(const AppState.authenticated(User(id: 'alice')));
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([bob]));
    });

    Future<void> pumpCustomizePlayer(
      WidgetTester tester, {
      Size size = const Size(1600, 1200),
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
                scryfallRepository: MockScryfallRepository(),
                firebaseDatabaseRepository: db,
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
        'Verify button shows a spinner while ValidatePin is pending and '
        'blocks re-submission', (tester) async {
      final completer = Completer<PinValidationResult>();
      when(() => db.validatePin(targetUserId: 'bob', pin: '1234'))
          .thenAnswer((_) => completer.future);

      await pumpCustomizePlayer(tester);
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Verify'), findsNothing);

      final verifyButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(verifyButton.onPressed, isNull);

      final cancelButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancelButton.onPressed, isNull);

      completer.complete(const PinValid());
      await tester.pumpAndSettle();
    });

    testWidgets(
        'PIN dialog is scrollable on small screens', (tester) async {
      when(() => db.validatePin(targetUserId: 'bob', pin: '1234'))
          .thenAnswer((_) async => const PinValid());

      await pumpCustomizePlayer(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);

      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Verify'),
        warnIfMissed: true,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
