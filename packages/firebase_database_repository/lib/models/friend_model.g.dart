// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendModel _$FriendModelFromJson(Map<String, dynamic> json) => FriendModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String,
    );

Map<String, dynamic> _$FriendModelToJson(FriendModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'profilePictureUrl': instance.profilePictureUrl,
    };
