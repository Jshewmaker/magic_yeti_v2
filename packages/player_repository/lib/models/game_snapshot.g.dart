// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameSnapshot _$GameSnapshotFromJson(Map<String, dynamic> json) => GameSnapshot(
      players: (json['players'] as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GameSnapshotToJson(GameSnapshot instance) =>
    <String, dynamic>{
      'players': instance.players.map((e) => e.toJson()).toList(),
    };
