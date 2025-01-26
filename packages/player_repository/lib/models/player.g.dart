// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
      id: json['id'] as String,
      name: json['name'] as String,
      commander: json['commander'] == null
          ? null
          : Commander.fromJson(json['commander'] as Map<String, dynamic>),
      playerNumber: (json['playerNumber'] as num).toInt(),
      lifePoints: (json['lifePoints'] as num).toInt(),
      color: (json['color'] as num).toInt(),
      commanderDamageList:
          Map<String, int>.from(json['commanderDamageList'] as Map),
      firebaseId: json['firebaseId'] as String?,
      state: $enumDecodeNullable(_$PlayerModelStateEnumMap, json['state']) ??
          PlayerModelState.eliminated,
      placement: (json['placement'] as num?)?.toInt(),
      timeOfDeath: (json['timeOfDeath'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
      'firebaseId': instance.firebaseId,
      'id': instance.id,
      'name': instance.name,
      'commander': instance.commander?.toJson(),
      'playerNumber': instance.playerNumber,
      'lifePoints': instance.lifePoints,
      'color': instance.color,
      'state': _$PlayerModelStateEnumMap[instance.state]!,
      'placement': instance.placement,
      'timeOfDeath': instance.timeOfDeath,
      'commanderDamageList': instance.commanderDamageList,
    };

const _$PlayerModelStateEnumMap = {
  PlayerModelState.active: 'active',
  PlayerModelState.eliminated: 'eliminated',
};
