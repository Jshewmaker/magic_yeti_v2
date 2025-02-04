// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opponent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Opponent _$OpponentFromJson(Map<String, dynamic> json) => Opponent(
      playerId: json['playerId'] as String,
      damages: (json['damages'] as List<dynamic>)
          .map((e) => CommanderDamage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OpponentToJson(Opponent instance) => <String, dynamic>{
      'playerId': instance.playerId,
      'damages': instance.damages.map((e) => e.toJson()).toList(),
    };
