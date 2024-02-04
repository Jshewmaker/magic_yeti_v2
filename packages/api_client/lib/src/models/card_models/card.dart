// ignore_for_file: public_member_api_docs

import 'package:api_client/src/models/card_models/card_models.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Card extends Equatable {
  const Card({
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

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);

  Map<String, dynamic> toJson() => _$CardToJson(this);

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
  final String typeLine;
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
        scryfallSetUri,
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
