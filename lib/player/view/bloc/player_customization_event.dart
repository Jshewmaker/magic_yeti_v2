part of 'player_customization_bloc.dart';

sealed class PlayerCustomizationEvent extends Equatable {
  const PlayerCustomizationEvent();

  @override
  List<Object?> get props => [];
}

/// Loads device recents + favorites into state.
final class LibraryRequested extends PlayerCustomizationEvent {
  const LibraryRequested();
}

final class CardListRequested extends PlayerCustomizationEvent {
  const CardListRequested({
    required this.cardName,
    this.searchBackgrounds = false,
  });

  final String cardName;
  final bool searchBackgrounds;

  @override
  List<Object> get props => [cardName, searchBackgrounds];
}

/// User picked a primary commander.
final class CommanderSelected extends PlayerCustomizationEvent {
  const CommanderSelected(this.commander);

  final Commander commander;

  @override
  List<Object?> get props => [commander];
}

/// User picked the second card (partner or background, per availablePairing).
final class SecondCardSelected extends PlayerCustomizationEvent {
  const SecondCardSelected(this.card);

  final Commander card;

  @override
  List<Object?> get props => [card];
}

final class StartSelectingSecondCard extends PlayerCustomizationEvent {
  const StartSelectingSecondCard();
}

final class CancelSelectingSecondCard extends PlayerCustomizationEvent {
  const CancelSelectingSecondCard();
}

final class SecondCardCleared extends PlayerCustomizationEvent {
  const SecondCardCleared();
}

final class CommanderFavoriteToggled extends PlayerCustomizationEvent {
  const CommanderFavoriteToggled(this.commander);

  final Commander commander;

  @override
  List<Object?> get props => [commander];
}

final class ClearCardList extends PlayerCustomizationEvent {
  const ClearCardList();
}

final class UpdateCommanderFilters extends PlayerCustomizationEvent {
  const UpdateCommanderFilters({required this.showOnlyLegendary});

  final bool showOnlyLegendary;

  @override
  List<Object> get props => [showOnlyLegendary];
}

final class SelectFriend extends PlayerCustomizationEvent {
  const SelectFriend({required this.friend});

  final FriendModel friend;

  @override
  List<Object> get props => [friend];
}

final class OwnerSelected extends PlayerCustomizationEvent {
  const OwnerSelected({required this.userId});

  final String userId;

  @override
  List<Object> get props => [userId];
}

final class LinkCleared extends PlayerCustomizationEvent {
  const LinkCleared();
}

final class ValidatePin extends PlayerCustomizationEvent {
  const ValidatePin({required this.pin, required this.friendUserId});

  final String pin;
  final String friendUserId;

  @override
  List<Object> get props => [pin, friendUserId];
}

/// Clears stale PIN-flow error/lockout state before a dialog opens, so a
/// lockout or error from a previous friend's attempt doesn't leak into the
/// next dialog. Does not touch [PlayerCustomizationState.pinValidated] or
/// [PlayerCustomizationState.selectedFriend] — an already-linked friend
/// selection must survive opening and cancelling a second dialog.
final class ResetPinFlow extends PlayerCustomizationEvent {
  const ResetPinFlow();
}
