// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
      id: json['id'] as int,
      name: json['name'] as String,
      picture: json['picture'] as String,
      playerNumber: json['playerNumber'] as int,
      lifePoints: json['lifePoints'] as int,
      color: json['color'] as int,
      placement: json['placement'] as int? ?? 99,
    );

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'picture': instance.picture,
      'playerNumber': instance.playerNumber,
      'lifePoints': instance.lifePoints,
      'placement': instance.placement,
      'color': instance.color,
    };
