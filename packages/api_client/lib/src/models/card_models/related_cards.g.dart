// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'related_cards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelatedCards _$RelatedCardsFromJson(Map<String, dynamic> json) => RelatedCards(
      id: json['id'] as String,
      component: json['component'] as String,
      name: json['name'] as String,
      object: json['object'] as String,
      typeLine: json['type_line'] as String,
      uri: json['uri'] as String,
    );

Map<String, dynamic> _$RelatedCardsToJson(RelatedCards instance) =>
    <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'component': instance.component,
      'name': instance.name,
      'type_line': instance.typeLine,
      'uri': instance.uri,
    };
