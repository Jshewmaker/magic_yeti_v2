// ignore_for_file: prefer_const_constructors
import 'package:api_client/api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scryfall_bulk_client/scryfall_bulk_client.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:test/test.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockScryfallBulkClient extends Mock implements ScryfallBulkClient {}

MagicCard _card({
  String name = "Atraxa, Praetors' Voice",
  String? oracleId = 'oracle-atraxa',
  String imageStatus = 'highres_scan',
  ImageURIs? imageUris = const ImageURIs(
    small: 'https://img/small.jpg',
    normal: 'https://img/normal.jpg',
    large: 'https://img/large.jpg',
    png: 'https://img/card.png',
    artCrop: 'https://img/art_crop.jpg',
    borderCrop: 'https://img/border_crop.jpg',
  ),
  List<CardFace>? cardFaces,
}) {
  return MagicCard(
    object: 'card',
    id: '',
    oracleId: oracleId,
    mtgoId: null,
    arenaId: null,
    multiverseIds: null,
    tcgplayerId: null,
    tcgplayerEtchedId: null,
    mtgoFoilId: null,
    cardmarketId: null,
    name: name,
    lang: 'en',
    releasedAt: '',
    uri: '',
    scryfallUri: '',
    layout: 'normal',
    highresImage: true,
    imageStatus: imageStatus,
    imageUris: imageUris,
    manaCost: null,
    allParts: null,
    cardFaces: cardFaces,
    cmc: null,
    lifeModifier: null,
    loyalty: null,
    power: null,
    producedMana: null,
    toughness: null,
    typeLine: 'Legendary Creature',
    oracleText: null,
    colors: null,
    colorIndicator: null,
    colorIdentity: const [],
    keywords: const [],
    legalities: const Legalities(
      standard: '',
      future: '',
      historic: '',
      gladiator: '',
      pioneer: '',
      timeless: '',
      modern: '',
      legacy: '',
      pauper: '',
      vintage: '',
      penny: '',
      commander: 'legal',
      oathbreaker: '',
      brawl: '',
      historicbrawl: null,
      alchemy: '',
      paupercommander: '',
      duel: '',
      oldschool: '',
      premodern: '',
      predh: '',
    ),
    games: const [],
    reserved: false,
    foil: false,
    nonfoil: true,
    finishes: const [],
    oversized: false,
    promo: false,
    reprint: false,
    variation: false,
    setId: '',
    set: '',
    setName: '',
    setType: '',
    setUri: '',
    setSearchUri: '',
    scryfallSetUri: '',
    rulingsUri: '',
    printsSearchUri: '',
    collectorNumber: '',
    digital: false,
    rarity: '',
    cardBackId: null,
    artist: null,
    contentWarning: null,
    flavorName: null,
    flavorText: null,
    artistIds: null,
    illustrationId: null,
    borderColor: '',
    frame: '',
    securityStamp: null,
    fullArt: false,
    textless: false,
    booster: false,
    storySpotlight: false,
    edhrecRank: null,
    pennyRank: null,
    handModifier: null,
    prices: const Prices(
      usd: null,
      usdFoil: null,
      usdEtched: null,
      eur: null,
      eurFoil: null,
      tix: null,
    ),
    relatedUris: const RelatedURIs(
      gatherer: null,
      tcgplayerInfiniteArticles: null,
      tcgplayerInfiniteDecks: null,
      edhrec: null,
    ),
    purchaseUris: null,
  );
}

SearchCards _results(List<MagicCard> cards) {
  return SearchCards(
    object: 'list',
    totalCards: cards.length,
    hasMore: false,
    nextPage: null,
    data: cards,
  );
}

