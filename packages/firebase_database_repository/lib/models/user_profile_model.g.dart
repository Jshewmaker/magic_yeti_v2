// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      isNewUser: json['isNewUser'] as bool? ?? false,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      username: json['username'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      bio: json['bio'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$UserProfileModelToJson(UserProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'isNewUser': instance.isNewUser,
      'isAnonymous': instance.isAnonymous,
      'username': instance.username,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'bio': instance.bio,
      'imageUrl': instance.imageUrl,
    };
