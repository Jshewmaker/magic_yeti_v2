// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'related_uris.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class RelatedURIs extends Equatable {
  const RelatedURIs({
    required this.gatherer,
    required this.tcgplayerInfiniteArticles,
    required this.tcgplayerInfiniteDecks,
    required this.edhrec,
  });

  factory RelatedURIs.fromJson(Map<String, dynamic> json) =>
      _$RelatedURIsFromJson(json);

  Map<String, dynamic> toJson() => _$RelatedURIsToJson(this);

  final String? gatherer;
  final String? tcgplayerInfiniteArticles;
  final String? tcgplayerInfiniteDecks;
  final String? edhrec;

  @override
  List<Object?> get props => [
        gatherer,
        tcgplayerInfiniteArticles,
        tcgplayerInfiniteDecks,
        edhrec,
      ];
}
