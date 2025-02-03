import 'package:json_annotation/json_annotation.dart';
import 'package:player_repository/models/commander_damage.dart';

part 'opponent.g.dart';

/// {@template opponent}
/// Model representing an opponent in a game
/// {@endtemplate}
@JsonSerializable()
class Opponent {
  /// {@macro opponent}
  Opponent({required this.playerId, required this.damages});

  /// Connect the generated [_$OpponentFromJson] function to the `fromJson`
  factory Opponent.fromJson(Map<String, dynamic> json) =>
      _$OpponentFromJson(json);

  /// The id of the player
  final String playerId;

  /// The damages the player has taken
  final List<CommanderDamage> damages;

  /// Connect the generated [_$OpponentToJson] function to the `toJson`
  Map<String, dynamic> toJson() => _$OpponentToJson(this);

  /// Creates a new instance of the `Opponent` class with the same values
  /// as the current instance
  Opponent copyWith({
    String? playerId,
    List<CommanderDamage>? damages,
  }) =>
      Opponent(
        playerId: playerId ?? this.playerId,
        damages: damages ?? this.damages,
      );
}
