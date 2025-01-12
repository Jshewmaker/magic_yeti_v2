import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:player_repository/player_repository.dart';

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
    required this.commander,
    required this.playerNumber,
    required this.lifePoints,
    required this.color,
    required this.commanderDamageList,
    this.firebaseId,
    this.timeOfDeath = -1,
    this.placement = 99,
  });

  /// Creates a Player object from a JSON map
  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  /// The document ID of the player in Firebase
  final String? firebaseId;

  /// Unique identifier for the player.
  final String id;

  /// Name of the player.
  final String name;

  /// The player's commander card.
  final Commander commander;

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
  final int timeOfDeath;

  /// A list representing the damage dealt to the player by each commander,
  /// defaults to an empty map.
  final Map<String, int> commanderDamageList;

  /// Connect the generated [_$PlayerToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  /// Creates a new player object with the same values as the current player,
  Player copyWith({
    String? id,
    String? name,
    Commander? commander,
    int? timeOfDeath,
    int? playerNumber,
    int? lifePoints,
    int? color,
    int? placement,
    String? firebaseId,
    Map<String, int>? commanderDamageList,
  }) {
    return Player(
      firebaseId: firebaseId ?? this.firebaseId,
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      commander: commander ?? this.commander,
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
        commander,
        playerNumber,
        lifePoints,
        placement,
        firebaseId,
        commanderDamageList,
      ];
}
