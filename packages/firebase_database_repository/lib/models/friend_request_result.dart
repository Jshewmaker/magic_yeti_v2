/// Result of attempting to send a friend request.
enum FriendRequestResult {
  /// Request was sent successfully.
  sent,

  /// Both users had pending requests — auto-accepted as friends.
  autoAccepted,

  /// Users are already friends.
  alreadyFriends,

  /// A pending request already exists.
  alreadyPending,

  /// Cannot send a friend request to yourself.
  self,
}
