import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile_model.g.dart';

/// {@template user_profile_model}
/// Model representing a user's profile
/// {@endtemplate}
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class UserProfileModel extends Equatable {
  /// / {@macro user_profile_model}
  const UserProfileModel({
    required this.id,
    this.email,
    this.isNewUser = false,
    this.isAnonymous = false,
    this.username,
    this.usernameLower,
    this.firstName,
    this.lastName,
    this.bio,
    this.imageUrl,
    this.friendCode,
    this.pin,
    this.onboardingComplete = false,
    this.hasPin = false,
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

  /// Lowercase copy of [username], kept in sync by the repository on every
  /// profile write. Powers the server-side `searchByUsername` prefix
  /// search — do not set this directly.
  final String? usernameLower;

  /// First name of the user
  final String? firstName;

  /// Last name of the user
  final String? lastName;

  /// Bio of the user
  final String? bio;

  /// Image URL of the user
  final String? imageUrl;

  /// Unique friend code for discovery (e.g. "A3F9K2XQ")
  final String? friendCode;

  /// SHA-256 hashed 4-digit PIN for identity verification
  final String? pin;

  /// Whether the user has a PIN set (hash lives in the private
  /// credentials subcollection, so only this flag is public).
  final bool hasPin;

  /// Whether the user has completed the onboarding flow
  final bool onboardingComplete;

  /// An unauthenticated user.
  static const empty = UserProfileModel(id: '');

  /// Copy with method to copy with new values
  UserProfileModel copyWith({
    String? id,
    String? email,
    bool? isNewUser,
    bool? isAnonymous,
    String? username,
    String? usernameLower,
    String? firstName,
    String? lastName,
    String? bio,
    String? imageUrl,
    String? friendCode,
    String? pin,
    bool? onboardingComplete,
    bool? hasPin,
  }) =>
      UserProfileModel(
        id: id ?? this.id,
        email: email ?? this.email,
        username: username ?? this.username,
        usernameLower: usernameLower ?? this.usernameLower,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        bio: bio ?? this.bio,
        imageUrl: imageUrl ?? this.imageUrl,
        isNewUser: isNewUser ?? this.isNewUser,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        friendCode: friendCode ?? this.friendCode,
        pin: pin ?? this.pin,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        hasPin: hasPin ?? this.hasPin,
      );

  /// Whether the profile satisfies the friends-feature requirements:
  /// onboarded, has a username, and has a PIN (new flag or legacy field).
  bool get isComplete =>
      onboardingComplete &&
      (username?.isNotEmpty ?? false) &&
      (hasPin || (pin?.isNotEmpty ?? false));

  @override
  List<Object?> get props => [
        id,
        email,
        isNewUser,
        isAnonymous,
        username,
        usernameLower,
        firstName,
        lastName,
        bio,
        imageUrl,
        friendCode,
        pin,
        onboardingComplete,
        hasPin,
      ];
}
