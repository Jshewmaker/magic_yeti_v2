import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

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
@JsonSerializable(explicitToJson: true)
class FriendRequestModel extends Equatable {
  /// Constructor for FriendRequestModel.
  ///
  /// @param requestId The unique identifier for the friend request.
  /// @param senderId The ID of the user sending the request.
  /// @param receiverId The ID of the user receiving the request.
  /// @param status The current status of the friend request (e.g., 'pending', 'accepted').
  /// @param timestamp The time when the request was created.
  const FriendRequestModel({
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.status,
    required this.timestamp,
  });

  /// Converts a Firestore document snapshot to a FriendRequestModel.
  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestModelFromJson(json);

  /// Converts the FriendRequestModel to a Map for Firestore storage.
  Map<String, dynamic> toJson() => _$FriendRequestModelToJson(this);

  /// The unique identifier for the friend request.
  final String requestId;

  /// The ID of the user sending the request.
  final String senderId;

  /// The ID of the user receiving the request.
  final String receiverId;

  /// The name of the user sending the request.
  final String senderName;

  /// The current status of the friend request (e.g., 'pending', 'accepted').
  final String status;

  /// The time when the request was created.
  final DateTime timestamp;

  /// Creates a copy of this FriendRequestModel with the given fields replaced with the
  /// new values.
  FriendRequestModel copyWith({
    String? requestId,
    String? senderId,
    String? receiverId,
    String? senderName,
    String? status,
    DateTime? timestamp,
  }) {
    return FriendRequestModel(
      requestId: requestId ?? this.requestId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        requestId,
        senderId,
        receiverId,
        senderName,
        status,
        timestamp,
      ];
}
