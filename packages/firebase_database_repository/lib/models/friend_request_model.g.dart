// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendRequestModel _$FriendRequestModelFromJson(Map<String, dynamic> json) =>
    FriendRequestModel(
      requestId: json['requestId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      senderName: json['senderName'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$FriendRequestModelToJson(FriendRequestModel instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'senderName': instance.senderName,
      'status': instance.status,
      'timestamp': instance.timestamp.toIso8601String(),
    };
