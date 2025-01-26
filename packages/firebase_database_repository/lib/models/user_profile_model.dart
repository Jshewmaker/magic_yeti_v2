import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile_model.g.dart';

/// {@template user_profile_model}
/// Model representing a user's profile
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
class UserProfileModel extends Equatable {
  /// / {@macro user_profile_model}
  const UserProfileModel({
    required this.id,
    this.email,
    this.isNewUser = false,
    this.isAnonymous = false,
    this.username,
    this.firstName,
    this.lastName,
    this.bio,
    this.imageUrl,
  });

  /// Factory constructor for a [UserProfileModel] from a JSON map
  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  /// Converts this UserProfileModel to a JSON map
  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  /// Firebase ID of the user
  final String id;

  /// Email of the user
  final String? email;

  /// Whether the user is a new user
  final bool isNewUser;

  /// Whether the user is anonymous
  final bool isAnonymous;

  /// Username of the user
  final String? username;

  /// First name of the user
  final String? firstName;

  /// Last name of the user
  final String? lastName;

  /// Bio of the user
  final String? bio;

  /// Image URL of the user
  final String? imageUrl;

  /// An unauthenticated user.
  static const empty = UserProfileModel(id: '');

  /// Copy with method to copy with new values
  UserProfileModel copyWith({
    String? id,
    String? email,
    bool? isNewUser,
    bool? isAnonymous,
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? imageUrl,
  }) =>
      UserProfileModel(
        id: id ?? this.id,
        email: email ?? this.email,
        username: username ?? this.username,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        bio: bio ?? this.bio,
        imageUrl: imageUrl ?? this.imageUrl,
        isNewUser: isNewUser ?? this.isNewUser,
        isAnonymous: isAnonymous ?? this.isAnonymous,
      );

  @override
  List<Object?> get props => [
        id,
        email,
        isNewUser,
        isAnonymous,
        username,
        firstName,
        lastName,
        bio,
        imageUrl,
      ];
}
