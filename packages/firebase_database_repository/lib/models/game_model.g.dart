// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameModel _$GameModelFromJson(Map<String, dynamic> json) => GameModel(
      players: (json['players'] as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      winnerId: json['winnerId'] as String,
      durationInSeconds: (json['durationInSeconds'] as num).toInt(),
      hostId: json['hostId'] as String? ?? '',
      startingPlayerId: json['startingPlayerId'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      id: json['id'] as String?,
    );

Map<String, dynamic> _$GameModelToJson(GameModel instance) => <String, dynamic>{
      'hostId': instance.hostId,
      'id': instance.id,
      'startingPlayerId': instance.startingPlayerId,
      'roomId': instance.roomId,
      'players': instance.players.map((e) => e.toJson()).toList(),
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'winnerId': instance.winnerId,
      'durationInSeconds': instance.durationInSeconds,
    };
