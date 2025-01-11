import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:player_repository/player_repository.dart';
import 'package:uuid/uuid.dart';

part 'game_model.g.dart';

/// {@template game_model}
/// Model representing a completed game and its statistics
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
class GameModel extends Equatable {
  /// {@macro game_model}
  GameModel({
    required this.players,
    required this.startTime,
    required this.endTime,
    required this.winner,
    required this.durationInSeconds,
    String? id,
  }) : id = id ?? const Uuid().v4();

  /// Creates a GameModel from a JSON map
  factory GameModel.fromJson(Map<String, dynamic> json) =>
      _$GameModelFromJson(json);

  /// Unique identifier for the game
  final String id;

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
        players,
        startTime,
        endTime,
        winner,
        durationInSeconds,
      ];
}
