// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
      id: json['id'] as String,
      name: json['name'] as String,
      commander: Commander.fromJson(json['commander'] as Map<String, dynamic>),
      playerNumber: (json['playerNumber'] as num).toInt(),
      lifePoints: (json['lifePoints'] as num).toInt(),
      color: (json['color'] as num).toInt(),
      commanderDamageList:
          Map<String, int>.from(json['commanderDamageList'] as Map),
      timeOfDeath: (json['timeOfDeath'] as num?)?.toInt() ?? -1,
      placement: (json['placement'] as num?)?.toInt() ?? 99,
    );

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'commander': instance.commander.toJson(),
      'playerNumber': instance.playerNumber,
      'lifePoints': instance.lifePoints,
      'color': instance.color,
      'placement': instance.placement,
      'timeOfDeath': instance.timeOfDeath,
      'commanderDamageList': instance.commanderDamageList,
    };
