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
      usernameLower: json['usernameLower'] as String?,
      bio: json['bio'] as String?,
      imageUrl: json['imageUrl'] as String?,
      friendCode: json['friendCode'] as String?,
      pin: json['pin'] as String?,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      hasPin: json['hasPin'] as bool? ?? false,
    );

Map<String, dynamic> _$UserProfileModelToJson(UserProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': ?instance.email,
      'isNewUser': instance.isNewUser,
      'isAnonymous': instance.isAnonymous,
      'username': ?instance.username,
      'usernameLower': ?instance.usernameLower,
      'bio': ?instance.bio,
      'imageUrl': ?instance.imageUrl,
      'friendCode': ?instance.friendCode,
      'pin': ?instance.pin,
      'hasPin': instance.hasPin,
      'onboardingComplete': instance.onboardingComplete,
    };
