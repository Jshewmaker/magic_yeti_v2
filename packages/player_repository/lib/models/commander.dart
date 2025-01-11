import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'commander.g.dart';

/// {@template commander}
/// Commander model representing a Magic: The Gathering commander card
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
class Commander extends Equatable {
  /// {@macro commander}
  const Commander({
    required this.name,
    required this.colors,
    required this.cardType,
    required this.imageUrl,
    required this.manaCost,
    required this.oracleText,
    required this.artist,
    this.power,
    this.toughness,
  });

  /// Creates a Commander from JSON map
  factory Commander.fromJson(Map<String, dynamic> json) =>
      _$CommanderFromJson(json);

  /// The name of the commander card
  final String name;

  /// The color identity of the commander (e.g., ['W', 'U', 'B', 'R', 'G'])
  final List<String> colors;

  /// The card type (e.g., "Legendary Creature", "Legendary Planeswalker")
  final String cardType;

  /// URL to the card's image
  final String imageUrl;

  /// The mana cost of the commander
  final String manaCost;

  /// The oracle text (rules text) of the commander
  final String oracleText;

  /// Power (for creatures)
  final String? power;

  final String? artist;

  /// Toughness (for creatures)
  final String? toughness;

  /// Converts the commander to a JSON map
  Map<String, dynamic> toJson() => _$CommanderToJson(this);

  /// Creates a copy of this Commander with the given fields replaced with the new values
  Commander copyWith({
    String? name,
    List<String>? colors,
    String? cardType,
    String? imageUrl,
    String? manaCost,
    String? oracleText,
    String? power,
    String? toughness,
    String? artist,
  }) {
    return Commander(
      name: name ?? this.name,
      colors: colors ?? this.colors,
      cardType: cardType ?? this.cardType,
      imageUrl: imageUrl ?? this.imageUrl,
      manaCost: manaCost ?? this.manaCost,
      oracleText: oracleText ?? this.oracleText,
      power: power ?? this.power,
      toughness: toughness ?? this.toughness,
      artist: artist ?? this.artist,
    );
  }

  @override
  List<Object?> get props => [
        name,
        colors,
        cardType,
        imageUrl,
        manaCost,
        oracleText,
        power,
        toughness,
        artist,
      ];
}
