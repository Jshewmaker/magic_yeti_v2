import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/models/relationship_status.dart';
import 'package:firebase_database_repository/models/user_profile_model.dart';

/// {@template friend_search_result}
/// Result of the `searchByFriendCode` callable.
///
/// `found: false` is returned ONLY for a genuine server not-found result,
/// which includes block-hiding (indistinguishable from a true miss by
/// design — see the callable). Any other callable error is thrown instead
/// of being folded into a `found: false` result, so offline/server errors
/// surface distinctly from "no such code".
/// {@endtemplate}
class FriendSearchResult extends Equatable {
  /// {@macro friend_search_result}
  const FriendSearchResult({
    required this.found,
    this.user,
    this.relationship,
  });

  /// Whether a matching user was found (and not hidden by a block).
  final bool found;

  /// The matching user's profile, present only when [found] is true.
  final UserProfileModel? user;

  /// The relationship between the caller and [user], present only when
  /// [found] is true.
  final RelationshipStatus? relationship;

  @override
  List<Object?> get props => [found, user, relationship];
}
