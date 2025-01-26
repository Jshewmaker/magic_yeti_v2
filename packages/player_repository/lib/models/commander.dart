import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'commander.g.dart';

/// {@template commander}
/// Commander model representing a Magic: The Gathering commander card
/// {@endtemplate}
@JsonSerializable(explicitToJson: true, includeIfNull: false)
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
    this.typeLine,
    this.scryFallUrl = '',
    this.colorIdentity,
    this.edhrecRank,
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

  /// The colors in this card’s color indicator, if any. A null value for this
  /// field indicates the card does not have one.
  final List<String>? colorIdentity;

  /// The type line of this card.
  final String? typeLine;

  /// The EDHREC rank of the commander card
  final int? edhrecRank;

  /// The ScryFall URL of the commander card
  final String? scryFallUrl;

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

  /// The colors in this card’s color indicator, if any. A null value for this
  final String? artist;

  /// Toughness (for creatures)
  final String? toughness;

  /// Converts the commander to a JSON map
  Map<String, dynamic> toJson() => _$CommanderToJson(this);

  /// Creates a copy of this Commander with the given fields replaced with the
  /// new values
  Commander copyWith({
    String? name,
    List<String>? colors,
    List<String>? colorIdentity,
    int? edhrecRank,
    String? typeLine,
    String? scryFallUrl,
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
      colorIdentity: colorIdentity ?? this.colorIdentity,
      edhrecRank: edhrecRank ?? this.edhrecRank,
      typeLine: typeLine ?? this.typeLine,
      scryFallUrl: scryFallUrl ?? this.scryFallUrl,
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
        colorIdentity,
        typeLine,
        scryFallUrl,
        cardType,
        imageUrl,
        manaCost,
        oracleText,
        edhrecRank,
        power,
        toughness,
        artist,
      ];
}
