import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/player_repository.dart';

part 'stats_overview_event.dart';
part 'stats_overview_state.dart';

class StatsOverviewBloc extends Bloc<StatsOverviewEvent, StatsOverviewState> {
  StatsOverviewBloc() : super(StatsOverviewInitial()) {
    on<CompileStatsOverviewData>(_onCompileStatsOverviewData);
  }

  Future<void> _onCompileStatsOverviewData(
    CompileStatsOverviewData event,
    Emitter<StatsOverviewState> emit,
  ) async {
    emit(StatsOverviewLoading());
    try {
      final games = event.games;
      // Calculate statistics
      final uniqueCommanderCount =
          _calculateUniqueCommanders(games, event.userId);
      final totalWins = _calculateTotalWins(games, event.userId);
      final winPercentage = _calculateWinPercentage(games, totalWins);
      final shortestGameDuration = _findShortestGameDuration(games);
      final longestGameDuration = _findLongestGameDuration(games);
      final averagePlacement = _calculateAveragePlacement(games, event.userId);
      final timesWentFirst = _calculateTimesWentFirst(games, event.userId);
      final mostPlayedCommander = _calculateMostPlayedCommander(
          games, uniqueCommanderCount, event.userId);

      emit(StatsOverviewLoaded(
        userId: event.userId,
        games: event.games,
        uniqueCommanderCount: uniqueCommanderCount,
        totalWins: totalWins,
        winPercentage: winPercentage,
        shortestGameDuration: _formatDuration(shortestGameDuration),
        longestGameDuration: _formatDuration(longestGameDuration),
        averagePlacement: averagePlacement,
        timesWentFirst: timesWentFirst,
        mostPlayedCommander: mostPlayedCommander,
      ));
    } catch (e) {
      emit(StatsOverviewFailure(error: e.toString()));
    }
  }

  /// Find the player in a game, defaulting to first player if not found
  Player _findPlayerInGame(GameModel game, String userId) {
    return game.players.firstWhere(
      (player) => player.firebaseId == userId,
      orElse: () => game.players.first,
    );
  }

  /// Calculate the total number of wins for the player
  int _calculateTotalWins(List<GameModel> games, String userId) {
    var wins = 0;
    for (final game in games) {
      final winningPlayer = game.players.firstWhere(
        (player) => player.id == game.winnerId,
      );
      if (winningPlayer.firebaseId == userId) {
        wins++;
      }
    }
    return wins;
  }

  /// Calculate the number of unique commanders used by the player
  int _calculateUniqueCommanders(List<GameModel> games, String userId) {
    final uniqueCommanders = <String>{};

    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      final commanderKey =
          '${player.commander?.cardType}${player.commander?.name}';
      if (commanderKey.isNotEmpty) {
        uniqueCommanders.add(commanderKey);
      }
    }

    return uniqueCommanders.length;
  }

  String _calculateMostPlayedCommander(
    List<GameModel> games,
    int uniqueCommanderCount,
    String userId,
  ) {
    if (games.isEmpty) return 'No games';

    final commanders = <String>[];
    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      if (player.commander == null) return 'No commanders';
      commanders.add(player.commander?.name ?? '');
    }
    commanders
        .removeWhere((commander) => commander.isEmpty || commander == 'null');
    final mostPlayedCommander = commanders.reduce((current, next) {
      if (commanders.isEmpty) return 'No commanders';
      return commanders.where((element) => element == current).length >
              commanders.where((element) => element == next).length
          ? current
          : next;
    });

    return mostPlayedCommander;
  }

  /// Calculate how many times the player went first
  int _calculateTimesWentFirst(List<GameModel> games, String userId) {
    if (games.isEmpty) return 0;

    var timesFirst = 0;
    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      if (player.id == game.startingPlayerId) {
        timesFirst++;
      }
    }
    return timesFirst;
  }

  /// Calculate the average placement of the player
  double _calculateAveragePlacement(List<GameModel> games, String userId) {
    if (games.isEmpty) return 0;

    var totalPlacement = 0;
    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      totalPlacement += player.placement;
    }

    // Round to 1 decimal place
    return double.parse((totalPlacement / games.length).toStringAsFixed(1));
  }

  /// Find the game with the longest duration
  int _findLongestGameDuration(List<GameModel> games) {
    if (games.isEmpty) return 0;
    return games
        .reduce(
          (current, next) => current.durationInSeconds > next.durationInSeconds
              ? current
              : next,
        )
        .durationInSeconds;
  }

  /// Find the game with the shortest duration
  int _findShortestGameDuration(List<GameModel> games) {
    if (games.isEmpty) return 0;
    return games
        .reduce(
          (current, next) => current.durationInSeconds < next.durationInSeconds
              ? current
              : next,
        )
        .durationInSeconds;
  }

  /// Calculate win percentage for the player
  int _calculateWinPercentage(List<GameModel> games, int totalWins) {
    if (games.isEmpty) return 0;
    return (totalWins * 100) ~/ games.length;
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours; // Get hours
    final minutes = duration.inMinutes.remainder(60); // Get remaining minutes
    return '${hours}h ${minutes}m'; // Format the output
  }
}
