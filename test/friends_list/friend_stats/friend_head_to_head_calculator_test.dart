import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head_calculator.dart';
import 'package:player_repository/player_repository.dart';

const _me = 'me-uid';
const _friend = 'friend-uid';

/// Fixed game window: noon to 2pm, a 2-hour wall-clock span.
final _start = DateTime(2026, 1, 1, 12);
final _end = DateTime(2026, 1, 1, 14);

/// A [timeOfDeath] at [fraction] through the [_start]..[_end] window.
int _tod(double fraction) =>
    _start.millisecondsSinceEpoch +
    (fraction * (_end.millisecondsSinceEpoch - _start.millisecondsSinceEpoch))
        .round();

Commander _commander(String name, {String? oracleId}) => Commander(
  name: name,
  oracleId: oracleId,
  colors: const ['G'],
  cardType: 'Legendary Creature',
  imageUrl: 'img-$name',
  manaCost: '{G}',
  oracleText: '',
  artist: 'Artist',
);

Opponent _dmg(String dealerId, {int commander = 0, int partner = 0}) =>
    Opponent(
      playerId: dealerId,
      damages: [
        CommanderDamage(damageType: DamageType.commander, amount: commander),
        CommanderDamage(damageType: DamageType.partner, amount: partner),
      ],
    );

Player _player({
  required String id,
  String? firebaseId,
  int? timeOfDeath,
  int placement = 2,
  String? commanderName,
  String? commanderOracleId,
  List<Opponent> opponents = const [],
  PlayerModelState state = PlayerModelState.eliminated,
}) => Player(
  id: id,
  name: 'Name-$id',
  playerNumber: 0,
  lifePoints: 40,
  color: 0xFF000000,
  opponents: opponents,
  state: state,
  placement: placement,
  timeOfDeath: timeOfDeath,
  firebaseId: firebaseId,
  commander: commanderName == null
      ? null
      : _commander(commanderName, oracleId: commanderOracleId),
);

GameModel _game({
  required String id,
  required List<Player> players,
  required String winnerId,
  DateTime? start,
  DateTime? end,
}) => GameModel(
  id: id,
  players: players,
  startTime: start ?? _start,
  endTime: end ?? _end,
  winnerId: winnerId,
  durationInSeconds: 7200,
);

/// A standard 4-player pod where [meTod]/[friendTod] set the two finishing
/// times of interest. Two filler seats die early.
GameModel _pod({
  required String id,
  required double meTod,
  required double friendTod,
  String winnerId = 'seat-me',
  List<Opponent> meOpponents = const [],
  List<Opponent> friendOpponents = const [],
  String friendCommander = 'Atraxa',
}) => _game(
  id: id,
  winnerId: winnerId,
  players: [
    _player(
      id: 'seat-me',
      firebaseId: _me,
      timeOfDeath: _tod(meTod),
      opponents: meOpponents,
      commanderName: 'Krenko',
    ),
    _player(
      id: 'seat-friend',
      firebaseId: _friend,
      timeOfDeath: _tod(friendTod),
      opponents: friendOpponents,
      commanderName: friendCommander,
    ),
    _player(id: 'seat-c', timeOfDeath: _tod(0.1)),
    _player(id: 'seat-d', timeOfDeath: _tod(0.2)),
  ],
);

