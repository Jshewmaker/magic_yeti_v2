// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:equatable/equatable.dart';

/// {@template user}
/// User model
///
/// [User.unauthenticated] represents an unauthenticated user.
/// {@endtemplate}
class User extends Equatable {
  /// {@macro user}
  const User({
    required this.id,
    this.email,
    this.name,
    this.photo,
    this.isNewUser = false,
  });

  /// The current user's email address.
  final String? email;

  /// The current user's id.
  final String id;

  /// The current user's name (display name).
  final String? name;

  /// Url for the current user's photo.
  final String? photo;

  /// Whether the current user is a first time user.
  final bool isNewUser;

  /// An unauthenticated user.
  static const unauthenticated = User(id: '');

  @override
  List<Object?> get props => [email, id, name, photo, isNewUser];
}
