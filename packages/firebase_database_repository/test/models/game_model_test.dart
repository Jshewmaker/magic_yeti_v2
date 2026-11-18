import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:test/test.dart';

void main() {
  final base = GameModel(
    id: 'g1',
    players: const [
      Player(
        id: 'p1',
        name: 'Sarah',
        playerNumber: 0,
        lifePoints: 40,
        color: 0,
        opponents: [],
        placement: 1,
        timeOfDeath: 1000,
        tags: ['t1_sol_ring'],
      ),
    ],
    startTime: DateTime.utc(2026),
    endTime: DateTime.utc(2026, 1, 1, 1),
    winnerId: 'p1',
    durationInSeconds: 3600,
  );

  group('GameModel.tags', () {
    test('defaults to empty', () {
      expect(base.tags, isEmpty);
    });

    test('round-trips through JSON with the player tags', () {
      final tagged = base.copyWith(tags: const ['bracket_3', 'end_combo']);

      final decoded = GameModel.fromJson(tagged.toJson());

      expect(decoded.tags, ['bracket_3', 'end_combo']);
      expect(decoded.players.single.tags, ['t1_sol_ring']);
      expect(decoded, tagged);
    });

    test('a saved game without tags decodes to an empty list', () {
      final json = base.toJson()..remove('tags');

      expect(GameModel.fromJson(json).tags, isEmpty);
    });

    test('copyWith keeps the tags when not given', () {
      final tagged = base.copyWith(tags: const ['bracket_1']);

      expect(tagged.copyWith(winnerId: 'p1').tags, ['bracket_1']);
    });
  });
}
