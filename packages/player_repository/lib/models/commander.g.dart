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
      power: json['power'] as String?,
      toughness: json['toughness'] as String?,
    );

Map<String, dynamic> _$CommanderToJson(Commander instance) => <String, dynamic>{
      'name': instance.name,
      'colors': instance.colors,
      'cardType': instance.cardType,
      'imageUrl': instance.imageUrl,
      'manaCost': instance.manaCost,
      'oracleText': instance.oracleText,
      'power': instance.power,
      'artist': instance.artist,
      'toughness': instance.toughness,
    };
