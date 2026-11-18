import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head_calculator.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';

part 'friend_stats_event.dart';
part 'friend_stats_state.dart';

/// Computes head-to-head stats between the signed-in user and one friend from
/// the user's own match history, over a selectable [StatsTimeRange].
///
/// Games are injected via [CompileFriendStats] (from the app-wide
/// match-history stream) and retained as fields so [FriendStatsRangeChanged]
/// can re-filter and recompute without re-fetching. Computation is
/// synchronous and cheap, so no generation fence is needed — events cannot
/// interleave across an await here.
class FriendStatsBloc extends Bloc<FriendStatsEvent, FriendStatsState> {
  FriendStatsBloc() : super(FriendStatsInitial()) {
    on<CompileFriendStats>(_onCompile);
    on<FriendStatsRangeChanged>(_onRangeChanged);
  }

  List<GameModel> _allGames = const [];
  String _myId = '';
  String _friendId = '';
  StatsTimeRange _range = StatsTimeRange.allTime;

  void _onCompile(CompileFriendStats event, Emitter<FriendStatsState> emit) {
    _allGames = event.games;
    _myId = event.myId;
    _friendId = event.friendId;
    _emitCompiled(emit);
  }

  void _onRangeChanged(
    FriendStatsRangeChanged event,
    Emitter<FriendStatsState> emit,
  ) {
    _range = event.range;
    _emitCompiled(emit);
  }

  void _emitCompiled(Emitter<FriendStatsState> emit) {
    emit(FriendStatsLoading());
    try {
      final games = _filterGames(_allGames, _range);
      final stats = FriendHeadToHeadCalculator.compute(
        games: games,
        myId: _myId,
        friendId: _friendId,
      );
      emit(FriendStatsLoaded(stats, range: _range));
    } on Object catch (error) {
      emit(FriendStatsFailure(error.toString()));
    }
  }

  /// Keeps games whose `endTime` is after the cutoff for [range]. Mirrors
  /// `StatsOverviewBloc._filterGames` so the two pages agree on boundaries.
  List<GameModel> _filterGames(List<GameModel> games, StatsTimeRange range) {
    if (range == StatsTimeRange.allTime) {
      return games;
    }
    final now = DateTime.now();
    final cutoff = switch (range) {
      StatsTimeRange.last12Months => DateTime(now.year - 1, now.month, now.day),
      StatsTimeRange.last6Months => DateTime(now.year, now.month - 6, now.day),
      StatsTimeRange.last3Months => DateTime(now.year, now.month - 3, now.day),
      StatsTimeRange.last30Days => now.subtract(const Duration(days: 30)),
      StatsTimeRange.allTime => now,
    };
    return games.where((game) => game.endTime.isAfter(cutoff)).toList();
  }
}
