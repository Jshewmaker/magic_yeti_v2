import 'package:flutter_test/flutter_test.dart';
import 'package:player_repository/player_repository.dart';

void main() {
  Commander commander({
    List<String> keywords = const [],
    String oracleText = '',
    String cardType = 'Legendary Creature',
  }) =>
      Commander(
        name: 'Test',
        colors: const ['U'],
        cardType: cardType,
        imageUrl: 'https://example.com/x.jpg',
        manaCost: '{U}',
        oracleText: oracleText,
        artist: 'Artist',
        keywords: keywords,
      );

  group('commanderPairingFor', () {
    test('plain commander => none', () {
      expect(commanderPairingFor(commander()), CommanderPairing.none);
    });

    test('Partner keyword => partner', () {
      expect(
        commanderPairingFor(commander(keywords: ['Partner'])),
        CommanderPairing.partner,
      );
    });

    test('Partner with X (keyword) => partner', () {
      expect(
        commanderPairingFor(commander(keywords: ['Partner with'])),
        CommanderPairing.partner,
      );
    });

    test('Friends forever => partner', () {
      expect(
        commanderPairingFor(commander(keywords: ['Friends forever'])),
        CommanderPairing.partner,
      );
    });

    test("Doctor's companion => partner", () {
      expect(
        commanderPairingFor(commander(keywords: ["Doctor's companion"])),
        CommanderPairing.partner,
      );
    });

    test('Choose a Background (oracle text) => background', () {
      expect(
        commanderPairingFor(
          commander(oracleText: 'Choose a Background (You can have a '
              'Background as a second commander.)'),
        ),
        CommanderPairing.background,
      );
    });

    test('detection is case-insensitive', () {
      expect(
        commanderPairingFor(commander(keywords: ['PARTNER'])),
        CommanderPairing.partner,
      );
    });

    test('background takes priority over a partner keyword', () {
      expect(
        commanderPairingFor(
          commander(keywords: ['Partner'], oracleText: 'Choose a Background'),
        ),
        CommanderPairing.background,
      );
    });

    test('Choose a Background (keyword) => background', () {
      expect(
        commanderPairingFor(commander(keywords: ['Choose a Background'])),
        CommanderPairing.background,
      );
    });
  });
}
