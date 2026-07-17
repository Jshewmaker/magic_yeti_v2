import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';
import 'package:player_repository/player_repository.dart';

/// Computes [FriendHeadToHead] from the signed-in user's own match history.
///
/// This reads only the user's own games (which already contain every
/// participant's seat via the game fan-out), so no cross-account reads are
/// needed. It is a pure function of its inputs — no I/O — so the correctness
/// rules below can be exercised directly in unit tests.
///
/// Correctness rules (each verified against the game/player models):
/// - A pod counts only when one seat's `firebaseId` is `myId` and a *different*
///   seat's is `friendId`. There is no "nearest seat" fallback — an untagged
///   seat is never attributed to either player.
/// - Finish order comes from `timeOfDeath` (strictly ordered epoch millis; the
///   winner is stamped at game end), never `placement`, which can collide when
///   a player is revived.
/// - Wins come from [GameModel.winnerId].
/// - `timeOfDeath` is a throwing getter; it is read through [_timeOfDeath],
///   and a pod whose two seats don't both yield one is dropped.
/// - A 21-damage kill is a single clock reaching 21 (`any`), while damage
///   *volume* sums both clocks (`fold`) — different questions.
/// - Survival fraction normalises against the wall-clock window
///   (`endTime - startTime`), not the pausable `durationInSeconds`.
class FriendHeadToHeadCalculator {
  const FriendHeadToHeadCalculator._();

  static FriendHeadToHead compute({
    required List<GameModel> games,
    required String myId,
    required String friendId,
  }) {
    if (myId.isEmpty || friendId.isEmpty || myId == friendId) {
      return FriendHeadToHead.empty;
    }

    var sharedPods = 0;
    DateTime? firstPlayed;
    var youAhead = 0;
    var theyAhead = 0;
    var youWon = 0;
    var theyWon = 0;
    var fieldWon = 0;
    var expectedWins = 0.0;
    var finalTwo = 0;
    var dmgDealt = 0;
    var dmgTaken = 0;
    var lethalLanded = 0;
    var lethalTaken = 0;
    final survivalYou = <double>[];
    final survivalThem = <double>[];
    final commanderCounts = <String, int>{};
    final commanderReps = <String, Commander>{};

    for (final game in games) {
      final me = _seatFor(game, myId);
      final friend = _seatFor(game, friendId);
      if (me == null || friend == null || me.id == friend.id) continue;

      final myTod = _timeOfDeath(me);
      final friendTod = _timeOfDeath(friend);
      if (myTod == null || friendTod == null) continue;

      sharedPods++;
      if (firstPlayed == null || game.startTime.isBefore(firstPlayed)) {
        firstPlayed = game.startTime;
      }

      // The Ledger.
      if (myTod > friendTod) {
        youAhead++;
      } else if (friendTod > myTod) {
        theyAhead++;
      }

      // Pods Won.
      if (game.winnerId == me.id) {
        youWon++;
      } else if (game.winnerId == friend.id) {
        theyWon++;
      } else {
        fieldWon++;
      }
      final podSize = game.players.length;
      if (podSize > 0) expectedWins += 1 / podSize;

      // Time Alive.
      final myFraction = _survivalFraction(game, myTod);
      final friendFraction = _survivalFraction(game, friendTod);
      if (myFraction != null) survivalYou.add(myFraction);
      if (friendFraction != null) survivalThem.add(friendFraction);

      // Final Two.
      if (_areFinalTwo(game, me.id, friend.id)) finalTwo++;

      // The Beatdown (volume, both clocks) — friend took from me, I took from
      // friend.
      dmgDealt += _damageVolume(victim: friend, dealerId: me.id);
      dmgTaken += _damageVolume(victim: me, dealerId: friend.id);

      // 21s (single clock lethality).
      if (_landedLethalClock(victim: friend, dealerId: me.id)) lethalLanded++;
      if (_landedLethalClock(victim: me, dealerId: friend.id)) lethalTaken++;

      // Their Go-To.
      final commander = friend.commander;
      if (commander != null) {
        final key = commander.oracleId ?? commander.name;
        commanderCounts[key] = (commanderCounts[key] ?? 0) + 1;
        commanderReps[key] = commander;
      }
    }

    if (sharedPods == 0) return FriendHeadToHead.empty;

    final topCommander = _topCommander(commanderCounts, commanderReps);

    return FriendHeadToHead(
      sharedPods: sharedPods,
      firstPlayedTogether: firstPlayed,
      youFinishedAhead: youAhead,
      theyFinishedAhead: theyAhead,
      youWon: youWon,
      theyWon: theyWon,
      fieldWon: fieldWon,
      expectedWinsEach: expectedWins,
      yourAvgSurvival: _average(survivalYou),
      theirAvgSurvival: _average(survivalThem),
      finalTwoCount: finalTwo,
      commanderDamageDealt: dmgDealt,
      commanderDamageTaken: dmgTaken,
      lethalBlowsLanded: lethalLanded,
      lethalBlowsTaken: lethalTaken,
      theirTopCommanderName: topCommander?.name,
      theirTopCommanderImageUrl: topCommander?.imageUrl,
      theirTopCommanderCount: topCommander == null
          ? 0
          : commanderCounts[topCommander.key]!,
    );
  }

