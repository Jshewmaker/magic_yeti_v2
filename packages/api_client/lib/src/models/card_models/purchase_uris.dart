// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'purchase_uris.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class PurchaseURIs extends Equatable {
  const PurchaseURIs({
    required this.tcgplayer,
    required this.cardhoarder,
    required this.cardmarket,
  });

  factory PurchaseURIs.fromJson(Map<String, dynamic> json) =>
      _$PurchaseURIsFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseURIsToJson(this);

  final String tcgplayer;
  final String cardmarket;
  final String cardhoarder;

  @override
  List<Object?> get props => [tcgplayer, cardhoarder, cardmarket];
}
