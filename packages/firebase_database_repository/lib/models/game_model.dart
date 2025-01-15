import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:player_repository/player_repository.dart';

part 'game_model.g.dart';

/// {@template game_model}
/// Model representing a completed game and its statistics
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
class GameModel extends Equatable {
  /// {@macro game_model}
  const GameModel({
    required this.hostId,
    required this.players,
    required this.startTime,
    required this.endTime,
    required this.winner,
    required this.durationInSeconds,
    this.startingPlayerId = '',
    this.roomId = '',
    this.id,
  });

  /// Creates a GameModel from a JSON map
  factory GameModel.fromJson(Map<String, dynamic> json) =>
      _$GameModelFromJson(json);

  /// ID of the host player that created the game
  final String hostId;

  /// Firebase document ID
  final String? id;

  /// ID of the player who went first in turn order.
  final String startingPlayerId;

  /// Unique identifier for the room
  final String roomId;

  /// List of players and their final stats
  final List<Player> players;

  /// When the game started
  final DateTime startTime;

  /// When the game ended
  final DateTime endTime;

  /// The winning player
  final Player winner;

  /// Total duration of the game in seconds
  final int durationInSeconds;

  /// Converts this GameModel to a JSON map
  Map<String, dynamic> toJson() => _$GameModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        hostId,
        roomId,
        players,
        startTime,
        endTime,
        winner,
        durationInSeconds,
      ];

  /// Creates a copy of this GameModel with the given fields replaced with the new values.
  GameModel copyWith({
    String? id,
    String? hostId,
    String? roomId,
    List<Player>? players,
    DateTime? startTime,
    DateTime? endTime,
    Player? winner,
    String? startingPlayerId,
    int? durationInSeconds,
  }) {
    return GameModel(
      id: id ?? this.id,
      startingPlayerId: startingPlayerId ?? this.startingPlayerId,
      hostId: hostId ?? this.hostId,
      roomId: roomId ?? this.roomId,
      players: players ?? this.players,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      winner: winner ?? this.winner,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
    );
  }
}
