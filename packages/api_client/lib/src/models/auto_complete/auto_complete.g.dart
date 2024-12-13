// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_complete.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutoComplete _$AutoCompleteFromJson(Map<String, dynamic> json) => AutoComplete(
      object: json['object'] as String,
      data: (json['data'] as List<dynamic>).map((e) => e as String).toList(),
      totalValues: (json['total_values'] as num).toInt(),
    );

Map<String, dynamic> _$AutoCompleteToJson(AutoComplete instance) =>
    <String, dynamic>{
      'object': instance.object,
      'total_values': instance.totalValues,
      'data': instance.data,
    };
