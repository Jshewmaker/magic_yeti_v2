import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friend_stats/view/friend_stats_page.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:user_repository/user_repository.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockMatchHistoryBloc
    extends MockBloc<MatchHistoryEvent, MatchHistoryState>
    implements MatchHistoryBloc {}

Player _seat(
  String id,
  String firebaseId,
  int todMs, {
  String? commander,
  List<Opponent> opponents = const [],
}) => Player(
  id: id,
  name: 'Name-$id',
  playerNumber: 0,
  lifePoints: 40,
  color: 0xFF000000,
  opponents: opponents,
  placement: 1,
  timeOfDeath: todMs,
  firebaseId: firebaseId,
  commander: commander == null
      ? null
      : Commander(
          name: commander,
          colors: const ['G'],
          cardType: 'Legendary Creature',
          imageUrl: '',
          manaCost: '{G}',
          oracleText: '',
          artist: 'A',
        ),
);

/// A shared pod where `me` outlasts `friend` when [meAhead] is true.
GameModel _pod(String id, {required bool meAhead}) {
  final start = DateTime(2026, 1, 1, 12);
  final end = DateTime(2026, 1, 1, 14);
  final meTod = meAhead
      ? end.millisecondsSinceEpoch
      : start.millisecondsSinceEpoch + 1000;
  final friendTod = meAhead
      ? start.millisecondsSinceEpoch + 1000
      : end.millisecondsSinceEpoch;
  return GameModel(
    id: id,
    winnerId: meAhead ? 'me-seat' : 'friend-seat',
    startTime: start,
    endTime: end,
    durationInSeconds: 7200,
    players: [
      _seat('me-seat', 'me', meTod, commander: 'Krenko'),
      _seat('friend-seat', 'friend', friendTod, commander: 'Atraxa'),
    ],
  );
}

const _friend = FriendModel(
  userId: 'friend',
  username: 'Sam',
  profilePictureUrl: '',
  friendCode: '1234',
);

