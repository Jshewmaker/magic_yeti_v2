import 'package:api_client/api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockMagicCard extends Mock implements MagicCard {}

/// Builds a mocktail-backed [MagicCard] with only the getters the app reads
/// stubbed. Avoids the 60-field constructor and deeply-nested required models.
MagicCard buildMagicCard({
  String id = 'card-id',
  String name = 'Atraxa',
  String typeLine = 'Legendary Creature',
  String scryfallUri = 'https://scryfall.test/card',
  String? oracleId = 'oracle-1',
  int? edhrecRank = 5,
  String? artist = 'Artist',
  List<String>? colors = const ['W', 'U', 'B', 'G'],
  List<String> colorIdentity = const ['W', 'U', 'B', 'G'],
  ImageURIs? imageUris = const ImageURIs(
    small: '',
    normal: 'https://img.test/normal.jpg',
    large: '',
    png: '',
    artCrop: 'https://img.test/art_crop.jpg',
    borderCrop: '',
  ),
  String? manaCost = '{G}{W}{U}{B}',
  String? oracleText = 'text',
  String? power = '4',
  String? toughness = '4',
}) {
  final card = MockMagicCard();
  when(() => card.id).thenReturn(id);
  when(() => card.name).thenReturn(name);
  when(() => card.typeLine).thenReturn(typeLine);
  when(() => card.scryfallUri).thenReturn(scryfallUri);
  when(() => card.oracleId).thenReturn(oracleId);
  when(() => card.edhrecRank).thenReturn(edhrecRank);
  when(() => card.artist).thenReturn(artist);
  when(() => card.colors).thenReturn(colors);
  when(() => card.colorIdentity).thenReturn(colorIdentity);
  when(() => card.imageUris).thenReturn(imageUris);
  when(() => card.manaCost).thenReturn(manaCost);
  when(() => card.oracleText).thenReturn(oracleText);
  when(() => card.power).thenReturn(power);
  when(() => card.toughness).thenReturn(toughness);
  when(() => card.cardFaces).thenReturn(null);
  return card;
}
