// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
      id: json['id'] as String,
      name: json['name'] as String,
      playerNumber: (json['playerNumber'] as num).toInt(),
      lifePoints: (json['lifePoints'] as num).toInt(),
      color: (json['color'] as num).toInt(),
      opponents: (json['opponents'] as List<dynamic>)
          .map((e) => Opponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      commander: json['commander'] == null
          ? null
          : Commander.fromJson(json['commander'] as Map<String, dynamic>),
      partner: json['partner'] == null
          ? null
          : Commander.fromJson(json['partner'] as Map<String, dynamic>),
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
      'partner': instance.partner?.toJson(),
      'playerNumber': instance.playerNumber,
      'lifePoints': instance.lifePoints,
      'color': instance.color,
      'state': _$PlayerModelStateEnumMap[instance.state]!,
      'placement': instance.placement,
      'timeOfDeath': instance.timeOfDeath,
      'opponents': instance.opponents.map((e) => e.toJson()).toList(),
    };

const _$PlayerModelStateEnumMap = {
  PlayerModelState.active: 'active',
  PlayerModelState.eliminated: 'eliminated',
};
