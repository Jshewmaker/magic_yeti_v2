import 'package:api_client/api_client.dart';
import 'package:player_repository/player_repository.dart';

/// Maps a Scryfall [MagicCard] to a [Commander] model.
///
/// Extracts the card's essential properties and converts them to the
/// Commander representation for use in game state and history.
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
    keywords: card.keywords,
  );
}
