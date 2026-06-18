import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/utils/commander_mapper.dart';

import '../../helpers/card_fixtures.dart';

void main() {
  group('magicCardToCommander', () {
    test('maps MagicCard fields onto a Commander', () {
      final card = buildMagicCard(
        oracleId: 'oracle-1',
        name: 'Atraxa',
        typeLine: 'Legendary Creature',
        scryfallUri: 'https://scryfall.test/atraxa',
        manaCost: '{G}{W}{U}{B}',
        power: '4',
        toughness: '4',
      );

      final commander = magicCardToCommander(card);

      expect(commander.oracleId, 'oracle-1');
      expect(commander.name, 'Atraxa');
      expect(commander.scryFallUrl, 'https://scryfall.test/atraxa');
      expect(commander.imageUrl, 'https://img.test/art_crop.jpg');
      expect(commander.colors, ['W', 'U', 'B', 'G']);
      expect(commander.cardType, 'Legendary Creature');
      expect(commander.manaCost, '{G}{W}{U}{B}');
      expect(commander.power, '4');
      expect(commander.toughness, '4');
    });

    test('falls back to empty image url when imageUris is null', () {
      final card = buildMagicCard(imageUris: null);
      expect(magicCardToCommander(card).imageUrl, '');
    });

    test('falls back to empty colors when colors is null', () {
      final card = buildMagicCard(colors: null);
      expect(magicCardToCommander(card).colors, isEmpty);
    });
  });
}