void main() {
  group('FriendHeadToHeadCalculator.compute', () {
    test('counts only pods where both accounts occupy distinct seats', () {
      final games = [
        _pod(id: 'shared', meTod: 1, friendTod: 0.5),
        // Only me — friend absent.
        _game(
          id: 'solo',
          winnerId: 'seat-me',
          players: [
            _player(id: 'seat-me', firebaseId: _me, timeOfDeath: _tod(1)),
            _player(id: 'x', timeOfDeath: _tod(0.3)),
          ],
        ),
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.sharedPods, 1);
    });

    test('does not treat one seat as both players when ids collide', () {
      final games = [_pod(id: 'a', meTod: 1, friendTod: 0.5)];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _me, // same id -> not a real pairing
      );

      expect(result.sharedPods, 0);
    });

    test('drops a shared pod when a seat has no parseable time of death', () {
      // Friend seat is active with no timeOfDeath -> the getter throws; the
      // pod must be dropped, not crash the whole computation.
      final broken = _game(
        id: 'broken',
        winnerId: 'seat-me',
        players: [
          _player(id: 'seat-me', firebaseId: _me, timeOfDeath: _tod(1)),
          _player(
            id: 'seat-friend',
            firebaseId: _friend,
            state: PlayerModelState.active,
          ),
          _player(id: 'z', timeOfDeath: _tod(0.2)),
        ],
      );

      final result = FriendHeadToHeadCalculator.compute(
        games: [
          broken,
          _pod(id: 'ok', meTod: 1, friendTod: 0.5),
        ],
        myId: _me,
        friendId: _friend,
      );

      expect(result.sharedPods, 1);
    });

    test('The Ledger counts who finished ahead by time of death', () {
      final games = [
        _pod(id: '1', meTod: 1.0, friendTod: 0.4), // me ahead
        _pod(id: '2', meTod: 0.9, friendTod: 0.3), // me ahead
        _pod(id: '3', meTod: 0.2, friendTod: 0.8), // friend ahead
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.youFinishedAhead, 2);
      expect(result.theyFinishedAhead, 1);
    });

    test('Pods Won splits wins between you, them, and the field', () {
      final games = [
        _pod(id: '1', meTod: 1, friendTod: 0.5, winnerId: 'seat-me'),
        _pod(id: '2', meTod: 0.5, friendTod: 1, winnerId: 'seat-friend'),
        _pod(id: '3', meTod: 0.5, friendTod: 0.4, winnerId: 'seat-c'),
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.youWon, 1);
      expect(result.theyWon, 1);
      expect(result.fieldWon, 1);
      // Expected wins = sum of 1/podSize; all 4-player pods -> 3 * 0.25.
      expect(result.expectedWinsEach, closeTo(0.75, 1e-9));
    });

    test('Time Alive averages survival fraction of the wall-clock window', () {
      final games = [
        _pod(id: '1', meTod: 1.0, friendTod: 0.5),
        _pod(id: '2', meTod: 0.5, friendTod: 0.5),
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.yourAvgSurvival, closeTo(0.75, 1e-9));
      expect(result.theirAvgSurvival, closeTo(0.5, 1e-9));
    });

    test('Final Two counts pods where the pair are the last two standing', () {
      final games = [
        // me + friend are the two latest deaths -> final two.
        _pod(id: '1', meTod: 1.0, friendTod: 0.9),
        // filler seat-d at 0.2 beats friend at 0.15 -> NOT final two.
        _pod(id: '2', meTod: 1.0, friendTod: 0.15),
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.finalTwoCount, 1);
    });

    test('Beatdown sums commander damage volume both directions', () {
      final games = [
        _pod(
          id: '1',
          meTod: 1,
          friendTod: 0.5,
          // Damage the friend seat took from me (dealer id = seat-me).
          friendOpponents: [_dmg('seat-me', commander: 10, partner: 3)],
          // Damage I took from the friend (dealer id = seat-friend).
          meOpponents: [_dmg('seat-friend', commander: 4)],
        ),
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.commanderDamageDealt, 13); // 10 + 3
      expect(result.commanderDamageTaken, 4);
    });

    test('21s use a single clock, not the summed partner clocks', () {
      final games = [
        // 13 + 12 across two clocks = 25 summed, but neither clock hits 21.
        _pod(
          id: 'nonlethal',
          meTod: 1,
          friendTod: 0.5,
          friendOpponents: [_dmg('seat-me', commander: 13, partner: 12)],
        ),
        // A single clock reaches 21 -> one lethal blow landed.
        _pod(
          id: 'lethal',
          meTod: 1,
          friendTod: 0.5,
          friendOpponents: [_dmg('seat-me', commander: 21)],
        ),
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.lethalBlowsLanded, 1);
      expect(result.lethalBlowsTaken, 0);
    });

    test('Their Go-To is their most-played commander, keyed by oracle id', () {
      final games = [
        _pod(id: '1', meTod: 1, friendTod: 0.5, friendCommander: 'Atraxa'),
        _pod(id: '2', meTod: 1, friendTod: 0.5, friendCommander: 'Atraxa'),
        _pod(id: '3', meTod: 1, friendTod: 0.5, friendCommander: 'Yuriko'),
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.theirTopCommanderName, 'Atraxa');
      expect(result.theirTopCommanderCount, 2);
    });

    test('records the earliest shared game date', () {
      final games = [
        _game(
          id: 'later',
          winnerId: 'seat-me',
          start: DateTime(2026, 3, 1, 12),
          end: DateTime(2026, 3, 1, 13),
          players: [
            _player(
              id: 'seat-me',
              firebaseId: _me,
              timeOfDeath: DateTime(2026, 3, 1, 13).millisecondsSinceEpoch,
            ),
            _player(
              id: 'seat-friend',
              firebaseId: _friend,
              timeOfDeath: DateTime(2026, 3, 1, 12, 30).millisecondsSinceEpoch,
            ),
          ],
        ),
        _game(
          id: 'earlier',
          winnerId: 'seat-me',
          start: DateTime(2026, 1, 15, 12),
          end: DateTime(2026, 1, 15, 13),
          players: [
            _player(
              id: 'seat-me',
              firebaseId: _me,
              timeOfDeath: DateTime(2026, 1, 15, 13).millisecondsSinceEpoch,
            ),
            _player(
              id: 'seat-friend',
              firebaseId: _friend,
              timeOfDeath: DateTime(2026, 1, 15, 12, 30).millisecondsSinceEpoch,
            ),
          ],
        ),
      ];

      final result = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _me,
        friendId: _friend,
      );

      expect(result.firstPlayedTogether, DateTime(2026, 1, 15, 12));
    });

    test('empty history yields the empty result', () {
      final result = FriendHeadToHeadCalculator.compute(
        games: const [],
        myId: _me,
        friendId: _friend,
      );

      expect(result, FriendHeadToHead.empty);
      expect(result.yourAvgSurvival, isNull);
      expect(result.theirAvgSurvival, isNull);
    });

    test('gating getters reflect sample thresholds', () {
      final threePods = List.generate(
        3,
        (i) => _pod(id: '$i', meTod: 1, friendTod: 0.5),
      );

      final result = FriendHeadToHeadCalculator.compute(
        games: threePods,
        myId: _me,
        friendId: _friend,
      );

      expect(result.hasEnoughForLedger, isTrue); // >= 3
      expect(result.hasEnoughForSurvival, isFalse); // needs >= 5
    });
  });
}
