import 'package:flutter_test/flutter_test.dart';
import 'package:player_repository/player_repository.dart';

void main() {
  const base = Player(
    id: 'p1',
    name: 'Sarah',
    playerNumber: 0,
    lifePoints: 40,
    color: 0xFF378ADD,
    opponents: [],
    placement: 1,
    timeOfDeath: 1000,
  );

  group('Player.tags', () {
    test('defaults to empty', () {
      expect(base.tags, isEmpty);
    });

    test('round-trips through JSON', () {
      final tagged = base.copyWith(tags: const ['t1_sol_ring', 'first_out']);

      final decoded = Player.fromJson(tagged.toJson());

      expect(decoded.tags, ['t1_sol_ring', 'first_out']);
      expect(decoded, tagged);
    });

    test('a saved player without tags decodes to an empty list', () {
      final json = base.toJson()..remove('tags');

      expect(Player.fromJson(json).tags, isEmpty);
    });

    test('copyWith keeps the tags when not given', () {
      final tagged = base.copyWith(tags: const ['great_opener']);

      expect(tagged.copyWith(name: 'Sam').tags, ['great_opener']);
    });

    test('tags take part in equality', () {
      expect(base.copyWith(tags: const ['a']), isNot(base));
    });
  });
}
