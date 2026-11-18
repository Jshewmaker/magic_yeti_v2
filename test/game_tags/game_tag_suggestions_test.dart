import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game_tags/game_tags.dart';
import 'package:player_repository/player_repository.dart';

/// Commander damage that [sourceId]'s commander (and partner) dealt.
Opponent _from(String sourceId, {int commander = 0, int partner = 0}) =>
    Opponent(
      playerId: sourceId,
      damages: [
        CommanderDamage(damageType: DamageType.commander, amount: commander),
        CommanderDamage(damageType: DamageType.partner, amount: partner),
      ],
    );

Player _player(
  String id, {
  required int placement,
  List<Opponent> opponents = const [],
  List<String> tags = const [],
}) => Player(
  id: id,
  name: id,
  playerNumber: placement,
  lifePoints: 0,
  color: 0,
  opponents: opponents,
  placement: placement,
  tags: tags,
);

List<String> _tagsOf(List<Player> players, String id) =>
    players.firstWhere((p) => p.id == id).tags;

void main() {
  group('withSuggestedPlayerTags', () {
    test('tags the victim and the killer of lethal commander damage', () {
      final result = withSuggestedPlayerTags([
        _player('a', placement: 1),
        _player('b', placement: 2, opponents: [_from('a', commander: 21)]),
        _player('c', placement: 3),
      ]);

      expect(_tagsOf(result, 'a'), ['commander_kill']);
      expect(_tagsOf(result, 'b'), ['ko_commander_damage']);
      expect(_tagsOf(result, 'c'), ['first_out']);
    });

    test('a partner clock is lethal on its own', () {
      final result = withSuggestedPlayerTags([
        _player('a', placement: 1),
        _player('b', placement: 2, opponents: [_from('a', partner: 22)]),
      ]);

      expect(_tagsOf(result, 'a'), ['commander_kill']);
      expect(_tagsOf(result, 'b'), ['ko_commander_damage', 'first_out']);
    });

    test('the commander and partner clocks are never summed', () {
      final result = withSuggestedPlayerTags([
        _player('a', placement: 1),
        _player(
          'b',
          placement: 2,
          opponents: [_from('a', commander: 13, partner: 12)],
        ),
      ]);

      expect(_tagsOf(result, 'a'), isEmpty);
      expect(_tagsOf(result, 'b'), ['first_out']);
    });

    test("ignores the player's own entry", () {
      final result = withSuggestedPlayerTags([
        _player('a', placement: 1, opponents: [_from('a', commander: 30)]),
        _player('b', placement: 2),
      ]);

      expect(_tagsOf(result, 'a'), isEmpty);
    });

    test('keeps existing tags and never adds one twice', () {
      final result = withSuggestedPlayerTags([
        _player('a', placement: 1, tags: const ['t1_sol_ring']),
        _player('b', placement: 2, tags: const ['first_out']),
      ]);

      expect(_tagsOf(result, 'a'), ['t1_sol_ring']);
      expect(_tagsOf(result, 'b'), ['first_out']);
    });

    test('a one-player game has no first out', () {
      final result = withSuggestedPlayerTags([_player('a', placement: 1)]);
      expect(_tagsOf(result, 'a'), isEmpty);
    });

    test('a player with no damage data gets no damage tags', () {
      const player = Player(
        id: 'a',
        name: 'a',
        playerNumber: 1,
        lifePoints: 0,
        color: 0,
        opponents: null,
        placement: 1,
      );
      expect(withSuggestedPlayerTags([player]).single.tags, isEmpty);
    });
  });

  group('suggestedGameTags', () {
    test(
      'suggests commander damage when the winner finished the runner-up',
      () {
        expect(
          suggestedGameTags([
            _player('a', placement: 1),
            _player('b', placement: 2, opponents: [_from('a', commander: 21)]),
          ]),
          ['end_commander_damage'],
        );
      },
    );

    test('suggests nothing when another player dealt the damage', () {
      expect(
        suggestedGameTags([
          _player('a', placement: 1),
          _player('b', placement: 2, opponents: [_from('c', commander: 21)]),
          _player('c', placement: 3),
        ]),
        isEmpty,
      );
    });

    test('suggests nothing without a runner-up', () {
      expect(suggestedGameTags([_player('a', placement: 1)]), isEmpty);
      expect(suggestedGameTags(const []), isEmpty);
    });
  });

  group('followFirstOut', () {
    final a = _player('a', placement: 1);
    final b = _player('b', placement: 2);
    final c = _player(
      'c',
      placement: 3,
      tags: const ['first_out', 'great_opener'],
    );

    test('moves the tag to the new last player', () {
      final result = followFirstOut([a, b, c], [a, c, b]);

      expect(_tagsOf(result, 'c'), ['great_opener']);
      expect(_tagsOf(result, 'b'), ['first_out']);
      expect(result.map((p) => p.id), ['a', 'c', 'b']);
    });

    test('does nothing when the last player is unchanged', () {
      final next = [b, a, c];
      expect(followFirstOut([a, b, c], next), same(next));
    });

    test('does nothing when the user cleared the tag', () {
      final cleared = c.copyWith(tags: const ['great_opener']);
      final next = [a, cleared, b];
      expect(followFirstOut([a, b, cleared], next), same(next));
    });

    test('handles empty lists', () {
      expect(followFirstOut(const [], [a]), [a]);
      expect(followFirstOut([a], const []), isEmpty);
    });
  });
}
