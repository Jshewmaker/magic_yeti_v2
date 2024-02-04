// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'prices.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Prices extends Equatable {
  const Prices({
    required this.usd,
    required this.usdFoil,
    required this.usdEtched,
    required this.eur,
    required this.eurFoil,
    required this.tix,
  });

  factory Prices.fromJson(Map<String, dynamic> json) => _$PricesFromJson(json);

  Map<String, dynamic> toJson() => _$PricesToJson(this);

  final String? usd;
  final String? usdFoil;
  final String? usdEtched;
  final String? eur;
  final String? eurFoil;
  final String? tix;

  @override
  List<Object?> get props => [
        usd,
        usdFoil,
        usdEtched,
        eur,
        eurFoil,
        tix,
      ];
}
