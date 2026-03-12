// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commander.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Commander _$CommanderFromJson(Map<String, dynamic> json) => Commander(
  name: json['name'] as String,
  colors: (json['colors'] as List<dynamic>).map((e) => e as String).toList(),
  cardType: json['cardType'] as String,
  imageUrl: json['imageUrl'] as String,
  manaCost: json['manaCost'] as String,
  oracleText: json['oracleText'] as String,
  artist: json['artist'] as String?,
  oracleId: json['oracleId'] as String?,
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
  'oracleId': ?instance.oracleId,
  'name': instance.name,
  'colors': instance.colors,
  'colorIdentity': ?instance.colorIdentity,
  'typeLine': ?instance.typeLine,
  'edhrecRank': ?instance.edhrecRank,
  'scryFallUrl': ?instance.scryFallUrl,
  'cardType': instance.cardType,
  'imageUrl': instance.imageUrl,
  'manaCost': instance.manaCost,
  'oracleText': instance.oracleText,
  'power': ?instance.power,
  'artist': ?instance.artist,
  'toughness': ?instance.toughness,
};
