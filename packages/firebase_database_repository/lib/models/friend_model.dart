import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'friend_model.g.dart';

/// {@template FriendModel}
/// This model represents a friend in the application, encapsulating
/// all necessary fields and providing methods for serialization and deserialization.
///
/// Key features:
/// - Type-safe representation of friend data
/// - Methods for converting to and from Firestore documents
///
/// @dependencies
/// - None
///
/// @notes
/// - Ensure that all fields are properly validated before using this model
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
class FriendModel extends Equatable {
  /// Constructor for FriendModel.
  ///
  /// @param userId The unique identifier for the friend.
  /// @param username The name of the friend.
  /// @param profilePictureUrl The URL of the friend's profile picture.
  const FriendModel({
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
  });

  /// Converts a Firestore document snapshot to a FriendModel.
  factory FriendModel.fromJson(Map<String, dynamic> json) =>
      _$FriendModelFromJson(json);

  /// Converts the FriendModel to a Map for Firestore storage.
  Map<String, dynamic> toJson() => _$FriendModelToJson(this);

  /// The unique identifier for the friend.
  final String userId;

  /// The name of the friend.
  final String username;

  /// The URL of the friend's profile picture.
  final String profilePictureUrl;

  @override
  List<Object> get props => [
        userId,
        username,
        profilePictureUrl,
      ];
}
