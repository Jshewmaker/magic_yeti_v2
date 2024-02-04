// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'related_cards.g.dart';

@JsonSerializable()
class RelatedCards extends Equatable {
  const RelatedCards({
    required this.id,
    required this.component,
    required this.name,
    required this.object,
    required this.typeLine,
    required this.uri,
  });

  factory RelatedCards.fromJson(Map<String, dynamic> json) =>
      _$RelatedCardsFromJson(json);

  Map<String, dynamic> toJson() => _$RelatedCardsToJson(this);

  final String id;
  final String object;
  final String component;
  final String name;
  final String typeLine;
  final String uri;

  @override
  List<Object?> get props => [
        id,
        object,
        component,
        name,
        typeLine,
        uri,
      ];
}
