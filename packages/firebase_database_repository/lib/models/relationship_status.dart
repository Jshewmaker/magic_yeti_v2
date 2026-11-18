/// The relationship between two users.
enum RelationshipStatus {
  /// No relationship exists.
  none,

  /// Users are friends.
  friends,

  /// Current user sent a pending request to the other user.
  pendingSent,

  /// Other user sent a pending request to the current user.
  pendingReceived,

  /// Same user (self).
  self,
}
