import 'package:player_repository/models/commander.dart';

/// How a commander may take a second card.
enum CommanderPairing {
  /// No second card.
  none,

  /// A second *attacking* commander (Partner / Partner with / Friends
  /// forever / Doctor's companion). Adds its own commander-damage clock.
  partner,

  /// A Background enchantment. Affects color identity only — no clock.
  background,
}

const _attackingMarkers = [
  'partner',
  'friends forever',
  "doctor's companion",
];

/// Classifies how [commander] may pair with a second card, based on its
/// Scryfall keywords and oracle text. Background is checked first because a
/// background-pairing commander is never also a partner-pairing one.
CommanderPairing commanderPairingFor(Commander commander) {
  final keywords = commander.keywords.map((k) => k.toLowerCase()).toList();
  final oracle = commander.oracleText.toLowerCase();

  final isBackground = keywords.any((k) => k.contains('choose a background')) ||
      oracle.contains('choose a background');
  if (isBackground) return CommanderPairing.background;

  final isPartner =
      keywords.any((k) => _attackingMarkers.any((m) => k.contains(m))) ||
          _attackingMarkers.any(oracle.contains);
  if (isPartner) return CommanderPairing.partner;

  return CommanderPairing.none;
}
