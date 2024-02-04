// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auto_complete.g.dart';

@JsonSerializable()
class AutoComplete extends Equatable {
  const AutoComplete({
    required this.object,
    required this.data,
    required this.totalValues,
  });

  factory AutoComplete.fromJson(Map<String, dynamic> json) =>
      _$AutoCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$AutoCompleteToJson(this);

  final String object;
  final int totalValues;
  final List<String> data;

  @override
  List<Object?> get props => [
        object,
        data,
        totalValues,
      ];
}
