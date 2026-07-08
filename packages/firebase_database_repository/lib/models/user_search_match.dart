import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/models/relationship_status.dart';
import 'package:firebase_database_repository/models/user_profile_model.dart';

/// {@template user_search_match}
/// A single match from the `searchByUsername` callable: a user profile
/// paired with the caller's relationship to them.
/// {@endtemplate}
class UserSearchMatch extends Equatable {
  /// {@macro user_search_match}
  const UserSearchMatch({
    required this.user,
    required this.relationship,
  });

  /// The matching user's profile.
  final UserProfileModel user;

  /// The relationship between the caller and [user].
  final RelationshipStatus relationship;

  @override
  List<Object?> get props => [user, relationship];
}
