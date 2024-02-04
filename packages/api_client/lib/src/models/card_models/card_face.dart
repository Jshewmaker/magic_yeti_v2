// ignore_for_file: public_member_api_docs

import 'package:api_client/src/models/card_models/card_models.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_face.g.dart';

@JsonSerializable()
class CardFace extends Equatable {
  const CardFace({
    required this.artist,
    required this.cmc,
    required this.colorIndicator,
    required this.colors,
    required this.flavorText,
    required this.illustrationId,
    required this.imageUris,
    required this.layout,
    required this.loyalty,
    required this.manaCost,
    required this.name,
    required this.object,
    required this.oracleId,
    required this.oracleText,
    required this.power,
    required this.printedName,
    required this.printedText,
    required this.printedTypeLine,
    required this.toughness,
    required this.typeLine,
    required this.watermark,
  });

  factory CardFace.fromJson(Map<String, dynamic> json) =>
      _$CardFaceFromJson(json);

  Map<String, dynamic> toJson() => _$CardFaceToJson(this);

  final String? artist;

  final double? cmc;
  final List<String>? colorIndicator;
  final List<String>? colors;

  final String? flavorText;

  final String? illustrationId;

  final ImageURIs? imageUris;

  final String? layout;

  final String? loyalty;

  final String manaCost;
  final String name;
  final String object;
  final String? oracleId;

  final String? oracleText;
  final String? power;

  final String? printedName;
  final String? printedText;

  final String? printedTypeLine;

  final String? toughness;

  final String? typeLine;
  final String? watermark;

  @override
  List<Object?> get props => [
        artist,
        cmc,
        colorIndicator,
        colors,
        flavorText,
        illustrationId,
        imageUris,
        layout,
        loyalty,
        manaCost,
        name,
        object,
        oracleId,
        oracleText,
        power,
        printedName,
        printedText,
        printedTypeLine,
        toughness,
        typeLine,
        watermark,
      ];
}
