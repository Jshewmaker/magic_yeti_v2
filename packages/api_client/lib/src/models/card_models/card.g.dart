// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Card _$CardFromJson(Map<String, dynamic> json) => Card(
      colorIndicator: (json['color_indicator'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      contentWarning: json['content_warning'] as bool?,
      flavorName: json['flavor_name'] as String?,
      flavorText: json['flavor_text'] as String?,
      lifeModifier: json['life_modifier'] as String?,
      loyalty: json['loyalty'] as String?,
      mtgoFoilId: json['mtgo_foil_id'] as int?,
      power: json['power'] as String?,
      producedMana: (json['produced_mana'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tcgplayerEtchedId: json['tcgplayer_etched_id'] as int?,
      toughness: json['toughness'] as String?,
      handModifier: json['hand_modifier'] as String?,
      object: json['object'] as String,
      id: json['id'] as String,
      set: json['set'] as String,
      oracleId: json['oracle_id'] as String?,
      multiverseIds: (json['multiverse_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      mtgoId: json['mtgo_id'] as int?,
      arenaId: json['arena_id'] as int?,
      tcgplayerId: json['tcgplayer_id'] as int?,
      cardmarketId: json['cardmarket_id'] as int?,
      allParts: (json['all_parts'] as List<dynamic>?)
          ?.map((e) => RelatedCards.fromJson(e as Map<String, dynamic>))
          .toList(),
      artist: json['artist'] as String?,
      artistIds: (json['artist_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      booster: json['booster'] as bool,
      borderColor: json['border_color'] as String,
      cardBackId: json['card_back_id'] as String?,
      cardFaces: (json['card_faces'] as List<dynamic>?)
          ?.map((e) => CardFace.fromJson(e as Map<String, dynamic>))
          .toList(),
      cmc: (json['cmc'] as num?)?.toDouble(),
      collectorNumber: json['collector_number'] as String,
      name: json['name'] as String,
      lang: json['lang'] as String,
      releasedAt: json['released_at'] as String,
      uri: json['uri'] as String,
      scryfallUri: json['scryfall_uri'] as String,
      layout: json['layout'] as String,
      highresImage: json['highres_image'] as bool,
      imageStatus: json['image_status'] as String,
      imageUris: json['image_uris'] == null
          ? null
          : ImageURIs.fromJson(json['image_uris'] as Map<String, dynamic>),
      manaCost: json['mana_cost'] as String?,
      typeLine: json['type_line'] as String,
      oracleText: json['oracle_text'] as String?,
      colors:
          (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      colorIdentity: (json['color_identity'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      keywords:
          (json['keywords'] as List<dynamic>).map((e) => e as String).toList(),
      legalities:
          Legalities.fromJson(json['legalities'] as Map<String, dynamic>),
      games: (json['games'] as List<dynamic>).map((e) => e as String).toList(),
      reserved: json['reserved'] as bool,
      foil: json['foil'] as bool,
      nonfoil: json['nonfoil'] as bool,
      finishes:
          (json['finishes'] as List<dynamic>).map((e) => e as String).toList(),
      oversized: json['oversized'] as bool,
      promo: json['promo'] as bool,
      reprint: json['reprint'] as bool,
      variation: json['variation'] as bool,
      setId: json['set_id'] as String,
      setName: json['set_name'] as String,
      setType: json['set_type'] as String,
      setUri: json['set_uri'] as String,
      setSearchUri: json['set_search_uri'] as String,
      scryfallSetUri: json['scryfall_set_uri'] as String,
      rulingsUri: json['rulings_uri'] as String,
      printsSearchUri: json['prints_search_uri'] as String,
      digital: json['digital'] as bool,
      rarity: json['rarity'] as String,
      illustrationId: json['illustration_id'] as String?,
      frame: json['frame'] as String,
      securityStamp: json['security_stamp'] as String?,
      fullArt: json['full_art'] as bool,
      textless: json['textless'] as bool,
      storySpotlight: json['story_spotlight'] as bool,
      edhrecRank: json['edhrec_rank'] as int?,
      pennyRank: json['penny_rank'] as int?,
      prices: Prices.fromJson(json['prices'] as Map<String, dynamic>),
      relatedUris:
          RelatedURIs.fromJson(json['related_uris'] as Map<String, dynamic>),
      purchaseUris: json['purchase_uris'] == null
          ? null
          : PurchaseURIs.fromJson(
              json['purchase_uris'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CardToJson(Card instance) => <String, dynamic>{
      'object': instance.object,
      'id': instance.id,
      'oracle_id': instance.oracleId,
      'mtgo_id': instance.mtgoId,
      'arena_id': instance.arenaId,
      'multiverse_ids': instance.multiverseIds,
      'tcgplayer_id': instance.tcgplayerId,
      'tcgplayer_etched_id': instance.tcgplayerEtchedId,
      'mtgo_foil_id': instance.mtgoFoilId,
      'cardmarket_id': instance.cardmarketId,
      'name': instance.name,
      'lang': instance.lang,
      'released_at': instance.releasedAt,
      'uri': instance.uri,
      'scryfall_uri': instance.scryfallUri,
      'layout': instance.layout,
      'highres_image': instance.highresImage,
      'image_status': instance.imageStatus,
      'image_uris': instance.imageUris?.toJson(),
      'mana_cost': instance.manaCost,
      'all_parts': instance.allParts?.map((e) => e.toJson()).toList(),
      'card_faces': instance.cardFaces?.map((e) => e.toJson()).toList(),
      'cmc': instance.cmc,
      'life_modifier': instance.lifeModifier,
      'loyalty': instance.loyalty,
      'power': instance.power,
      'produced_mana': instance.producedMana,
      'toughness': instance.toughness,
      'type_line': instance.typeLine,
      'oracle_text': instance.oracleText,
      'colors': instance.colors,
      'color_indicator': instance.colorIndicator,
      'color_identity': instance.colorIdentity,
      'keywords': instance.keywords,
      'legalities': instance.legalities.toJson(),
      'games': instance.games,
      'reserved': instance.reserved,
      'foil': instance.foil,
      'nonfoil': instance.nonfoil,
      'finishes': instance.finishes,
      'oversized': instance.oversized,
      'promo': instance.promo,
      'reprint': instance.reprint,
      'variation': instance.variation,
      'set_id': instance.setId,
      'set': instance.set,
      'set_name': instance.setName,
      'set_type': instance.setType,
      'set_uri': instance.setUri,
      'set_search_uri': instance.setSearchUri,
      'scryfall_set_uri': instance.scryfallSetUri,
      'rulings_uri': instance.rulingsUri,
      'prints_search_uri': instance.printsSearchUri,
      'collector_number': instance.collectorNumber,
      'digital': instance.digital,
      'rarity': instance.rarity,
      'card_back_id': instance.cardBackId,
      'artist': instance.artist,
      'content_warning': instance.contentWarning,
      'flavor_name': instance.flavorName,
      'flavor_text': instance.flavorText,
      'artist_ids': instance.artistIds,
      'illustration_id': instance.illustrationId,
      'border_color': instance.borderColor,
      'frame': instance.frame,
      'security_stamp': instance.securityStamp,
      'full_art': instance.fullArt,
      'textless': instance.textless,
      'booster': instance.booster,
      'story_spotlight': instance.storySpotlight,
      'edhrec_rank': instance.edhrecRank,
      'penny_rank': instance.pennyRank,
      'hand_modifier': instance.handModifier,
      'prices': instance.prices.toJson(),
      'related_uris': instance.relatedUris.toJson(),
      'purchase_uris': instance.purchaseUris?.toJson(),
    };
