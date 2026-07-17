import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';

part 'friend_request_event.dart';
part 'friend_request_state.dart';

/// Bloc implementation for managing friend requests.
///
/// Handles:
/// - Streaming the user's incoming pending friend requests from Firestore.
/// - Accepting and declining friend requests.
///
/// Provided at the app root (see `lib/app/view/app.dart`) so the home
/// indicator and the friends page share one source of truth and open one
/// listener between them.
///
/// @dependencies
/// - FirebaseDatabaseRepository: For interacting with Firestore
/// - Flutter Bloc: For state management
class FriendRequestBloc extends Bloc<FriendRequestEvent, FriendRequestState> {
  FriendRequestBloc({required this.repository})
      : super(FriendRequestLoading()) {
    // restartable: a new LoadFriendRequests cancels the previous Firestore
    // subscription instead of queueing behind it (the handler never
    // completes on its own because the requests stream never closes).
    on<LoadFriendRequests>(_onLoadFriendRequests, transformer: restartable());
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<DeclineFriendRequest>(_onDeclineFriendRequest);
  }
  final FirebaseDatabaseRepository repository;

  Future<void> _onLoadFriendRequests(
    LoadFriendRequests event,
    Emitter<FriendRequestState> emit,
  ) async {
    // An empty userId means "no signed-in user": clear any previous requests
    // and stop listening. Anonymous users have no friend graph, and a
    // listener opened against a non-uid would take a permission error.
    if (event.userId.isEmpty) {
      emit(const FriendRequestLoaded([]));
      return;
    }

    emit(FriendRequestLoading());
    await emit.forEach<List<FriendRequestModel>>(
      repository.watchFriendRequests(event.userId),
      onData: FriendRequestLoaded.new,
      onError: (_, __) =>
          const FriendRequestError('Failed to load friend requests'),
    );
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<FriendRequestState> emit,
  ) async {
    // Captured before the attempt so a legacy-accept failure can restore
    // the list the page was showing — the builder renders the error state
    // as an empty "No pending requests" placeholder, so without recovery
    // the whole list would appear to vanish over one bad request.
    final priorState = state;
    try {
      await repository.acceptFriendRequest(event.request, event.userId);
      // Deliberately no emit on success. acceptFriendRequest ends in a batch
      // delete of the request doc, so the watchFriendRequests query re-emits
      // without it — and Firestore's latency compensation fires the local
      // listener before the server acks, so it is immediate. Maintaining an
      // in-memory copy here is what let the tab badge go stale.
    } on LegacyFriendRequestException {
      emit(const FriendRequestLegacyAcceptError());
      if (priorState is FriendRequestLoaded) {
        emit(priorState);
      }
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
      // No emit, same reasoning as accept: declining flips status to
      // 'declined', which drops the doc out of the pending query.
    } catch (e) {
      emit(const FriendRequestError('Failed to decline friend request'));
    }
  }
}