  /// First seat whose account link is [firebaseId], or null.
  static Player? _seatFor(GameModel game, String firebaseId) {
    for (final p in game.players) {
      if (p.firebaseId == firebaseId) return p;
    }
    return null;
  }

  /// Reads a seat's time of death without throwing. Returns null for an active
  /// or malformed seat.
  static int? _timeOfDeath(Player p) {
    if (!p.isEliminated) return null;
    try {
      return p.timeOfDeath;
    } on Object catch (_) {
      // A malformed legacy seat (eliminated but no recorded death) throws.
      return null;
    }
  }

  static double? _survivalFraction(GameModel game, int timeOfDeath) {
    final start = game.startTime.millisecondsSinceEpoch;
    final end = game.endTime.millisecondsSinceEpoch;
    final span = end - start;
    if (span <= 0) return null;
    return ((timeOfDeath - start) / span).clamp(0.0, 1.0);
  }

  /// Whether [aId] and [bId] hold the two latest deaths in the pod.
  static bool _areFinalTwo(GameModel game, String aId, String bId) {
    final ordered = <MapEntry<String, int>>[];
    for (final p in game.players) {
      final tod = _timeOfDeath(p);
      if (tod != null) ordered.add(MapEntry(p.id, tod));
    }
    if (ordered.length < 2) return false;
    ordered.sort((x, y) => y.value.compareTo(x.value));
    final topTwo = {ordered[0].key, ordered[1].key};
    return topTwo.contains(aId) && topTwo.contains(bId);
  }

  static int _damageVolume({required Player victim, required String dealerId}) {
    final entry = _opponentEntry(victim, dealerId);
    if (entry == null) return 0;
    return entry.damages.fold<int>(0, (sum, d) => sum + d.amount);
  }

  static bool _landedLethalClock({
    required Player victim,
    required String dealerId,
  }) {
    final entry = _opponentEntry(victim, dealerId);
    if (entry == null) return false;
    return entry.damages.any((d) => d.amount >= 21);
  }

  static Opponent? _opponentEntry(Player victim, String dealerId) {
    final opponents = victim.opponents;
    if (opponents == null) return null;
    for (final o in opponents) {
      if (o.playerId == dealerId) return o;
    }
    return null;
  }

  static double? _average(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static _TopCommander? _topCommander(
    Map<String, int> counts,
    Map<String, Commander> reps,
  ) {
    if (counts.isEmpty) return null;
    String? bestKey;
    var bestCount = -1;
    for (final entry in counts.entries) {
      final count = entry.value;
      // Deterministic tie-break: higher count wins, then commander name.
      if (count > bestCount ||
          (count == bestCount &&
              reps[entry.key]!.name.compareTo(reps[bestKey]!.name) < 0)) {
        bestKey = entry.key;
        bestCount = count;
      }
    }
    final rep = reps[bestKey]!;
    return _TopCommander(bestKey!, rep.name, rep.imageUrl);
  }
}

class _TopCommander {
  const _TopCommander(this.key, this.name, this.imageUrl);
  final String key;
  final String name;
  final String imageUrl;
}
