import 'package:api_client/api_client.dart';
import 'package:player_repository/player_repository.dart';

/// Builds a [Commander] from a Scryfall [MagicCard].
///
/// Single source of truth for this mapping, shared by the live player
/// customization flow and the match-details edit flow.
Commander magicCardToCommander(MagicCard card) {
  return Commander(
    oracleId: card.oracleId,
    name: card.name,
    typeLine: card.typeLine ?? '',
    scryFallUrl: card.scryfallUri,
    edhrecRank: card.edhrecRank,
    artist: card.artist ?? '',
    colors: card.colors ?? [],
    colorIdentity: card.colorIdentity,
    cardType: card.typeLine ?? '',
    imageUrl: card.imageUris?.artCrop ?? '',
    manaCost: card.manaCost ?? '',
    oracleText: card.oracleText ?? '',
    power: card.power,
    toughness: card.toughness,
  );
}
