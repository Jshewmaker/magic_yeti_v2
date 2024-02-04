// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_face.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardFace _$CardFaceFromJson(Map<String, dynamic> json) => CardFace(
      artist: json['artist'] as String?,
      cmc: (json['cmc'] as num?)?.toDouble(),
      colorIndicator: (json['color_indicator'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      colors:
          (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      flavorText: json['flavor_text'] as String?,
      illustrationId: json['illustration_id'] as String?,
      imageUris: json['image_uris'] == null
          ? null
          : ImageURIs.fromJson(json['image_uris'] as Map<String, dynamic>),
      layout: json['layout'] as String?,
      loyalty: json['loyalty'] as String?,
      manaCost: json['mana_cost'] as String,
      name: json['name'] as String,
      object: json['object'] as String,
      oracleId: json['oracle_id'] as String?,
      oracleText: json['oracle_text'] as String?,
      power: json['power'] as String?,
      printedName: json['printed_name'] as String?,
      printedText: json['printed_text'] as String?,
      printedTypeLine: json['printed_type_line'] as String?,
      toughness: json['toughness'] as String?,
      typeLine: json['type_line'] as String?,
      watermark: json['watermark'] as String?,
    );

Map<String, dynamic> _$CardFaceToJson(CardFace instance) => <String, dynamic>{
      'artist': instance.artist,
      'cmc': instance.cmc,
      'color_indicator': instance.colorIndicator,
      'colors': instance.colors,
      'flavor_text': instance.flavorText,
      'illustration_id': instance.illustrationId,
      'image_uris': instance.imageUris,
      'layout': instance.layout,
      'loyalty': instance.loyalty,
      'mana_cost': instance.manaCost,
      'name': instance.name,
      'object': instance.object,
      'oracle_id': instance.oracleId,
      'oracle_text': instance.oracleText,
      'power': instance.power,
      'printed_name': instance.printedName,
      'printed_text': instance.printedText,
      'printed_type_line': instance.printedTypeLine,
      'toughness': instance.toughness,
      'type_line': instance.typeLine,
      'watermark': instance.watermark,
    };
