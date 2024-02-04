import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Player object that holds all player info
class Player extends Equatable {
  const Player({
    required this.name,
    required this.picture,
    required this.playerNumber,
    required this.lifePoints,
    required this.color,
    this.placement = 99,
  });
  final String name;
  final String picture;
  final int playerNumber;
  final int lifePoints;
  final int placement;
  final Color color;

  Player copyWith({
    String? name,
    String? picture,
    int? playerNumber,
    int? lifePoints,
    Color? color,
    int? placement,
  }) {
    return Player(
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
        name,
        color,
        picture,
        playerNumber,
        lifePoints,
        placement,
      ];
}
