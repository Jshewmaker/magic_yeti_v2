import 'package:flutter_test/flutter_test.dart';
import 'package:player_repository/player_repository.dart';

void main() {
  group('Commander keywords', () {
    Commander base() => const Commander(
          name: "Atraxa, Praetors' Voice",
          colors: ['W', 'U', 'B', 'G'],
          cardType: 'Legendary Creature',
          imageUrl: 'https://example.com/atraxa.jpg',
          manaCost: '{G}{W}{U}{B}',
          oracleText: 'Flying, vigilance, deathtouch, lifelink',
          artist: 'Victor Adame Minguez',
          keywords: ['Flying', 'Vigilance'],
        );

    test('round-trips keywords through JSON', () {
      final json = base().toJson();
      final restored = Commander.fromJson(json);
      expect(restored.keywords, ['Flying', 'Vigilance']);
    });

    test('defaults to empty list when keywords absent from JSON', () {
      final json = base().toJson()..remove('keywords');
      final restored = Commander.fromJson(json);
      expect(restored.keywords, isEmpty);
    });

    test('copyWith replaces keywords', () {
      final updated = base().copyWith(keywords: ['Partner']);
      expect(updated.keywords, ['Partner']);
    });
  });
}
