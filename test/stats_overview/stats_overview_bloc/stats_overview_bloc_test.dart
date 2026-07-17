import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class _MockScryfallRepository extends Mock implements ScryfallRepository {}

/// Commander name whose oracle ID lookup the race tests hold open.
const _gatedCommander = 'Gated Commander';

Commander _commander(String name) => Commander(
  name: name,
  colors: const ['G'],
  cardType: 'Legendary Creature',
  imageUrl: '',
  manaCost: '{G}',
  oracleText: '',
  artist: 'Artist',
);

/// Mirrors the minimal single-player [GameModel] fixture used in
/// `test/home/match_history_bloc/match_history_bloc_test.dart`: a populated
/// `players` list is required by the bloc's stat calculators.
///
/// [commanderName] attaches a commander with no `oracleId`, which is what
/// makes the bloc await a Scryfall lookup — the suspension point the race
/// tests below need.
GameModel _game({
  required String id,
  required DateTime endTime,
  String? commanderName,
}) {
  final player = Player(
    id: 'p1',
    name: 'Player 1',
    playerNumber: 1,
    lifePoints: 40,
    color: 0xFF000000,
    opponents: const [],
    placement: 1,
    firebaseId: 'alice',
    commander: commanderName == null ? null : _commander(commanderName),
  );
  return GameModel(
    id: id,
    players: [player],
    startTime: endTime.subtract(const Duration(hours: 1)),
    endTime: endTime,
    winnerId: 'p1',
    durationInSeconds: 3600,
  );
}

/// Builds a single-player game where the user `alice` carries [opponents] —
/// the commander-damage clocks recorded against them. Used to exercise
/// `_calculateTimesKilledByCommander` through the compiled state.
GameModel _gameWithDamages({
  required String id,
  required List<Opponent> opponents,
}) {
  final player = Player(
    id: 'p1',
    name: 'Player 1',
    playerNumber: 1,
    lifePoints: 0,
    color: 0xFF000000,
    opponents: opponents,
    placement: 4,
    firebaseId: 'alice',
  );
  return GameModel(
    id: id,
    players: [player],
    startTime: DateTime(2020),
    endTime: DateTime(2020, 1, 1, 1),
    winnerId: 'p1',
    durationInSeconds: 3600,
  );
}

/// A single opponent dealing [damages] to the user.
Opponent _foeDealing(List<CommanderDamage> damages) =>
    Opponent(playerId: 'foe', damages: damages);

