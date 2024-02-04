// ignore_for_file: public_member_api_docs

import 'package:api_client/src/models/models.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_cards.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class SearchCards extends Equatable {
  const SearchCards({
    required this.object,
    required this.totalCards,
    required this.hasMore,
    required this.nextPage,
    required this.data,
  });

  factory SearchCards.fromJson(Map<String, dynamic> json) =>
      _$SearchCardsFromJson(json);

  Map<String, dynamic> toJson() => _$SearchCardsToJson(this);
  final String object;
  final int totalCards;
  final bool hasMore;
  final String? nextPage;
  final List<Card> data;

  @override
  List<Object?> get props => [
        object,
        totalCards,
        hasMore,
        nextPage,
        data,
      ];
}
