import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'friend_request_event.dart';
part 'friend_request_state.dart';

/// Bloc implementation for managing friend requests.
///
/// Handles:
/// - Loading friend requests from Firestore.
/// - Accepting and declining friend requests.
///
/// @dependencies
/// - Firebase Firestore: For data storage and retrieval.
/// - Flutter Bloc: For state management.
class FriendRequestBloc extends Bloc<FriendRequestEvent, FriendRequestState> {
  FriendRequestBloc({required this.repository})
      : super(FriendRequestLoading()) {
    on<LoadFriendRequests>(_onLoadFriendRequests);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<DeclineFriendRequest>(_onDeclineFriendRequest);
  }
  final FirebaseDatabaseRepository repository;

  Future<void> _onLoadFriendRequests(
    LoadFriendRequests event,
    Emitter<FriendRequestState> emit,
  ) async {
    try {
      final requests = await repository.getFriendRequests(event.userId);
      emit(FriendRequestLoaded(requests));
    } catch (e) {
      emit(const FriendRequestError('Failed to load friend requests'));
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<FriendRequestState> emit,
  ) async {
    try {
      await repository.acceptFriendRequest(event.request, event.userId);
      // Remove accepted request from in-memory list
      if (state is FriendRequestLoaded) {
        final updated = (state as FriendRequestLoaded)
            .requests
            .where((r) => r.id != event.request.id)
            .toList();
        emit(FriendRequestLoaded(updated));
      }
    } on LegacyFriendRequestException {
      emit(const FriendRequestLegacyAcceptError());
    } catch (e) {
      emit(const FriendRequestError('Failed to accept friend request'));
    }
  }

  Future<void> _onDeclineFriendRequest(
    DeclineFriendRequest event,
    Emitter<FriendRequestState> emit,
  ) async {
    try {
      await repository.declineFriendRequest(event.request.id);
      // Remove declined request from in-memory list
      if (state is FriendRequestLoaded) {
        final updated = (state as FriendRequestLoaded)
            .requests
            .where((r) => r.id != event.request.id)
            .toList();
        emit(FriendRequestLoaded(updated));
      }
    } catch (e) {
      emit(const FriendRequestError('Failed to decline friend request'));
    }
  }
}
