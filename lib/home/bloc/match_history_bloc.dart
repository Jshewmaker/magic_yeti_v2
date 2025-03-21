import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/models/player.dart';

part 'match_history_event.dart';
part 'match_history_state.dart';

class MatchHistoryBloc extends Bloc<MatchHistoryEvent, MatchHistoryState> {
  MatchHistoryBloc({
    required FirebaseDatabaseRepository databaseRepository,
  })  : _databaseRepository = databaseRepository,
        super(const MatchHistoryState()) {
    on<LoadMatchHistory>(_onLoadMatchHistory);
    on<ClearMatchHistory>(_onClearMatchHistory);
    on<CompileMatchHistoryData>(_onCompileMatchHistoryData);
    on<AddMatchToPlayerHistoryEvent>(_addMatchToPlayerHistory);
    on<UpdatePlayerOwnership>(_onUpdatePlayerOwnership);
  }

  final FirebaseDatabaseRepository _databaseRepository;

  Future<void> _onLoadMatchHistory(
    LoadMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: MatchHistoryStatus.loadingHistory,
        userId: event.userId,
      ),
    );
    if (event.userId.isEmpty) return;
    await emit.forEach(
      _databaseRepository.getGames(event.userId),
      onData: (List<GameModel> games) {
        // Sort games by end time in descending order (most recent first)
        final sortedGames = List<GameModel>.from(games)
          ..sort((a, b) => b.endTime.compareTo(a.endTime));

        return state.copyWith(
          status: MatchHistoryStatus.loadingHistorySuccess,
          games: sortedGames,
        );
      },
      onError: (error, stackTrace) {
        return state.copyWith(
          status: MatchHistoryStatus.failure,
          error: error.toString(),
        );
      },
    );
  }

  Future<void> _addMatchToPlayerHistory(
    AddMatchToPlayerHistoryEvent event,
    Emitter<MatchHistoryState> emit,
  ) async {
    try {
      final game = await _databaseRepository.getGame(event.roomId);
      await _databaseRepository.addMatchToPlayerHistory(game, event.playerId);
      emit(
        state.copyWith(
          status: MatchHistoryStatus.loadingHistorySuccess,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: MatchHistoryStatus.gameNotFound,
          error: error.toString(),
        ),
      );
    }
  }

  /// Calculate the number of unique commanders used by the player
  int _calculateUniqueCommanders(List<GameModel> games) {
    final uniqueCommanders = <String>{};

    for (final game in games) {
      final player = _findPlayerInGame(game);
      final commanderKey =
          '${player.commander?.cardType}${player.commander?.name}';
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
      final winningPlayer = game.players.firstWhere(
        (player) => player.id == game.winnerId,
      );
      if (winningPlayer.firebaseId == state.userId) {
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
      (player) => player.firebaseId == state.userId,
      orElse: () => game.players.first,
    );
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

  String _calculateMostPlayedCommander(
    List<GameModel> games,
    int uniqueCommanderCount,
  ) {
    if (games.isEmpty) return '';

    final commanders = <String>[];
    for (final game in games) {
      final player = _findPlayerInGame(game);
      commanders.add(player.commander?.name ?? '');
    }

    final mostPlayedCommander = commanders.reduce((current, next) {
      return commanders.where((element) => element == current).length >
              commanders.where((element) => element == next).length
          ? current
          : next;
    });

    return mostPlayedCommander;
  }

  Future<void> _onCompileMatchHistoryData(
    CompileMatchHistoryData event,
    Emitter<MatchHistoryState> emit,
  ) async {
    emit(state.copyWith(status: MatchHistoryStatus.loadingStats));

    try {
      final games = state.games;

      // Calculate statistics
      final uniqueCommanderCount = _calculateUniqueCommanders(games);
      final totalWins = _calculateTotalWins(games);
      final winPercentage = _calculateWinPercentage(games, totalWins);
      final shortestGameDuration = _findShortestGameDuration(games);
      final longestGameDuration = _findLongestGameDuration(games);
      final averagePlacement = _calculateAveragePlacement(games);
      final timesWentFirst = _calculateTimesWentFirst(games);
      final avgEdhRecRank =
          _calculateMostPlayedCommander(games, uniqueCommanderCount);

      emit(
        state.copyWith(
          status: MatchHistoryStatus.loadingStatsSuccess,
          uniqueCommanderCount: uniqueCommanderCount,
          totalWins: totalWins,
          winPercentage: winPercentage,
          shortestGameDuration: _formatDuration(shortestGameDuration),
          longestGameDuration: _formatDuration(longestGameDuration),
          averagePlacement: averagePlacement,
          timesWentFirst: timesWentFirst,
          mostPlayedCommander: avgEdhRecRank,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: MatchHistoryStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void _onClearMatchHistory(
    ClearMatchHistory event,
    Emitter<MatchHistoryState> emit,
  ) {
    emit(
      state.copyWith(
        status: MatchHistoryStatus.loadingHistorySuccess,
        games: const [],
      ),
    );
  }

  Future<void> _onUpdatePlayerOwnership(
    UpdatePlayerOwnership event,
    Emitter<MatchHistoryState> emit,
  ) async {
    try {
      // Update the players list, removing the Firebase ID from any player that had it
      // and assigning it to the selected player
      final updatedPlayers = event.game.players.map((p) {
        if (p.id == event.player.id) {
          // Assign the Firebase ID to the selected player
          return p.copyWith(firebaseId: () => event.currentUserFirebaseId);
        } else if (p.firebaseId == event.currentUserFirebaseId) {
          // Remove the Firebase ID from any other player that had it
          return p.copyWith(firebaseId: () => null);
        }
        return p;
      }).toList();

      // Update the game model with the new player list
      final updatedGame = event.game.copyWith(players: updatedPlayers);

      // Save the updated game to Firebase
      await _databaseRepository.updateGameStats(
        game: updatedGame,
        playerId: event.currentUserFirebaseId,
      );

      // Update the games list in state
      // final updatedGames = state.games.map((game) {
      //   if (game.id == event.game.id) {
      //     return updatedGame;
      //   }
      //   return game;
      // }).toList();

      emit(
        state.copyWith(
          //games: updatedGames,
          status: MatchHistoryStatus.loadingHistorySuccess,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: MatchHistoryStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours; // Get hours
    final minutes = duration.inMinutes.remainder(60); // Get remaining minutes
    return '${hours}h ${minutes}m'; // Format the output
  }
}
