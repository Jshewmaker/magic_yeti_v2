import 'package:flutter_test/flutter_test.dart';
import 'package:player_repository/player_repository.dart';

void main() {
  Commander commander(String name) => Commander(
        name: name,
        colors: const ['B'],
        cardType: 'Legendary Enchantment — Background',
        imageUrl: 'https://example.com/$name.jpg',
        manaCost: '',
        oracleText: '',
        artist: 'Artist',
      );

  Player base() => Player(
        id: 'p1',
        name: 'Sarah',
        playerNumber: 0,
        lifePoints: 40,
        color: 0xFF378ADD,
        opponents: const [],
        placement: 1,
        timeOfDeath: 1000,
      );

  group('Player.background', () {
    test('defaults to null and round-trips through JSON', () {
      final withBg = base().copyWith(background: () => commander('Cult of Rakdos'));
      final restored = Player.fromJson(withBg.toJson());
      expect(restored.background?.name, 'Cult of Rakdos');
    });

    test('deserializes to null when background absent (backward compat)', () {
      final json = base().toJson()..remove('background');
      final restored = Player.fromJson(json);
      expect(restored.background, isNull);
    });

    test('copyWith can clear background explicitly', () {
      final withBg = base().copyWith(background: () => commander('Bg'));
      final cleared = withBg.copyWith(background: () => null);
      expect(cleared.background, isNull);
    });

    test('copyWith without background argument preserves it', () {
      final withBg = base().copyWith(background: () => commander('Bg'));
      final renamed = withBg.copyWith(name: 'Sara');
      expect(renamed.background?.name, 'Bg');
    });
  });
}
