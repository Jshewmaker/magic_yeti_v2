// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commander.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Commander _$CommanderFromJson(Map<String, dynamic> json) => Commander(
      name: json['name'] as String,
      colors:
          (json['colors'] as List<dynamic>).map((e) => e as String).toList(),
      cardType: json['cardType'] as String,
      imageUrl: json['imageUrl'] as String,
      manaCost: json['manaCost'] as String,
      oracleText: json['oracleText'] as String,
      artist: json['artist'] as String?,
      typeLine: json['typeLine'] as String?,
      scryFallUrl: json['scryFallUrl'] as String? ?? '',
      colorIdentity: (json['colorIdentity'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      edhrecRank: (json['edhrecRank'] as num?)?.toInt(),
      power: json['power'] as String?,
      toughness: json['toughness'] as String?,
    );

Map<String, dynamic> _$CommanderToJson(Commander instance) => <String, dynamic>{
      'name': instance.name,
      'colors': instance.colors,
      if (instance.colorIdentity case final value?) 'colorIdentity': value,
      if (instance.typeLine case final value?) 'typeLine': value,
      if (instance.edhrecRank case final value?) 'edhrecRank': value,
      if (instance.scryFallUrl case final value?) 'scryFallUrl': value,
      'cardType': instance.cardType,
      'imageUrl': instance.imageUrl,
      'manaCost': instance.manaCost,
      'oracleText': instance.oracleText,
      if (instance.power case final value?) 'power': value,
      if (instance.artist case final value?) 'artist': value,
      if (instance.toughness case final value?) 'toughness': value,
    };
