// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'image_uris.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class ImageURIs extends Equatable {
  const ImageURIs({
    required this.small,
    required this.normal,
    required this.large,
    required this.png,
    required this.artCrop,
    required this.borderCrop,
  });

  factory ImageURIs.fromJson(Map<String, dynamic> json) =>
      _$ImageURIsFromJson(json);

  Map<String, dynamic> toJson() => _$ImageURIsToJson(this);

  final String small;
  final String normal;
  final String large;
  final String png;
  final String artCrop;
  final String borderCrop;

  @override
  List<Object?> get props => [
        small,
        normal,
        large,
        png,
        artCrop,
        borderCrop,
      ];
}
