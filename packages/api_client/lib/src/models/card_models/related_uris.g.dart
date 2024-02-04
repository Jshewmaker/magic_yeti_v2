// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'related_uris.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelatedURIs _$RelatedURIsFromJson(Map<String, dynamic> json) => RelatedURIs(
      gatherer: json['gatherer'] as String?,
      tcgplayerInfiniteArticles: json['tcgplayer_infinite_articles'] as String?,
      tcgplayerInfiniteDecks: json['tcgplayer_infinite_decks'] as String?,
      edhrec: json['edhrec'] as String?,
    );

Map<String, dynamic> _$RelatedURIsToJson(RelatedURIs instance) =>
    <String, dynamic>{
      'gatherer': instance.gatherer,
      'tcgplayer_infinite_articles': instance.tcgplayerInfiniteArticles,
      'tcgplayer_infinite_decks': instance.tcgplayerInfiniteDecks,
      'edhrec': instance.edhrec,
    };
