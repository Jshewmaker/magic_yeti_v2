import 'package:magic_yeti/game_tags/game_tag.dart';
import 'package:player_repository/player_repository.dart';

/// Commander damage from one source that eliminates a player. Mirrors
/// `PlayerRepository._checkPlayerDeath`: each clock (commander or partner)
/// counts on its own, never summed.
const _lethalCommanderDamage = 21;

/// Returns [standings] with the player tags that the recorded game data
/// proves already selected, so the user only has to clear a wrong one.
///
/// [standings] must be in placement order, winner first. A tag a player
/// already holds is kept and never added twice.
List<Player> withSuggestedPlayerTags(List<Player> standings) {
  final knockedOut = <String>{};
  final killers = <String>{};
  for (final player in standings) {
    for (final source in player.opponents ?? const <Opponent>[]) {
      // Each player also holds an entry for their own id.
      if (source.playerId == player.id) continue;
      if (_isLethal(source)) {
        knockedOut.add(player.id);
        killers.add(source.playerId);
      }
    }
  }
  final firstOutId = standings.length > 1 ? standings.last.id : null;

  return [
    for (final player in standings)
      _withTags(player, [
        if (knockedOut.contains(player.id)) GameTag.koCommanderDamage,
        if (killers.contains(player.id)) GameTag.commanderKill,
        if (player.id == firstOutId) GameTag.firstOut,
      ]),
  ];
}

/// The game tags that the recorded data proves, for [standings] in
/// placement order.
///
/// Suggests [GameTag.endCommanderDamage] when the winner's commander damage
/// eliminated the runner-up, the last player standing against them.
List<String> suggestedGameTags(List<Player> standings) {
  if (standings.length < 2) return const [];
  final winner = standings.first;
  final runnerUp = standings[1];
  final finishedByCommander = (runnerUp.opponents ?? const <Opponent>[]).any(
    (source) => source.playerId == winner.id && _isLethal(source),
  );
  return [if (finishedByCommander) GameTag.endCommanderDamage.id];
}

/// Moves [GameTag.firstOut] to the new last player after the standings are
/// reordered from [previous] to [next].
///
/// Does nothing when the last player is unchanged, or when the user already
/// cleared the tag from the old last player.
List<Player> followFirstOut(List<Player> previous, List<Player> next) {
  if (previous.isEmpty || next.isEmpty) return next;
  final oldLast = previous.last;
  final newLast = next.last;
  if (oldLast.id == newLast.id) return next;
  if (!oldLast.tags.contains(GameTag.firstOut.id)) return next;

  return [
    for (final player in next)
      if (player.id == oldLast.id)
        player.copyWith(
          tags: player.tags.where((id) => id != GameTag.firstOut.id).toList(),
        )
      else if (player.id == newLast.id)
        _withTags(player, const [GameTag.firstOut])
      else
        player,
  ];
}

bool _isLethal(Opponent source) =>
    source.damages.any((damage) => damage.amount >= _lethalCommanderDamage);

Player _withTags(Player player, List<GameTag> tags) {
  final missing = tags.where((tag) => !player.tags.contains(tag.id));
  if (missing.isEmpty) return player;
  return player.copyWith(tags: [...player.tags, ...missing.map((t) => t.id)]);
}
