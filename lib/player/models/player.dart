import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

/// Player object that holds all player info
@JsonSerializable(explicitToJson: true)
class Player extends Equatable {
  const Player({
    required this.id,
    required this.name,
    required this.picture,
    required this.playerNumber,
    required this.lifePoints,
    required this.color,
    this.placement = 99,
  });
  final int id;
  final String name;
  final String picture;
  final int playerNumber;
  final int lifePoints;
  final int placement;
  final int color;

  /// Connect the generated [_$PlayerToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PlayerToJson(this);
  Player copyWith({
    int? id,
    String? name,
    String? picture,
    int? playerNumber,
    int? lifePoints,
    int? color,
    int? placement,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      picture: picture ?? this.picture,
      playerNumber: playerNumber ?? this.playerNumber,
      lifePoints: lifePoints ?? this.lifePoints,
      placement: placement ?? this.placement,
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
