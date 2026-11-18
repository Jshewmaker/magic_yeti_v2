import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:player_repository/models/player.dart';

part 'game_snapshot.g.dart';

/// {@template game_snapshot}
/// Model representing a snapshot of the in-progress game for undo/restore.
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
class GameSnapshot extends Equatable {
  /// {@macro game_snapshot}
  const GameSnapshot({
    required this.players,
    // Add more fields here if PlayerRepository manages more game state
  });

  /// Creates a GameSnapshot from a JSON map
  factory GameSnapshot.fromJson(Map<String, dynamic> json) =>
      _$GameSnapshotFromJson(json);

  /// The list of players at the time of the snapshot
  final List<Player> players;

  /// Converts this GameSnapshot to a JSON map
  Map<String, dynamic> toJson() => _$GameSnapshotToJson(this);

  @override
  List<Object?> get props => [players];
}
