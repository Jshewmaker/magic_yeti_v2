import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/helpers/timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';
// ignore: directives_ordering
import 'package:cloud_firestore/cloud_firestore.dart';

part 'blocked_user_model.g.dart';

/// {@template blocked_user_model}
/// This model represents a user that the current user has blocked,
/// denormalizing enough profile data to render a "Blocked users" list
/// without extra reads.
/// {@endtemplate}
@JsonSerializable(explicitToJson: true, includeIfNull: false)
@TimestampConverter()
class BlockedUserModel extends Equatable {
  /// {@macro blocked_user_model}
  const BlockedUserModel({
    required this.userId,
    required this.username,
    required this.imageUrl,
    this.blockedAt,
  });

  /// Converts a Firestore document snapshot to a BlockedUserModel.
  factory BlockedUserModel.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserModelFromJson(json);

  /// Converts the BlockedUserModel to a Map for Firestore storage.
  Map<String, dynamic> toJson() => _$BlockedUserModelToJson(this);

  /// The unique identifier of the blocked user.
  final String userId;

  /// The blocked user's username, denormalized at block time.
  final String username;

  /// The blocked user's profile image URL, denormalized at block time.
  final String imageUrl;

  /// When the block was created. Null until the server timestamp resolves.
  @TimestampConverter()
  final DateTime? blockedAt;

  @override
  List<Object?> get props => [userId, username, imageUrl, blockedAt];
}
