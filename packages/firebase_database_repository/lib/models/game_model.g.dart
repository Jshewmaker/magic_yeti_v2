// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameModel _$GameModelFromJson(Map<String, dynamic> json) => GameModel(
      hostId: json['hostId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      winner: Player.fromJson(json['winner'] as Map<String, dynamic>),
      durationInSeconds: (json['durationInSeconds'] as num).toInt(),
      roomId: json['roomId'] as String? ?? '',
      id: json['id'] as String?,
    );

Map<String, dynamic> _$GameModelToJson(GameModel instance) => <String, dynamic>{
      'hostId': instance.hostId,
      'id': instance.id,
      'roomId': instance.roomId,
      'players': instance.players.map((e) => e.toJson()).toList(),
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'winner': instance.winner.toJson(),
      'durationInSeconds': instance.durationInSeconds,
    };