void main() {
  group('ScryfallRepository', () {
    late ApiClient apiClient;
    late ScryfallBulkClient bulkClient;
    late ScryfallRepository repository;

    setUp(() {
      apiClient = _MockApiClient();
      bulkClient = _MockScryfallBulkClient();
      repository = ScryfallRepository(
        apiClient: apiClient,
        bulkClient: bulkClient,
      );
    });

    test('can be instantiated', () {
      expect(ScryfallRepository(apiClient: apiClient), isNotNull);
    });

    group('getOracleIdByName', () {
      test('returns oracle ID from the local index without calling the API',
          () async {
        when(() => bulkClient.getOracleIdByName(any()))
            .thenAnswer((_) async => 'oracle-atraxa');

        final oracleId =
            await repository.getOracleIdByName("Atraxa, Praetors' Voice");

        expect(oracleId, 'oracle-atraxa');
        verifyNever(() => apiClient.getOracleIdByName(any()));
      });

      test('falls back to the API when the local index has no match', () async {
        when(() => bulkClient.getOracleIdByName(any()))
            .thenAnswer((_) async => null);
        when(() => apiClient.getOracleIdByName(any()))
            .thenAnswer((_) async => 'oracle-from-api');

        final oracleId = await repository.getOracleIdByName('Brand New Card');

        expect(oracleId, 'oracle-from-api');
        verify(() => apiClient.getOracleIdByName('Brand New Card')).called(1);
      });

      test('returns null when the API fallback fails (e.g. offline)', () async {
        when(() => bulkClient.getOracleIdByName(any()))
            .thenAnswer((_) async => null);
        when(() => apiClient.getOracleIdByName(any())).thenThrow(
          ApiClientError(error: 'offline', stackTrace: StackTrace.current),
        );

        final oracleId = await repository.getOracleIdByName('Brand New Card');

        expect(oracleId, isNull);
      });
    });

    group('getCardFullText', () {
      test('returns local results without calling the API when non-empty',
          () async {
        when(() => bulkClient.searchCards(any()))
            .thenAnswer((_) async => _results([_card()]));

        final results = await repository.getCardFullText(cardName: 'Atraxa');

        expect(results.data, hasLength(1));
        verifyNever(() => apiClient.getCardFullText(any()));
      });

      test('falls back to the API when the local index has no results',
          () async {
        when(() => bulkClient.searchCards(any()))
            .thenAnswer((_) async => _results([]));
        when(() => apiClient.getCardFullText(any()))
            .thenAnswer((_) async => _results([_card(name: 'New Commander')]));

        final results = await repository.getCardFullText(cardName: 'New');

        expect(results.data.single.name, 'New Commander');
        verify(() => apiClient.getCardFullText('New')).called(1);
      });

      test('filters out cards with missing images', () async {
        when(() => bulkClient.searchCards(any())).thenAnswer(
          (_) async => _results([
            _card(),
            _card(name: 'No Image', imageStatus: 'missing', imageUris: null),
          ]),
        );

        final results = await repository.getCardFullText(cardName: 'card');

        expect(results.data, hasLength(1));
        expect(results.totalCards, 1);
      });

      test('hoists first-face image URIs for double-faced cards', () async {
        const faceUris = ImageURIs(
          small: 'https://img/face-small.jpg',
          normal: 'https://img/face-normal.jpg',
          large: 'https://img/face-large.jpg',
          png: 'https://img/face.png',
          artCrop: 'https://img/face-art_crop.jpg',
          borderCrop: 'https://img/face-border_crop.jpg',
        );
        when(() => bulkClient.searchCards(any())).thenAnswer(
          (_) async => _results([
            _card(
              name: 'Double // Faced',
              imageUris: null,
              cardFaces: [
                CardFace(
                  artist: null,
                  cmc: null,
                  colorIndicator: null,
                  colors: null,
                  flavorText: null,
                  illustrationId: null,
                  layout: null,
                  loyalty: null,
                  manaCost: '',
                  name: 'Double',
                  object: 'card_face',
                  oracleId: null,
                  oracleText: null,
                  power: null,
                  printedName: null,
                  printedText: null,
                  printedTypeLine: null,
                  toughness: null,
                  typeLine: null,
                  watermark: null,
                  imageUris: faceUris,
                ),
              ],
            ),
          ]),
        );

        final results = await repository.getCardFullText(cardName: 'double');

        expect(results.data.single.imageUris, faceUris);
      });
    });

    group('searchAllCards', () {
      test('queries the API without reading the commander index', () async {
        when(() => apiClient.getCardFullText(any())).thenAnswer(
          (_) async => _results([_card(name: 'Lightning Bolt')]),
        );

        final results = await repository.searchAllCards(cardName: 'bolt');

        expect(results.data.single.name, 'Lightning Bolt');
        verify(() => apiClient.getCardFullText('bolt')).called(1);
        verifyNever(() => bulkClient.searchCards(any()));
      });

      test('filters out cards with missing images', () async {
        when(() => apiClient.getCardFullText(any())).thenAnswer(
          (_) async => _results([
            _card(name: 'Lightning Bolt'),
            _card(name: 'No Image', imageStatus: 'missing', imageUris: null),
          ]),
        );

        final results = await repository.searchAllCards(cardName: 'bolt');

        expect(results.data, hasLength(1));
      });
    });
  });
}
