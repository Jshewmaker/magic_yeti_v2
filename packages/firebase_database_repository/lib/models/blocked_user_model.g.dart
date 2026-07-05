// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockedUserModel _$BlockedUserModelFromJson(Map<String, dynamic> json) =>
    BlockedUserModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      imageUrl: json['imageUrl'] as String,
      blockedAt: _$JsonConverterFromJson<Timestamp, DateTime>(
          json['blockedAt'], const TimestampConverter().fromJson),
    );

Map<String, dynamic> _$BlockedUserModelToJson(BlockedUserModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'imageUrl': instance.imageUrl,
      'blockedAt': _$JsonConverterToJson<Timestamp, DateTime>(
          instance.blockedAt, const TimestampConverter().toJson),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
