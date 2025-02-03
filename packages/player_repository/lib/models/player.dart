import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:player_repository/models/opponent.dart';
import 'package:player_repository/player_repository.dart';

part 'player.g.dart';

/// A utility class that wraps a value that might be updated to null.
/// This allows copyWith to differentiate between "not provided" (null)
/// and "explicitly set to null" (Value(null))
class Value<T> {
  final T? value;
  const Value(this.value);
}

/// Type of damage done to a player.
///
/// [DamageType.commander] - Damage done from the player's commander
/// [DamageType.partner] - Damage done from the player's commander's partner
enum DamageType {
  /// Damage done from the player's commander
  commander,

  /// Damage done from the player's commander's partner
  partner,
}

/// Player state in the game
enum PlayerModelState {
  active,
  eliminated;

  bool get isActive => this == PlayerModelState.active;
  bool get isEliminated => this == PlayerModelState.eliminated;
}

/// {@template player}
/// Player object that holds all player info
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
class Player extends Equatable {
  /// {@macro player}
  const Player({
    required this.id,
    required this.name,
    required this.playerNumber,
    required this.lifePoints,
    required this.color,
    required this.opponents,
    this.commander,
    this.partner,
    this.firebaseId,
    this.state = PlayerModelState.eliminated,
    int? placement,
    int? timeOfDeath,
  })  : _placement = placement,
        _timeOfDeath = timeOfDeath;

  /// Creates a Player object from a JSON map
  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  /// The document ID of the player in Firebase
  final String? firebaseId;

  /// Unique identifier for the player.
  final String id;

  /// Name of the player.
  final String name;

  /// The player's commander card.
  final Commander? commander;

  /// The commander's partner card.
  final Commander? partner;

  /// The player's assigned number in the game.
  final int playerNumber;

  /// The player's current life points.
  final int lifePoints;

  /// The player's color represented as an integer.
  final int color;

  /// The player's current state in the game
  final PlayerModelState state;

  final int? _placement;
  final int? _timeOfDeath;

  /// The player's placement in the game. Only available when player is eliminated.
  int get placement {
    if (!state.isEliminated) {
      throw StateError('Cannot get placement for active player');
    }
    return _placement!;
  }

  /// The time when the player was eliminated. Only available when player is eliminated.
  int get timeOfDeath {
    if (!state.isEliminated) {
      throw StateError('Cannot get time of death for active player');
    }
    return _timeOfDeath!;
  }

  /// Whether the player is still active in the game
  bool get isActive => state.isActive;

  /// Whether the player has been eliminated
  bool get isEliminated => state.isEliminated;

  /// A list representing the damage dealt to the player by each opponent's commander.
  final List<Opponent> opponents;

  /// Creates a new player object with the same values as the current player
  Player copyWith({
    String? id,
    String? name,
    Commander? commander,
    Commander? partner,
    int? playerNumber,
    int? lifePoints,
    int? color,
    String? Function()? firebaseId,
    PlayerModelState? state,
    Value<int?>? placement,
    Value<int?>? timeOfDeath,
    List<Opponent>? opponents,
  }) {
    return Player(
      firebaseId: firebaseId != null ? firebaseId() : this.firebaseId,
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      commander: commander ?? this.commander,
      partner: partner ?? this.partner,
      playerNumber: playerNumber ?? this.playerNumber,
      lifePoints: lifePoints ?? this.lifePoints,
      state: state ?? this.state,
      placement: placement != null ? placement.value : _placement,
      timeOfDeath: timeOfDeath != null ? timeOfDeath.value : _timeOfDeath,
      opponents: opponents ?? this.opponents,
    );
  }

  /// Connect the generated [_$PlayerToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        commander,
        partner,
        playerNumber,
        lifePoints,
        state,
        firebaseId,
        opponents,
        _placement,
        _timeOfDeath,
      ];
}
