// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_cards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchCards _$SearchCardsFromJson(Map<String, dynamic> json) => SearchCards(
      object: json['object'] as String,
      totalCards: (json['total_cards'] as num).toInt(),
      hasMore: json['has_more'] as bool,
      nextPage: json['next_page'] as String?,
      data: (json['data'] as List<dynamic>)
          .map((e) => MagicCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchCardsToJson(SearchCards instance) =>
    <String, dynamic>{
      'object': instance.object,
      'total_cards': instance.totalCards,
      'has_more': instance.hasMore,
      'next_page': instance.nextPage,
      'data': instance.data.map((e) => e.toJson()).toList(),
    };
