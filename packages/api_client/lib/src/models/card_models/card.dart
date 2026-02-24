// ignore_for_file: public_member_api_docs

import 'package:api_client/src/models/card_models/card_models.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class MagicCard extends Equatable {
  const MagicCard({
    required this.colorIndicator,
    required this.contentWarning,
    required this.flavorName,
    required this.flavorText,
    required this.lifeModifier,
    required this.loyalty,
    required this.mtgoFoilId,
    required this.power,
    required this.producedMana,
    required this.tcgplayerEtchedId,
    required this.toughness,
    required this.handModifier,
    required this.object,
    required this.id,
    required this.set,
    required this.oracleId,
    required this.multiverseIds,
    required this.mtgoId,
    required this.arenaId,
    required this.tcgplayerId,
    required this.cardmarketId,
    required this.allParts,
    required this.artist,
    required this.artistIds,
    required this.booster,
    required this.borderColor,
    required this.cardBackId,
    required this.cardFaces,
    required this.cmc,
    required this.collectorNumber,
    required this.name,
    required this.lang,
    required this.releasedAt,
    required this.uri,
    required this.scryfallUri,
    required this.layout,
    required this.highresImage,
    required this.imageStatus,
    required this.imageUris,
    required this.manaCost,
    required this.typeLine,
    required this.oracleText,
    required this.colors,
    required this.colorIdentity,
    required this.keywords,
    required this.legalities,
    required this.games,
    required this.reserved,
    required this.foil,
    required this.nonfoil,
    required this.finishes,
    required this.oversized,
    required this.promo,
    required this.reprint,
    required this.variation,
    required this.setId,
    required this.setName,
    required this.setType,
    required this.setUri,
    required this.setSearchUri,
    required this.scryfallSetUri,
    required this.rulingsUri,
    required this.printsSearchUri,
    required this.digital,
    required this.rarity,
    required this.illustrationId,
    required this.frame,
    required this.securityStamp,
    required this.fullArt,
    required this.textless,
    required this.storySpotlight,
    required this.edhrecRank,
    required this.pennyRank,
    required this.prices,
    required this.relatedUris,
    required this.purchaseUris,
  });

  factory MagicCard.fromJson(Map<String, dynamic> json) =>
      _$MagicCardFromJson(json);

  Map<String, dynamic> toJson() => _$MagicCardToJson(this);

  MagicCard copyWith({
    String? object,
    String? id,
    String? oracleId,
    int? mtgoId,
    int? arenaId,
    List<int>? multiverseIds,
    int? tcgplayerId,
    int? tcgplayerEtchedId,
    int? mtgoFoilId,
    int? cardmarketId,
    String? name,
    String? lang,
    String? releasedAt,
    String? uri,
    String? scryfallUri,
    String? layout,
    bool? highresImage,
    String? imageStatus,
    ImageURIs? imageUris,
    String? manaCost,
    List<RelatedCards>? allParts,
    List<CardFace>? cardFaces,
    double? cmc,
    String? lifeModifier,
    String? loyalty,
    String? power,
    List<String>? producedMana,
    String? toughness,
    String? typeLine,
    String? oracleText,
    List<String>? colors,
    List<String>? colorIndicator,
    List<String>? colorIdentity,
    List<String>? keywords,
    Legalities? legalities,
    List<String>? games,
    bool? reserved,
    bool? foil,
    bool? nonfoil,
    List<String>? finishes,
    bool? oversized,
    bool? promo,
    bool? reprint,
    bool? variation,
    String? setId,
    String? set,
    String? setName,
    String? setType,
    String? setUri,
    String? setSearchUri,
    String? scryfallSetUri,
    String? rulingsUri,
    String? printsSearchUri,
    String? collectorNumber,
    bool? digital,
    String? rarity,
    String? cardBackId,
    String? artist,
    bool? contentWarning,
    String? flavorName,
    String? flavorText,
    List<String>? artistIds,
    String? illustrationId,
    String? borderColor,
    String? frame,
    String? securityStamp,
    bool? fullArt,
    bool? textless,
    bool? booster,
    bool? storySpotlight,
    int? edhrecRank,
    int? pennyRank,
    String? handModifier,
    Prices? prices,
    RelatedURIs? relatedUris,
    PurchaseURIs? purchaseUris,
  }) {
    return MagicCard(
      object: object ?? this.object,
      id: id ?? this.id,
      oracleId: oracleId ?? this.oracleId,
      mtgoId: mtgoId ?? this.mtgoId,
      arenaId: arenaId ?? this.arenaId,
      multiverseIds: multiverseIds ?? this.multiverseIds,
      tcgplayerId: tcgplayerId ?? this.tcgplayerId,
      tcgplayerEtchedId: tcgplayerEtchedId ?? this.tcgplayerEtchedId,
      mtgoFoilId: mtgoFoilId ?? this.mtgoFoilId,
      cardmarketId: cardmarketId ?? this.cardmarketId,
      name: name ?? this.name,
      lang: lang ?? this.lang,
      releasedAt: releasedAt ?? this.releasedAt,
      uri: uri ?? this.uri,
      scryfallUri: scryfallUri ?? this.scryfallUri,
      layout: layout ?? this.layout,
      highresImage: highresImage ?? this.highresImage,
      imageStatus: imageStatus ?? this.imageStatus,
      imageUris: imageUris ?? this.imageUris,
      manaCost: manaCost ?? this.manaCost,
      allParts: allParts ?? this.allParts,
      cardFaces: cardFaces ?? this.cardFaces,
      cmc: cmc ?? this.cmc,
      lifeModifier: lifeModifier ?? this.lifeModifier,
      loyalty: loyalty ?? this.loyalty,
      power: power ?? this.power,
      producedMana: producedMana ?? this.producedMana,
      toughness: toughness ?? this.toughness,
      typeLine: typeLine ?? this.typeLine,
      oracleText: oracleText ?? this.oracleText,
      colors: colors ?? this.colors,
      colorIndicator: colorIndicator ?? this.colorIndicator,
      colorIdentity: colorIdentity ?? this.colorIdentity,
      keywords: keywords ?? this.keywords,
      legalities: legalities ?? this.legalities,
      games: games ?? this.games,
      reserved: reserved ?? this.reserved,
      foil: foil ?? this.foil,
      nonfoil: nonfoil ?? this.nonfoil,
      finishes: finishes ?? this.finishes,
      oversized: oversized ?? this.oversized,
      promo: promo ?? this.promo,
      reprint: reprint ?? this.reprint,
      variation: variation ?? this.variation,
      setId: setId ?? this.setId,
      set: set ?? this.set,
      setName: setName ?? this.setName,
      setType: setType ?? this.setType,
      setUri: setUri ?? this.setUri,
      setSearchUri: setSearchUri ?? this.setSearchUri,
      scryfallSetUri: scryfallSetUri ?? this.scryfallSetUri,
      rulingsUri: rulingsUri ?? this.rulingsUri,
      printsSearchUri: printsSearchUri ?? this.printsSearchUri,
      collectorNumber: collectorNumber ?? this.collectorNumber,
      digital: digital ?? this.digital,
      rarity: rarity ?? this.rarity,
      cardBackId: cardBackId ?? this.cardBackId,
      artist: artist ?? this.artist,
      contentWarning: contentWarning ?? this.contentWarning,
      flavorName: flavorName ?? this.flavorName,
      flavorText: flavorText ?? this.flavorText,
      artistIds: artistIds ?? this.artistIds,
      illustrationId: illustrationId ?? this.illustrationId,
      borderColor: borderColor ?? this.borderColor,
      frame: frame ?? this.frame,
      securityStamp: securityStamp ?? this.securityStamp,
      fullArt: fullArt ?? this.fullArt,
      textless: textless ?? this.textless,
      booster: booster ?? this.booster,
      storySpotlight: storySpotlight ?? this.storySpotlight,
      edhrecRank: edhrecRank ?? this.edhrecRank,
      pennyRank: pennyRank ?? this.pennyRank,
      handModifier: handModifier ?? this.handModifier,
      prices: prices ?? this.prices,
      relatedUris: relatedUris ?? this.relatedUris,
      purchaseUris: purchaseUris ?? this.purchaseUris,
    );
  }

  final String object;
  final String id;
  final String? oracleId;
  final int? mtgoId;
  final int? arenaId;
  final List<int>? multiverseIds;
  final int? tcgplayerId;
  final int? tcgplayerEtchedId;
  final int? mtgoFoilId;
  final int? cardmarketId;
  final String name;
  final String lang;
  final String releasedAt;
  final String uri;
  final String scryfallUri;
  final String layout;
  final bool highresImage;
  final String imageStatus;
  final ImageURIs? imageUris;
  final String? manaCost;
  final List<RelatedCards>? allParts;
  final List<CardFace>? cardFaces;
  final double? cmc;
  final String? lifeModifier;
  final String? loyalty;
  final String? power;
  final List<String>? producedMana;
  final String? toughness;
  final String? typeLine;
  final String? oracleText;
  final List<String>? colors;
  final List<String>? colorIndicator;
  final List<String> colorIdentity;
  final List<String> keywords;
  final Legalities legalities;
  final List<String> games;
  final bool reserved;
  final bool foil;
  final bool nonfoil;
  final List<String> finishes;
  final bool oversized;
  final bool promo;
  final bool reprint;
  final bool variation;
  final String setId;
  final String set;
  final String setName;
  final String setType;
  final String setUri;
  final String setSearchUri;
  final String scryfallSetUri;
  final String rulingsUri;
  final String printsSearchUri;
  final String collectorNumber;
  final bool digital;
  final String rarity;
  final String? cardBackId;

  final String? artist;
  final bool? contentWarning;
  final String? flavorName;
  final String? flavorText;
  final List<String>? artistIds;
  final String? illustrationId;

  final String borderColor;
  final String frame;
  final String? securityStamp;
  final bool fullArt;
  final bool textless;
  final bool booster;
  final bool storySpotlight;
  final int? edhrecRank;
  final int? pennyRank;
  final String? handModifier;
  final Prices prices;
  final RelatedURIs relatedUris;
  final PurchaseURIs? purchaseUris;

  @override
  List<Object?> get props => [
        object,
        id,
        oracleId,
        multiverseIds,
        mtgoId,
        arenaId,
        tcgplayerId,
        cardmarketId,
        name,
        lang,
        releasedAt,
        uri,
        scryfallUri,
        layout,
        highresImage,
        imageStatus,
        imageUris,
        manaCost,
        cmc,
        typeLine,
        oracleText,
        colors,
        colorIdentity,
        keywords,
        legalities,
        games,
        reserved,
        foil,
        nonfoil,
        finishes,
        oversized,
        promo,
        reprint,
        variation,
        setId,
        set,
        setName,
        setType,
        setUri,
        setSearchUri,
        scryfallSetUri,
        rulingsUri,
        printsSearchUri,
        collectorNumber,
        digital,
        rarity,
        cardBackId,
        artist,
        artistIds,
        illustrationId,
        borderColor,
        frame,
        securityStamp,
        fullArt,
        textless,
        booster,
        storySpotlight,
        edhrecRank,
        pennyRank,
        prices,
        relatedUris,
        purchaseUris,
      ];
}
