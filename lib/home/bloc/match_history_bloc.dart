import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/models/player.dart';
import 'package:user_repository/user_repository.dart';

part 'match_history_event.dart';
part 'match_history_state.dart';

class MatchHistoryBloc extends Bloc<MatchHistoryEvent, MatchHistoryState> {
  MatchHistoryBloc({
    required FirebaseDatabaseRepository databaseRepository,
    required User user,
  })  : _databaseRepository = databaseRepository,
        _user = user,
        super(const MatchHistoryState()) {
    on<LoadMatchHistory>(_onLoadMatchHistory);
    on<ClearMatchHistory>(_onClearMatchHistory);
    on<CompileMatchHistoryData>(_onCompileMatchHistoryData);
  }

  final FirebaseDatabaseRepository _databaseRepository;
  final User _user;

  Future<void> _onLoadMatchHistory(
    LoadMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loadingHistory));

    await emit.forEach(
      _databaseRepository.getGames(event.userId),
      onData: (List<GameModel> games) {
        // Sort games by end time in descending order (most recent first)
        final sortedGames = List<GameModel>.from(games)
          ..sort((a, b) => b.endTime.compareTo(a.endTime));

        return state.copyWith(
          status: HomeStatus.loadingHistorySuccess,
          games: sortedGames,
        );
      },
      onError: (error, stackTrace) {
        return state.copyWith(
          status: HomeStatus.failure,
          error: error.toString(),
        );
      },
    );
  }

  /// Calculate the number of unique commanders used by the player
  int _calculateUniqueCommanders(List<GameModel> games) {
    final Set<String> uniqueCommanders = {};

    for (final game in games) {
      final player = _findPlayerInGame(game);
      final commanderKey =
          '${player.commander.cardType}${player.commander.name}';
      if (commanderKey.isNotEmpty) {
        uniqueCommanders.add(commanderKey);
      }
    }

    return uniqueCommanders.length;
  }

  /// Calculate the total number of wins for the player
  int _calculateTotalWins(List<GameModel> games) {
    var wins = 0;
    for (final game in games) {
      if (game.winner.firebaseId == _user.id) {
        wins++;
      }
    }
    return wins;
  }

  /// Calculate win percentage for the player
  int _calculateWinPercentage(List<GameModel> games, int totalWins) {
    if (games.isEmpty) return 0;
    return (totalWins * 100) ~/ games.length;
  }

  /// Find the player in a game, defaulting to first player if not found
  Player _findPlayerInGame(GameModel game) {
    return game.players.firstWhere(
      (player) => player.firebaseId == _user.id,
      orElse: () => game.players.first,
    );
  }

  /// Find the game with the shortest duration
  int _findShortestGameDuration(List<GameModel> games) {
    if (games.isEmpty) return 0;
    return games
        .reduce((current, next) =>
            current.durationInSeconds < next.durationInSeconds ? current : next)
        .durationInSeconds;
  }

  /// Find the game with the longest duration
  int _findLongestGameDuration(List<GameModel> games) {
    if (games.isEmpty) return 0;
    return games
        .reduce((current, next) =>
            current.durationInSeconds > next.durationInSeconds ? current : next)
        .durationInSeconds;
  }

  /// Calculate the average placement of the player
  double _calculateAveragePlacement(List<GameModel> games) {
    if (games.isEmpty) return 0;

    var totalPlacement = 0;
    for (final game in games) {
      final player = _findPlayerInGame(game);
      totalPlacement += player.placement;
    }

    // Round to 1 decimal place
    return double.parse((totalPlacement / games.length).toStringAsFixed(1));
  }

  /// Calculate how many times the player went first
  int _calculateTimesWentFirst(List<GameModel> games) {
    if (games.isEmpty) return 0;

    var timesFirst = 0;
    for (final game in games) {
      final player = _findPlayerInGame(game);
      if (player.id == game.startingPlayerId) {
        timesFirst++;
      }
    }
    return timesFirst;
  }

  Future<void> _onCompileMatchHistoryData(
    CompileMatchHistoryData event,
    Emitter<MatchHistoryState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loadingStats));

    final games = state.games;

    // Calculate statistics
    final uniqueCommanderCount = _calculateUniqueCommanders(games);
    final totalWins = _calculateTotalWins(games);
    final winPercentage = _calculateWinPercentage(games, totalWins);
    final shortestGameDuration = _findShortestGameDuration(games);
    final longestGameDuration = _findLongestGameDuration(games);
    final averagePlacement = _calculateAveragePlacement(games);
    final timesWentFirst = _calculateTimesWentFirst(games);

    emit(state.copyWith(
      status: HomeStatus.loadingStatsSuccess,
      uniqueCommanderCount: uniqueCommanderCount,
      totalWins: totalWins,
      winPercentage: winPercentage,
      shortestGameDuration: _formatDuration(shortestGameDuration),
      longestGameDuration: _formatDuration(longestGameDuration),
      averagePlacement: averagePlacement,
      timesWentFirst: timesWentFirst,
    ));
  }

  void _onClearMatchHistory(
    ClearMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) {
    emit(state.copyWith(
      status: HomeStatus.loadingHistorySuccess,
      games: const [],
    ));
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours; // Get hours
    final minutes = duration.inMinutes.remainder(60); // Get remaining minutes
    return '${hours}h ${minutes}m'; // Format the output
  }
}