void main() {
  late ScryfallRepository scryfallRepository;

  final oldGame = _game(id: 'old', endTime: DateTime(2020));
  final newGame = _game(
    id: 'new',
    endTime: DateTime.now().subtract(const Duration(days: 1)),
  );

  // Race fixtures. `staleGame` is 200 days old: inside Last 12 Months but
  // outside Last 30 Days, so it is exactly the game that must appear under
  // one range and not the other. It is also the only carrier of the gated
  // commander, so only a compile whose range *includes* it can block.
  final staleGame = _game(
    id: 'stale',
    endTime: DateTime.now().subtract(const Duration(days: 200)),
    commanderName: _gatedCommander,
  );
  final recentGame = _game(
    id: 'recent',
    endTime: DateTime.now().subtract(const Duration(days: 5)),
    commanderName: 'Recent Commander',
  );

  setUp(() {
    scryfallRepository = _MockScryfallRepository();
  });

  StatsOverviewBloc buildBloc() =>
      StatsOverviewBloc(scryfallRepository: scryfallRepository);

  /// Stubs oracle ID resolution so that looking up [_gatedCommander] hangs
  /// until the returned completer is completed, while every other name
  /// resolves immediately.
  ///
  /// Returns a setter-style hook: the gate starts disarmed so setup compiles
  /// run unblocked, and arming it is what opens the race window.
  Completer<String?> Function() stubGatedOracleLookup() {
    Completer<String?>? gate;
    when(() => scryfallRepository.getOracleIdByName(any())).thenAnswer(
      (invocation) {
        final name = invocation.positionalArguments.first as String;
        final pending = gate;
        if (name == _gatedCommander && pending != null) return pending.future;
        return Future<String?>.value('oracle-$name');
      },
    );
    return () => gate = Completer<String?>();
  }

  group('StatsOverviewBloc', () {
    group('CompileStatsOverviewData', () {
      blocTest<StatsOverviewBloc, StatsOverviewState>(
        'defaults to allTime and keeps every game',
        build: buildBloc,
        act: (bloc) => bloc.add(
          CompileStatsOverviewData(
            userId: 'alice',
            games: [oldGame, newGame],
          ),
        ),
        expect: () => [
          isA<StatsOverviewLoading>(),
          isA<StatsOverviewLoaded>()
              .having((s) => s.range, 'range', StatsTimeRange.allTime)
              .having((s) => s.games.length, 'games.length', 2),
        ],
      );
    });

    group('timesKilledByCommander', () {
      blocTest<StatsOverviewBloc, StatsOverviewState>(
        'does not count a partner pair whose two clocks (13 + 12) each stay '
        'below 21, even though they sum past it',
        build: buildBloc,
        act: (bloc) => bloc.add(
          CompileStatsOverviewData(
            userId: 'alice',
            games: [
              _gameWithDamages(
                id: 'split',
                opponents: [
                  _foeDealing([
                    CommanderDamage(
                      damageType: DamageType.commander,
                      amount: 13,
                    ),
                    CommanderDamage(
                      damageType: DamageType.partner,
                      amount: 12,
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ),
        expect: () => [
          isA<StatsOverviewLoading>(),
          isA<StatsOverviewLoaded>().having(
            (s) => s.timesKilledByCommander,
            'timesKilledByCommander',
            0,
          ),
        ],
      );

      blocTest<StatsOverviewBloc, StatsOverviewState>(
        'counts a single clock that reaches 21',
        build: buildBloc,
        act: (bloc) => bloc.add(
          CompileStatsOverviewData(
            userId: 'alice',
            games: [
              _gameWithDamages(
                id: 'lethal',
                opponents: [
                  _foeDealing([
                    CommanderDamage(
                      damageType: DamageType.commander,
                      amount: 21,
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ),
        expect: () => [
          isA<StatsOverviewLoading>(),
          isA<StatsOverviewLoaded>().having(
            (s) => s.timesKilledByCommander,
            'timesKilledByCommander',
            1,
          ),
        ],
      );
    });

    group('StatsTimeRangeChanged', () {
      blocTest<StatsOverviewBloc, StatsOverviewState>(
        'StatsTimeRangeChanged re-filters the games already held, without '
        'the caller re-supplying them, and flashes loading on both paths',
        build: buildBloc,
        act: (bloc) async {
          bloc.add(
            CompileStatsOverviewData(
              userId: 'alice',
              games: [oldGame, newGame],
            ),
          );
          await Future<void>.delayed(Duration.zero);
          bloc.add(const StatsTimeRangeChanged(StatsTimeRange.last30Days));
        },
        expect: () => [
          isA<StatsOverviewLoading>(),
          isA<StatsOverviewLoaded>()
              .having((s) => s.range, 'range', StatsTimeRange.allTime)
              .having((s) => s.games.length, 'games.length', 2),
          isA<StatsOverviewLoading>(),
          isA<StatsOverviewLoaded>()
              .having((s) => s.range, 'range', StatsTimeRange.last30Days)
              .having((s) => s.games.length, 'games.length', 1),
        ],
      );
    });

    // Both handlers share `_emitCompiled`, which awaits oracle ID resolution
    // partway through. The bloc package processes events concurrently by
    // default, so invocations overlap. Every state the bloc emits must pair a
    // `range` with the `games` that range actually selects.
    group('overlapping compiles', () {
      test(
        'a slow earlier range change cannot pair its games with a newer '
        "range's label",
        () async {
          final armGate = stubGatedOracleLookup();
          final bloc = buildBloc();
          addTearDown(bloc.close);

          bloc.add(
            CompileStatsOverviewData(
              userId: 'alice',
              games: [recentGame, staleGame],
            ),
          );
          await bloc.stream.firstWhere((state) => state is StatsOverviewLoaded);

          // Armed only now, so the setup compile above ran unblocked.
          final gate = armGate();

          bloc
            ..add(const StatsTimeRangeChanged(StatsTimeRange.last12Months))
            ..add(const StatsTimeRangeChanged(StatsTimeRange.last30Days));

          // The last30Days compile covers only `recentGame`, so it never
          // touches the gate and runs to completion while the last12Months
          // compile is still suspended mid-resolution.
          await bloc.stream.firstWhere(
            (state) =>
                state is StatsOverviewLoaded &&
                state.range == StatsTimeRange.last30Days,
          );

          // Release the earlier, slower compile and give it every chance to
          // emit over the newer result.
          gate.complete('oracle-gated');
          await Future<void>.delayed(const Duration(milliseconds: 20));

          final state = bloc.state;
          expect(state, isA<StatsOverviewLoaded>());
          final loaded = state as StatsOverviewLoaded;
          expect(
            loaded.range,
            StatsTimeRange.last30Days,
            reason: 'the last range the user picked must win',
          );
          expect(
            loaded.games.map((game) => game.id).toList(),
            ['recent'],
            reason:
                'games must match the range the state reports; the '
                '200-day-old game is outside Last 30 Days',
          );
        },
      );

      test(
        'a slow live-sync compile cannot clobber a newer range change '
        '(cross-event-type race)',
        () async {
          // Guards against "fix" attempts that only serialise same-type
          // events: a per-registration transformer such as restartable()
          // cannot help here, because the two overlapping invocations arrive
          // through two independent `on<E>()` subscriptions.
          final armGate = stubGatedOracleLookup();
          final gate = armGate();
          final bloc = buildBloc();
          addTearDown(bloc.close);

          bloc
            // A live match-history update lands and starts compiling over
            // allTime, which includes the gated 200-day-old game.
            ..add(
              CompileStatsOverviewData(
                userId: 'alice',
                games: [recentGame, staleGame],
              ),
            )
            // The user changes the range while that sync is still in flight.
            ..add(const StatsTimeRangeChanged(StatsTimeRange.last30Days));

          await bloc.stream.firstWhere(
            (state) =>
                state is StatsOverviewLoaded &&
                state.range == StatsTimeRange.last30Days,
          );

          gate.complete('oracle-gated');
          await Future<void>.delayed(const Duration(milliseconds: 20));

          final state = bloc.state;
          expect(state, isA<StatsOverviewLoaded>());
          final loaded = state as StatsOverviewLoaded;
          expect(loaded.range, StatsTimeRange.last30Days);
          expect(
            loaded.games.map((game) => game.id).toList(),
            ['recent'],
            reason:
                'the in-flight allTime compile must not emit its game set '
                'under the newer Last 30 Days label',
          );
        },
      );
    });
  });
}
