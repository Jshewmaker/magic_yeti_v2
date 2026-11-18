import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../../../helpers/pump_app.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _FakeGameModel extends Fake implements GameModel {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeGameModel()));

  group('GameOverDetailsPanel action bar', () {
    const player1 = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
      // The account-owner slot must already be resolved so that setting
      // firstPlayerId alone is enough to flip canSubmit to true.
      firebaseId: 'p1',
    );
    final player2 = player1.copyWith(
      id: 'p2',
      name: 'Player Two',
      placement: const Value(2),
    );

    final gameModel = GameModel(
      players: const [],
      startTime: DateTime(2024),
      endTime: DateTime(2024),
      winnerId: 'p1',
      durationInSeconds: 60,
    );

    late _MockAppBloc appBloc;

    setUp(() {
      appBloc = _MockAppBloc();
      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'p1')),
      );
    });

    // Builds a real GameOverBloc inline (not via a shared setUp/late field).
    // A real Bloc's internal event-stream subscription is created in
    // whatever zone is active at construction time; setUp() runs outside
    // the special zone flutter_test wraps the testWidgets body in, so a
    // bloc built there silently stops notifying BlocBuilder even though
    // bloc.state updates correctly. Building it inside the test body avoids
    // the mismatch.
    //
    // saveCompleter is left uncompleted so a dispatched save is observed
    // mid-flight in GameOverStatus.loading rather than racing ahead to
    // success. Tests that use it must complete it (and pumpAndSettle)
    // before finishing, or bloc.close() in tearDown hangs waiting for the
    // in-flight handler.
    GameOverBloc buildGameOverBloc(Completer<String> saveCompleter) {
      final firebaseDatabaseRepository = _MockFirebaseDatabaseRepository();
      when(
        () => firebaseDatabaseRepository.saveGameStats(any()),
      ).thenAnswer((_) => saveCompleter.future);
      return GameOverBloc(
        players: [player1, player2],
        currentUserId: 'p1',
        firebaseDatabaseRepository: firebaseDatabaseRepository,
      );
    }

    Future<void> pumpPanel(
      WidgetTester tester,
      GameOverBloc bloc, {
      double? width,
      double textScale = 1,
    }) async {
      // Mirrors production: GameOverDetailsPanel is a dumb widget fed by an
      // outer BlocBuilder (see _TabletShell), not a self-updating consumer.
      Widget panel = BlocBuilder<GameOverBloc, GameOverState>(
        builder: (context, state) => GameOverDetailsPanel(
          state: state,
          players: state.standings,
          gameModel: gameModel,
        ),
      );
      if (width != null) {
        // The test *window* itself must actually be tall enough — a
        // SizedBox height request is clipped to whatever bounded max the
        // Scaffold body already has from the (unresized) test viewport.
        // Only width is meant to be under test here: the full tablet page
        // has a separate, pre-existing vertical overflow at 2x text scale
        // (GameOverDetailsFields outgrowing the fixed-height flex row) —
        // real, but unrelated to Fix 2 and out of scope here (see the fix
        // report). A short viewport would trip that bug too and fail this
        // test for the wrong reason.
        tester.view.physicalSize = Size(width + 100, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        panel = Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: panel),
        );
      }

      await tester.pumpApp(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppBloc>.value(value: appBloc),
              BlocProvider<GameOverBloc>.value(value: bloc),
            ],
            child: Scaffold(body: panel),
          ),
        ),
      );
      await tester.pump();
    }

    // Fix 1: the tablet details panel used to hand-roll its own hint + Row
    // of buttons instead of reusing GameOverActionBar. Before the fix,
    // GameOverActionBar simply never appeared under GameOverDetailsPanel —
    // this assertion is the RED phase (findsNothing pre-fix,
    // findsOneWidget post-fix).
    testWidgets(
      'renders the shared GameOverActionBar in side-by-side mode',
      (tester) async {
        final bloc = buildGameOverBloc(Completer<String>());
        addTearDown(bloc.close);

        await pumpPanel(tester, bloc);

        final actionBar = tester.widget<GameOverActionBar>(
          find.byType(GameOverActionBar),
        );
        expect(actionBar.stacked, isFalse);
      },
    );

    testWidgets('shows the game tags, and a tap toggles one', (tester) async {
      final bloc = buildGameOverBloc(Completer<String>());
      addTearDown(bloc.close);

      await pumpPanel(tester, bloc);
      final pill = find.byKey(const ValueKey('tag_pill_bracket_5'));
      await tester.ensureVisible(pill);
      await tester.pumpAndSettle();
      await tester.tap(pill);
      await tester.pump();

      expect(bloc.state.gameTags, contains('bracket_5'));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'tapping return home dispatches SendGameOverStatsEvent with home '
      'intent, reusing the same dispatch the panel used to inline',
      (tester) async {
        final saveCompleter = Completer<String>();
        final bloc = buildGameOverBloc(saveCompleter);
        addTearDown(bloc.close);

        await pumpPanel(tester, bloc);
        bloc.add(const UpdateFirstPlayerEvent('p1'));
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Return to Home'));
        await tester.pump();

        expect(bloc.state.status, GameOverStatus.loading);
        expect(bloc.state.exitIntent, GameOverExitIntent.home);

        saveCompleter.complete('saved-id');
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'tapping play again dispatches SendGameOverStatsEvent with '
      'playAgain intent',
      (tester) async {
        final saveCompleter = Completer<String>();
        final bloc = buildGameOverBloc(saveCompleter);
        addTearDown(bloc.close);

        await pumpPanel(tester, bloc);
        bloc.add(const UpdateFirstPlayerEvent('p1'));
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Play Again'));
        await tester.pump();

        expect(bloc.state.status, GameOverStatus.loading);
        expect(bloc.state.exitIntent, GameOverExitIntent.playAgain);

        saveCompleter.complete('saved-id');
        await tester.pumpAndSettle();
      },
    );

    // Fix 2: before Fix 1, the tablet's hint was a bare Row(icon, Text)
    // with no Flexible — at the real ~549pt-wide flex:4-of-9 tablet column
    // and 2x text scale, that overflows horizontally. Wiring the panel to
    // GameOverActionBar (Fix 1) pulls in GameOverRequiredHint, whose
    // Flexible-wrapped Text absorbs the extra width. Width matches the
    // GameOverDetailsPanel's real embedding: (1280 - 16 - 16 - 12) * 4 / 9.
    testWidgets(
      'hint does not overflow horizontally at the real tablet width and '
      '2x text scale',
      (tester) async {
        final bloc = buildGameOverBloc(Completer<String>());
        addTearDown(bloc.close);

        await pumpPanel(tester, bloc, width: 549, textScale: 2);

        expect(find.text('Fill out both fields to continue'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
