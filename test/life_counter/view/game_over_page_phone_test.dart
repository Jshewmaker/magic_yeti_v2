import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/game_tags/game_tags.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/view/game_over_page.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/pump_app.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

class _MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _FakeGameModel extends Fake implements GameModel {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeGameModel()));

  group('GameOverView on a phone', () {
    late _MockAppBloc appBloc;
    late _MockGameBloc gameBloc;
    late _MockTimerBloc timerBloc;
    late PlayerRepository playerRepository;

    const base = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    final gameModel = GameModel(
      players: const [],
      startTime: DateTime(2024),
      endTime: DateTime(2024),
      winnerId: 'host-slot',
      durationInSeconds: 60,
    );

    List<Player> playersFor(int count) => [
      base.copyWith(
        id: 'host-slot',
        name: 'Host Player',
        firebaseId: () => 'host',
        placement: const Value(1),
      ),
      base.copyWith(
        id: 'slot-2',
        name: 'Second Player',
        placement: const Value(2),
      ),
      if (count == 4) ...[
        base.copyWith(
          id: 'slot-3',
          name: 'Third Player',
          placement: const Value(3),
        ),
        base.copyWith(
          id: 'slot-4',
          name: 'Fourth Player',
          placement: const Value(4),
        ),
      ],
    ];

    setUp(() {
      appBloc = _MockAppBloc();
      gameBloc = _MockGameBloc();
      timerBloc = _MockTimerBloc();
      playerRepository = PlayerRepository();

      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'host')),
      );
      when(() => gameBloc.state).thenReturn(GameState(gameModel: gameModel));
      when(() => timerBloc.state).thenReturn(
        const TimerState(elapsedSeconds: 60),
      );
    });

    Future<GameOverBloc> pumpPhoneView(
      WidgetTester tester, {
      int playerCount = 4,
      List<Player>? players,
      Size physicalSize = const Size(390, 844),
      double textScale = 1,
      EdgeInsets viewPadding = EdgeInsets.zero,
    }) async {
      tester.view.physicalSize = physicalSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = GameOverBloc(
        players: players ?? playersFor(playerCount),
        currentUserId: 'host',
        firebaseDatabaseRepository: _MockFirebaseDatabaseRepository(),
      );
      addTearDown(bloc.close);

      await tester.pumpApp(
        MediaQuery(
          data: MediaQueryData(
            size: physicalSize,
            textScaler: TextScaler.linear(textScale),
            padding: viewPadding,
          ),
          child: DeviceInfoProvider(
            isPhone: true,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AppBloc>.value(value: appBloc),
                BlocProvider<GameBloc>.value(value: gameBloc),
                BlocProvider<TimerBloc>.value(value: timerBloc),
                BlocProvider<GameOverBloc>.value(value: bloc),
              ],
              child: RepositoryProvider<PlayerRepository>.value(
                value: playerRepository,
                child: const GameOverView(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return bloc;
    }

    testWidgets('renders a 4-player game without overflow', (tester) async {
      await pumpPhoneView(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a 2-player game without overflow', (tester) async {
      await pumpPhoneView(tester, playerCount: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('pins the action bar without scrolling', (tester) async {
      await pumpPhoneView(tester);

      expect(find.byType(GameOverActionBar), findsOneWidget);
      // Not just present somewhere in the tree — anchored to the bottom of
      // the 844pt-tall viewport, outside the scrollable body. The bar's
      // surface fill lives on the wrapping Container (see Fix 1), so that's
      // what must reach the bottom edge, not the bare GameOverActionBar.
      expect(
        tester
            .getBottomLeft(
              find.byKey(const Key('game_over_phone_action_bar_container')),
            )
            .dy,
        844,
      );
    });

    testWidgets(
      'the action bar fill runs past a home-indicator inset, but its '
      'buttons still clear it',
      (tester) async {
        // Fix 5: _PhoneShell used a plain SafeArea, so the action bar's
        // Container stopped above the home indicator and the scaffold's
        // darker background showed through that strip. SafeArea(bottom:
        // false) plus adding the inset to the bar's own bottom padding
        // should let the surface fill reach the true screen edge while
        // the buttons inside still sit above the indicator.
        const bottomInset = 34.0; // Typical iPhone home-indicator height.
        await pumpPhoneView(
          tester,
          viewPadding: const EdgeInsets.only(bottom: bottomInset),
        );

        final containerRect = tester.getRect(
          find.byKey(const Key('game_over_phone_action_bar_container')),
        );
        expect(containerRect.bottom, 844);

        // The primary button is the last widget before the bar's own
        // bottom padding — its bottom edge must clear the indicator.
        final buttonBottom = tester.getRect(find.byType(ElevatedButton)).bottom;
        expect(buttonBottom, lessThanOrEqualTo(844 - bottomInset));
      },
    );

    testWidgets(
      'the drag-indicator icon carries a "Drag to reorder" tooltip, '
      'matching the tablet',
      (tester) async {
        // Fix 4: the phone previously passed a bare Icon as the section
        // label's trailing widget, with no way to discover the reorder
        // gesture. The tablet already wraps the same icon in a Tooltip
        // (see GameOverStandingsPanel) — the phone should carry the exact
        // same affordance.
        await pumpPhoneView(tester);

        final tooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.byIcon(Icons.drag_indicator_rounded),
            matching: find.byType(Tooltip),
          ),
        );
        expect(tooltip.message, 'Drag to reorder');
      },
    );

    testWidgets('does not use the tablet two-column row', (tester) async {
      await pumpPhoneView(tester);

      expect(find.byType(GameOverStandingsPanel), findsNothing);
      expect(find.byType(GameOverDetailsPanel), findsNothing);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('scrolling reveals the match details fields', (tester) async {
      await pumpPhoneView(tester);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FirstPlayerDropdown), findsOneWidget);
      expect(
        find.byKey(const ValueKey('game_over_account_owner_dropdown')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('every standing row is reachable by scrolling', (tester) async {
      // A shorter viewport than the other tests: at the default 844pt
      // height, "Fourth Player" already lands on screen at rest (its rect
      // ends at y=649.5, and the pinned action bar only starts at y=669),
      // so scrollUntilVisible would exit on its first poll without ever
      // scrolling — proving nothing. At 700pt the fourth row's sliver isn't
      // built at all until the list actually scrolls.
      await pumpPhoneView(tester, physicalSize: const Size(390, 700));

      expect(find.text('Fourth Player'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Fourth Player'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Fourth Player'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dragging a grip reorders the standings', (tester) async {
      final bloc = await pumpPhoneView(tester);

      // ReorderableDragStartListener starts an immediate drag, so no
      // long-press wait. The first small move exceeds touch slop; the total
      // drag (250 logical pixels) clears more than two 98pt row slots
      // (height 90 + 8 margin), so the drop lands unambiguously on the last
      // slot rather than straddling a swap boundary.
      final firstGrip = find.byType(ReorderableDragStartListener).first;
      final gesture = await tester.startGesture(tester.getCenter(firstGrip));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 220));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // Dragging the host (originally placement 1) all the way down moves it
      // behind every other standing, verifying the exact resulting order —
      // not merely that something changed. This also proves the phone shell
      // dispatches the raw oldIndex/newIndex straight through to
      // GameOverBloc._onUpdateStandings without adding a second
      // pre-removal-index adjustment (see the brief's warning): if the shell
      // *did* double-adjust, this drag would land one slot short of the end.
      expect(
        bloc.state.standings.map((p) => p.id).toList(),
        ['slot-2', 'slot-3', 'slot-4', 'host-slot'],
      );
    });

    testWidgets('a long player name ellipsizes rather than overflowing', (
      tester,
    ) async {
      await pumpPhoneView(
        tester,
        players: [
          base.copyWith(
            id: 'host-slot',
            name: 'Bartholomew Maximilian Featherstonehaugh The Third',
            firebaseId: () => 'host',
            placement: const Value(1),
          ),
          base.copyWith(
            id: 'slot-2',
            name: 'Second Player',
            placement: const Value(2),
          ),
        ],
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders a 4-player game without overflow at a larger text scale',
      (tester) async {
        // Pins the GameOverSectionLabel fix: its "FINAL STANDINGS" label (with
        // a trailing drag icon) previously had no Flexible/ellipsis and
        // overflowed the 358pt-wide row at this exact width/scale combination
        // once the label's text scaled up. Deleting that Flexible wrap should
        // turn this test red.
        await pumpPhoneView(tester, textScale: 2);

        expect(tester.takeException(), isNull);
      },
    );

    group('tags', () {
      testWidgets('tapping a game tag pill toggles the tag', (tester) async {
        final bloc = await pumpPhoneView(tester);
        final pill = find.byKey(const ValueKey('tag_pill_bracket_3'));

        await tester.scrollUntilVisible(
          pill,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // scrollUntilVisible stops once the pill is built, which can still
        // be below the fold; bring it fully on screen before the tap.
        await tester.ensureVisible(pill);
        await tester.pumpAndSettle();
        await tester.tap(pill);
        await tester.pump();

        expect(bloc.state.gameTags, contains(GameTag.bracket3.id));
      });

      testWidgets('explains the tags that the app selected', (tester) async {
        await pumpPhoneView(tester);
        final hint = find.text(
          'Some tags were selected from the game data. '
          'Tap a tag to clear it.',
        );

        await tester.scrollUntilVisible(
          hint,
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(hint, findsOneWidget);
      });

      testWidgets(
        'the row tag button opens the sheet, and a tap there tags the player',
        (tester) async {
          final bloc = await pumpPhoneView(tester);

          await tester.tap(
            find.byKey(const ValueKey('edit_player_tags_host-slot')),
          );
          await tester.pumpAndSettle();

          expect(find.text('Tags for Host Player'), findsOneWidget);

          await tester.tap(find.byKey(const ValueKey('tag_pill_t1_sol_ring')));
          await tester.pump();

          final host = bloc.state.standings.firstWhere(
            (p) => p.id == 'host-slot',
          );
          expect(host.tags, contains(GameTag.t1SolRing.id));

          expect(find.text('Save'), findsOneWidget);
          await tester.tap(find.byKey(const Key('player_tags_sheet_done')));
          await tester.pumpAndSettle();

          expect(find.text('Tags for Host Player'), findsNothing);
          // The row now shows the new tag.
          expect(find.text('Turn 1 Sol Ring'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'rows with many tags and long commander names do not overflow '
        'at 2x text scale',
        (tester) async {
          const commander = Commander(
            name: 'Kenrith, the Returned King of the Very Long Name',
            colors: ['W'],
            cardType: 'Legendary Creature',
            imageUrl: '',
            manaCost: '{W}',
            oracleText: '',
            artist: 'Artist',
          );
          final players = [
            for (final player in playersFor(4))
              player.copyWith(
                commander: commander,
                tags: [
                  for (final tag in GameTagGroup.mana.tags) tag.id,
                  GameTag.commanderTax6.id,
                ],
              ),
          ];

          await pumpPhoneView(tester, players: players, textScale: 2);

          expect(find.text('+3'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}
