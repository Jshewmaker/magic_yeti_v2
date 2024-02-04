// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'legalities.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Legalities extends Equatable {
  const Legalities({
    required this.standard,
    required this.future,
    required this.historic,
    required this.gladiator,
    required this.pioneer,
    required this.explorer,
    required this.modern,
    required this.legacy,
    required this.pauper,
    required this.vintage,
    required this.penny,
    required this.commander,
    required this.oathbreaker,
    required this.brawl,
    required this.historicbrawl,
    required this.alchemy,
    required this.paupercommander,
    required this.duel,
    required this.oldschool,
    required this.premodern,
    required this.predh,
  });

  factory Legalities.fromJson(Map<String, dynamic> json) =>
      _$LegalitiesFromJson(json);

  Map<String, dynamic> toJson() => _$LegalitiesToJson(this);

  final String standard;
  final String future;
  final String historic;
  final String gladiator;
  final String pioneer;
  final String explorer;
  final String modern;
  final String legacy;
  final String pauper;
  final String vintage;
  final String penny;
  final String commander;
  final String oathbreaker;
  final String brawl;
  final String? historicbrawl;
  final String alchemy;
  final String paupercommander;
  final String duel;
  final String oldschool;
  final String premodern;
  final String predh;

  @override
  List<Object?> get props => [
        standard,
        future,
        historic,
        gladiator,
        pioneer,
        explorer,
        modern,
        legacy,
        pauper,
        vintage,
        penny,
        commander,
        oathbreaker,
        brawl,
        historicbrawl,
        alchemy,
        paupercommander,
        duel,
        oldschool,
        premodern,
        predh,
      ];
}
