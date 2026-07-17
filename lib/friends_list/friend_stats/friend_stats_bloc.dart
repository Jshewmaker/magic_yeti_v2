import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head_calculator.dart';

part 'friend_stats_event.dart';
part 'friend_stats_state.dart';

/// Computes head-to-head stats between the signed-in user and one friend from
/// the user's own match history.
///
/// Games are injected via [CompileFriendStats] rather than fetched here — the
/// friend page feeds them in from the app-wide match-history stream, mirroring
/// how the stats overview is driven. Computation is synchronous and cheap, so
/// no generation fence is needed.
class FriendStatsBloc extends Bloc<FriendStatsEvent, FriendStatsState> {
  FriendStatsBloc() : super(FriendStatsInitial()) {
    on<CompileFriendStats>(_onCompile);
  }

  void _onCompile(CompileFriendStats event, Emitter<FriendStatsState> emit) {
    emit(FriendStatsLoading());
    try {
      final stats = FriendHeadToHeadCalculator.compute(
        games: event.games,
        myId: event.myId,
        friendId: event.friendId,
      );
      emit(FriendStatsLoaded(stats));
    } on Object catch (error) {
      emit(FriendStatsFailure(error.toString()));
    }
  }
}