void main() {
  late AppBloc appBloc;
  late MatchHistoryBloc matchHistoryBloc;

  void stubHistory(List<GameModel> games) {
    final state = MatchHistoryState(
      status: MatchHistoryStatus.loadingHistorySuccess,
      userId: 'me',
      games: games,
    );
    when(() => matchHistoryBloc.state).thenReturn(state);
    whenListen(
      matchHistoryBloc,
      const Stream<MatchHistoryState>.empty(),
      initialState: state,
    );
  }

  setUp(() {
    appBloc = _MockAppBloc();
    matchHistoryBloc = _MockMatchHistoryBloc();
    when(
      () => appBloc.state,
    ).thenReturn(const AppState.authenticated(User(id: 'me')));
  });

  Widget buildSubject() {
    return MaterialApp(
      home: DeviceInfoProvider(
        isPhone: true,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<MatchHistoryBloc>.value(value: matchHistoryBloc),
          ],
          child: const FriendStatsPage(friendId: 'friend', friend: _friend),
        ),
      ),
    );
  }

  Widget buildTabletSubject() {
    return MaterialApp(
      home: DeviceInfoProvider(
        isPhone: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<MatchHistoryBloc>.value(value: matchHistoryBloc),
          ],
          child: const FriendStatsPage(friendId: 'friend', friend: _friend),
        ),
      ),
    );
  }

  testWidgets('renders head-to-head stats for the shared pods', (tester) async {
    stubHistory([
      _pod('1', meAhead: true),
      _pod('2', meAhead: true),
      _pod('3', meAhead: true),
      _pod('4', meAhead: false),
      _pod('5', meAhead: false),
    ]);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Header names the friend and the shared pod count.
    expect(find.text('Sam'), findsWidgets);
    expect(find.textContaining('5 pods together'), findsOneWidget);

    // Hero Ledger: me ahead in 3 of 5.
    expect(find.text('3–2'), findsOneWidget);

    // Secondary tiles are present.
    expect(find.text('Pods Won'), findsOneWidget);
    expect(find.text('Avg Time Alive'), findsOneWidget);
    expect(find.text('Their Go-To'), findsOneWidget);
  });

  testWidgets(
    'does not overflow at phone width with every tile showing, including '
    'The Beatdown, 21s, and a long commander name',
    (tester) async {
      // Phone-sized viewport — the crash this guards against only shows up
      // under the 2-column grid's real (bounded) cell height.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const longCommanderName = "Kroxa, Titan of Death's Hunger";
      final start = DateTime(2026, 1, 1, 12);
      final end = DateTime(2026, 1, 1, 14);

      GameModel podWith({required String id, List<Opponent>? friendTakes}) {
        return GameModel(
          id: id,
          winnerId: 'me-seat',
          startTime: start,
          endTime: end,
          durationInSeconds: 7200,
          players: [
            _seat('me-seat', 'me', end.millisecondsSinceEpoch),
            _seat(
              'friend-seat',
              'friend',
              start.millisecondsSinceEpoch + 1000,
              commander: longCommanderName,
              opponents: friendTakes ?? const [],
            ),
          ],
        );
      }

      stubHistory([
        // The first pod lands a lethal 21 from me onto the friend, and
        // clears the commander-damage-volume gate (>=21) in one shot —
        // this makes both "The Beatdown" and "21s" tiles render.
        podWith(
          id: '1',
          friendTakes: [
            Opponent(
              playerId: 'me-seat',
              damages: [
                CommanderDamage(damageType: DamageType.commander, amount: 21),
              ],
            ),
          ],
        ),
        podWith(id: '2'),
        podWith(id: '3'),
        podWith(id: '4'),
        podWith(id: '5'),
      ]);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Sanity: the long-caption tiles are actually present, so this test
      // exercises the overflow-prone cards rather than trivially passing.
      expect(find.text('The Beatdown'), findsOneWidget);
      expect(find.text('21s'), findsOneWidget);
      expect(find.text(longCommanderName), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'does not overflow at tablet width and renders the Wrap layout, not the '
    'phone grid, with every tile showing',
    (tester) async {
      // Wide viewport — exercises the tablet/wide AdaptiveLayout branch.
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const longCommanderName = "Kroxa, Titan of Death's Hunger";
      final start = DateTime(2026, 1, 1, 12);
      final end = DateTime(2026, 1, 1, 14);

      GameModel podWith({required String id, List<Opponent>? friendTakes}) {
        return GameModel(
          id: id,
          winnerId: 'me-seat',
          startTime: start,
          endTime: end,
          durationInSeconds: 7200,
          players: [
            _seat('me-seat', 'me', end.millisecondsSinceEpoch),
            _seat(
              'friend-seat',
              'friend',
              start.millisecondsSinceEpoch + 1000,
              commander: longCommanderName,
              opponents: friendTakes ?? const [],
            ),
          ],
        );
      }

      stubHistory([
        // The first pod lands a lethal 21 from me onto the friend, and
        // clears the commander-damage-volume gate (>=21) in one shot —
        // this makes both "The Beatdown" and "21s" tiles render.
        podWith(
          id: '1',
          friendTakes: [
            Opponent(
              playerId: 'me-seat',
              damages: [
                CommanderDamage(damageType: DamageType.commander, amount: 21),
              ],
            ),
          ],
        ),
        podWith(id: '2'),
        podWith(id: '3'),
        podWith(id: '4'),
        podWith(id: '5'),
      ]);

      await tester.pumpWidget(buildTabletSubject());
      await tester.pumpAndSettle();

      // Sanity: the long-caption tiles are actually present, so this test
      // exercises the overflow-prone cards rather than trivially passing.
      expect(find.text('The Beatdown'), findsOneWidget);
      expect(find.text('21s'), findsOneWidget);
      expect(find.text(longCommanderName), findsOneWidget);

      // The tablet path renders a Wrap of fixed-size cards, not the phone
      // GridView.
      expect(find.byType(Wrap), findsWidgets);
      expect(find.byType(GridView), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows an in-range empty body when the range hides all pods', (
    tester,
  ) async {
    // Pods dated Jan 2026 — outside a Last-30-Days window as of the run date.
    stubHistory([
      _pod('1', meAhead: true),
      _pod('2', meAhead: true),
      _pod('3', meAhead: true),
    ]);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Open the range dropdown and pick Last 30 Days.
    await tester.tap(find.byType(DropdownButton<StatsTimeRange>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 30 Days').last);
    await tester.pumpAndSettle();

    // In-range empty message shows, and the dropdown is still available to
    // widen the range back out.
    expect(find.textContaining('No shared pods in this range'), findsOneWidget);
    expect(find.byType(DropdownButton<StatsTimeRange>), findsOneWidget);
    // Not the all-time "never played" empty state.
    expect(find.textContaining('No shared pods yet'), findsNothing);
  });

  testWidgets('shows the empty state when no pods are shared', (tester) async {
    // A game with only me — the friend never shares a seat.
    stubHistory([
      GameModel(
        id: 'solo',
        winnerId: 'me-seat',
        startTime: DateTime(2026),
        endTime: DateTime(2026, 1, 1, 1),
        durationInSeconds: 3600,
        players: [_seat('me-seat', 'me', 0)],
      ),
    ]);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('No shared pods yet'), findsOneWidget);
  });
}
