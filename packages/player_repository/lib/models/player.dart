import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

/// {@template player}
/// Player object that holds all player info
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
class Player extends Equatable {
  /// {@macro player}
  const Player({
    required this.id,
    required this.name,
    required this.picture,
    required this.playerNumber,
    required this.lifePoints,
    required this.color,
    this.timeOfDeath = '',
    this.commanderDamageList = const [0, 0, 0, 0],
    this.placement = 99,
  });

  /// Unique identifier for the player.
  final int id;

  /// Name of the player.
  final String name;

  /// URL or path to the player's picture.
  final String picture;

  /// The player's assigned number in the game.
  final int playerNumber;

  /// The player's current life points.
  final int lifePoints;

  /// The player's color represented as an integer.
  final int color;

  /// The player's placement in the game, defaults to 99.
  final int placement;

  /// The time when the player was eliminated from the game,
  /// defaults to an empty string.
  final String timeOfDeath;

  /// A list representing the damage dealt to the player by each commander,
  /// defaults to [0, 0, 0, 0].
  final List<int> commanderDamageList;

  /// Connect the generated [_$PlayerToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  /// Creates a new player object with the same values as the current player,
  Player copyWith({
    int? id,
    String? name,
    String? picture,
    String? timeOfDeath,
    int? playerNumber,
    int? lifePoints,
    int? color,
    int? placement,
    List<int>? commanderDamageList,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      picture: picture ?? this.picture,
      playerNumber: playerNumber ?? this.playerNumber,
      lifePoints: lifePoints ?? this.lifePoints,
      placement: placement ?? this.placement,
      timeOfDeath: timeOfDeath ?? this.timeOfDeath,
      commanderDamageList: commanderDamageList ?? this.commanderDamageList,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        picture,
        playerNumber,
        lifePoints,
        placement,
      ];
}
