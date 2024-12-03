// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      picture: json['picture'] as String,
      playerNumber: (json['playerNumber'] as num).toInt(),
      lifePoints: (json['lifePoints'] as num).toInt(),
      color: (json['color'] as num).toInt(),
      timeOfDeath: json['timeOfDeath'] as String? ?? '',
      commanderDamageList: (json['commanderDamageList'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [0, 0, 0, 0],
      placement: (json['placement'] as num?)?.toInt() ?? 99,
    );

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'picture': instance.picture,
      'playerNumber': instance.playerNumber,
      'lifePoints': instance.lifePoints,
      'placement': instance.placement,
      'color': instance.color,
      'timeOfDeath': instance.timeOfDeath,
      'commanderDamageList': instance.commanderDamageList,
    };
