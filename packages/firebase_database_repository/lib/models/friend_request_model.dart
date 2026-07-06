import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/helpers/timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';
// ignore: directives_ordering
import 'package:cloud_firestore/cloud_firestore.dart';

part 'friend_request_model.g.dart';

/// {@template FriendRequestModel}
/// This model represents a friend request in the application, encapsulating
/// all necessary fields and providing methods for serialization and deserialization.
///
/// Key features:
/// - Type-safe representation of friend request data
/// - Methods for converting to and from Firestore documents
///
/// @dependencies
/// - None
///
/// @notes
/// - Ensure that all fields are properly validated before using this model
/// {@endtemplate}
@JsonSerializable(explicitToJson: true, includeIfNull: false)
@TimestampConverter()
class FriendRequestModel extends Equatable {
  /// Constructor for FriendRequestModel.
  ///
  /// @param requestId The unique identifier for the friend request.
  /// @param senderId The ID of the user sending the request.
  /// @param receiverId The ID of the user receiving the request.
  /// @param status The current status of the friend request (e.g., 'pending', 'accepted').
  /// @param timestamp The time when the request was created.
  const FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.status,
    required this.timestamp,
    this.senderFriendCode,
  });

  /// Converts a Firestore document snapshot to a FriendRequestModel.
  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestModelFromJson(json);

  /// Converts the FriendRequestModel to a Map for Firestore storage.
  Map<String, dynamic> toJson() => _$FriendRequestModelToJson(this);

  /// The unique identifier for the friend request.
  final String id;

  /// The ID of the user sending the request.
  final String senderId;

  /// The ID of the user receiving the request.
  final String receiverId;

  /// The name of the user sending the request.
  final String senderName;

  /// The sender's unique friend code, denormalized at request-creation
  /// time — since [senderName] has no uniqueness guarantee, this is the
  /// only reliable way to tell two same-named senders apart. Null for
  /// requests created before this field existed.
  final String? senderFriendCode;

  /// The current status of the friend request (e.g., 'pending', 'accepted').
  final String status;

  /// The time when the request was created.
  @TimestampConverter()
  final DateTime timestamp;

  /// Creates a copy of this FriendRequestModel with the given fields replaced with the
  /// new values.
  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? senderName,
    String? senderFriendCode,
    String? status,
    DateTime? timestamp,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      senderFriendCode: senderFriendCode ?? this.senderFriendCode,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        senderName,
        senderFriendCode,
        status,
        timestamp,
      ];
}
