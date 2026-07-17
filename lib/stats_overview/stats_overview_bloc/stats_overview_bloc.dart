import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'stats_overview_event.dart';
part 'stats_overview_state.dart';

enum StatsTimeRange {
  allTime('All Time'),
  last12Months('Last 12 Months'),
  last6Months('Last 6 Months'),
  last3Months('Last 3 Months'),
  last30Days('Last 30 Days');

  const StatsTimeRange(this.label);
  final String label;
}

class StatsOverviewBloc extends Bloc<StatsOverviewEvent, StatsOverviewState> {
  StatsOverviewBloc({required ScryfallRepository scryfallRepository})
      : _scryfallRepository = scryfallRepository,
        super(StatsOverviewInitial()) {
    on<CompileStatsOverviewData>(_onCompileStatsOverviewData);
    on<StatsTimeRangeChanged>(_onTimeRangeChanged);
  }

  final ScryfallRepository _scryfallRepository;

  List<GameModel> _allGames = const [];
  String _userId = '';
  StatsTimeRange _range = StatsTimeRange.allTime;

  /// Monotonic counter identifying each [_emitCompiled] invocation.
  ///
  /// See [_emitCompiled] for why this exists.
  int _generation = 0;

  Future<void> _onCompileStatsOverviewData(
    CompileStatsOverviewData event,
    Emitter<StatsOverviewState> emit,
  ) async {
    _allGames = event.games;
    _userId = event.userId;
    await _emitCompiled(emit);
  }

  Future<void> _onTimeRangeChanged(
    StatsTimeRangeChanged event,
    Emitter<StatsOverviewState> emit,
  ) async {
    _range = event.range;
    await _emitCompiled(emit);
  }

  /// Filters [games] to [range].
  ///
  /// [range] is passed in rather than read from `_range` so this stays a pure
  /// function of its arguments — see [_emitCompiled] for why that matters.
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

  /// Filters [_allGames] to [_range], compiles all 18 stats over the
  /// result, and emits the outcome.
  ///
  /// Shared by both event handlers so the compilation logic — including
  /// oracle ID resolution — lives in exactly one place instead of being
  /// duplicated between them.
  ///
  /// Both handlers routing through here means invocations can overlap: the
  /// bloc package processes events concurrently by default, and `on<E>()`
  /// registers an *independent* subscription per event type. So a
  /// [CompileStatsOverviewData] (which arrives unprompted from live match
  /// history updates) can interleave with a [StatsTimeRangeChanged] across
  /// the `await` below. Per-registration transformers cannot fix that —
  /// they only serialise same-type events.
  ///
  /// Two separate guards make that safe. They solve different halves of the
  /// problem, so removing either reintroduces a bug:
  ///
  /// 1. **Consistency** — `range`/`userId`/`allGames` are captured into
  ///    locals *before* the await and are the only values read afterwards.
  ///    Re-reading the mutable fields after the await would pair one
  ///    invocation's `games` with a different invocation's `range`, e.g.
  ///    labelling a 12-month game set "Last 30 Days".
  /// 2. **Ordering** — [_generation] fences the emit, so an invocation that
  ///    resumes late cannot clobber a newer invocation's result with stale
  ///    data. Locals alone do not give this: a slow earlier invocation would
  ///    still emit last, overwriting a newer, correct result.
  Future<void> _emitCompiled(Emitter<StatsOverviewState> emit) async {
    final generation = ++_generation;
    final range = _range;
    final userId = _userId;
    final allGames = _allGames;

    emit(StatsOverviewLoading());
    try {
      final filteredGames = _filterGames(allGames, range);
      final games = await _resolveOracleIds(filteredGames, userId);
      // Calculate statistics
      final uniqueCommanderCount =
          _calculateUniqueCommanders(games, userId);
      final totalWins = _calculateTotalWins(games, userId);
      final winPercentage = _calculateWinPercentage(games, totalWins);
      final shortestGameDuration = _findShortestGameDuration(games);
      final longestGameDuration = _findLongestGameDuration(games);
      final averagePlacement = _calculateAveragePlacement(games, userId);
      final timesWentFirst = _calculateTimesWentFirst(games, userId);
      final mostPlayedCommander = _calculateMostPlayedCommander(games, userId);
      final averageGameDuration = _calculateAverageGameDuration(games);
      final winRateWhenFirst = _calculateWinRateWhenFirst(games, userId);
      final bestCommander = _calculateBestCommander(games, userId);
      final currentStreak = _calculateCurrentStreak(games, userId);
      final mostCommonOpponent =
          _calculateMostCommonOpponent(games, userId);
      final nemesis = _calculateNemesis(games, userId);
      final avgCommanderDamageTaken =
          _calculateAvgCommanderDamageTaken(games, userId);
      final timesKilledByCommander =
          _calculateTimesKilledByCommander(games, userId);
      final bestColorCombo = _calculateBestColorCombo(games, userId);
      final bestSingleColor = _calculateBestSingleColor(games, userId);

      // A newer invocation started while we were awaiting; its result is the
      // one the user is waiting on, so drop ours rather than clobber it.
      if (generation != _generation) return;

      emit(StatsOverviewLoaded(
        userId: userId,
        games: filteredGames,
        range: range,
        uniqueCommanderCount: uniqueCommanderCount,
        totalWins: totalWins,
        winPercentage: winPercentage,
        shortestGameDuration: _formatDuration(shortestGameDuration),
        longestGameDuration: _formatDuration(longestGameDuration),
        averagePlacement: averagePlacement,
        timesWentFirst: timesWentFirst,
        mostPlayedCommander: mostPlayedCommander,
        averageGameDuration: _formatDuration(averageGameDuration),
        winRateWhenFirst: winRateWhenFirst,
        bestCommander: bestCommander,
        currentStreak: currentStreak,
        mostCommonOpponent: mostCommonOpponent,
        nemesis: nemesis,
        avgCommanderDamageTaken: avgCommanderDamageTaken,
        timesKilledByCommander: timesKilledByCommander,
        bestColorCombo: bestColorCombo,
        bestSingleColor: bestSingleColor,
      ));
    } catch (e) {
      // Fenced for the same reason as the success path: a stale invocation's
      // failure must not replace a newer invocation's good result.
      if (generation != _generation) return;
      emit(StatsOverviewFailure(error: e.toString()));
    }
  }

  /// Resolves missing oracle IDs for commanders using the local bulk data.
  ///
  /// Caches lookups by name so each unique commander name is resolved once.
  Future<List<GameModel>> _resolveOracleIds(
    List<GameModel> games,
    String userId,
  ) async {
    final cache = <String, String?>{};

    Future<Commander> resolve(Commander commander) async {
      if (commander.oracleId != null) return commander;
      final name = commander.name;
      if (!cache.containsKey(name)) {
        cache[name] = await _scryfallRepository.getOracleIdByName(name);
      }
      final oracleId = cache[name];
      if (oracleId == null) return commander;
      return commander.copyWith(oracleId: oracleId);
    }

    final resolved = <GameModel>[];
    for (final game in games) {
      final players = <Player>[];
      for (final player in game.players) {
        var updatedPlayer = player;
        if (player.commander != null) {
          final resolvedCommander = await resolve(player.commander!);
          updatedPlayer = updatedPlayer.copyWith(commander: resolvedCommander);
        }
        if (player.partner != null) {
          final resolvedPartner = await resolve(player.partner!);
          updatedPlayer =
              updatedPlayer.copyWith(partner: () => resolvedPartner);
        }
        players.add(updatedPlayer);
      }
      resolved.add(game.copyWith(players: players));
    }
    return resolved;
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
      final commander = player.commander;
      if (commander == null) continue;
      final commanderKey = commander.oracleId ?? commander.name;
      if (commanderKey.isNotEmpty) {
        uniqueCommanders.add(commanderKey);
      }
    }

    return uniqueCommanders.length;
  }

  String _calculateMostPlayedCommander(List<GameModel> games, String userId) {
    if (games.isEmpty) return 'No games';

    final playCounts = <String, int>{};
    final keyToName = <String, String>{};
    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      final commander = player.commander;
      if (commander == null) continue;
      final key = commander.oracleId ?? commander.name;
      if (key.isEmpty || key == 'null') continue;
      playCounts[key] = (playCounts[key] ?? 0) + 1;
      keyToName[key] = commander.name;
    }
    if (playCounts.isEmpty) return 'No commanders';
    final mostPlayedKey = playCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return keyToName[mostPlayedKey] ?? mostPlayedKey;
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

  /// Calculate average game duration in seconds
  int _calculateAverageGameDuration(List<GameModel> games) {
    if (games.isEmpty) return 0;
    final total =
        games.fold<int>(0, (sum, game) => sum + game.durationInSeconds);
    return total ~/ games.length;
  }

  /// Calculate win rate when the player went first
  String _calculateWinRateWhenFirst(List<GameModel> games, String userId) {
    var timesFirst = 0;
    var winsWhenFirst = 0;
    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      if (player.id == game.startingPlayerId) {
        timesFirst++;
        final winner = game.players.firstWhere(
          (p) => p.id == game.winnerId,
        );
        if (winner.firebaseId == userId) {
          winsWhenFirst++;
        }
      }
    }
    if (timesFirst < 3) return 'Need 3+ games';
    final rate = (winsWhenFirst * 100) ~/ timesFirst;
    return '$rate%';
  }

  /// Calculate the commander with the highest win rate (min 3 games)
  String _calculateBestCommander(List<GameModel> games, String userId) {
    final commanderGames = <String, int>{};
    final commanderWins = <String, int>{};
    final keyToName = <String, String>{};

    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      final commander = player.commander;
      if (commander == null) continue;
      final key = commander.oracleId ?? commander.name;
      if (key.isEmpty) continue;
      keyToName[key] = commander.name;
      commanderGames[key] = (commanderGames[key] ?? 0) + 1;
      final winner = game.players.firstWhere(
        (p) => p.id == game.winnerId,
      );
      if (winner.firebaseId == userId) {
        commanderWins[key] = (commanderWins[key] ?? 0) + 1;
      }
    }

    String? bestKey;
    var bestRate = -1.0;
    for (final entry in commanderGames.entries) {
      if (entry.value < 3) continue;
      final wins = commanderWins[entry.key] ?? 0;
      final rate = wins / entry.value;
      if (rate > bestRate) {
        bestRate = rate;
        bestKey = entry.key;
      }
    }
    if (bestKey == null) return 'Need 3+ games';
    final winPct = (bestRate * 100).round();
    return '${keyToName[bestKey]} ($winPct%)';
  }

  /// Calculate the current win or loss streak sorted by game end time
  String _calculateCurrentStreak(List<GameModel> games, String userId) {
    if (games.isEmpty) return '0';
    final sorted = List<GameModel>.from(games)
      ..sort((a, b) => b.endTime.compareTo(a.endTime));

    final firstGame = sorted.first;
    final firstWinner = firstGame.players.firstWhere(
      (p) => p.id == firstGame.winnerId,
    );
    final isWinStreak = firstWinner.firebaseId == userId;
    var streak = 0;

    for (final game in sorted) {
      final winner = game.players.firstWhere(
        (p) => p.id == game.winnerId,
      );
      final won = winner.firebaseId == userId;
      if (won == isWinStreak) {
        streak++;
      } else {
        break;
      }
    }

    return isWinStreak ? '$streak W' : '$streak L';
  }

  /// Calculate the most common opponent by name (case-insensitive)
  String _calculateMostCommonOpponent(List<GameModel> games, String userId) {
    if (games.isEmpty) return 'N/A';
    final opponentCounts = <String, int>{};
    final originalNames = <String, String>{};

    for (final game in games) {
      for (final player in game.players) {
        if (player.firebaseId == userId) continue;
        final lowerName = player.name.toLowerCase();
        opponentCounts[lowerName] = (opponentCounts[lowerName] ?? 0) + 1;
        originalNames[lowerName] = player.name;
      }
    }
    opponentCounts.removeWhere((_, count) => count < 3);
    if (opponentCounts.isEmpty) return 'Need 3+ games';
    final topKey = opponentCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return '${originalNames[topKey]} (${opponentCounts[topKey]})';
  }

  /// Calculate the nemesis — opponent who beats you the most (case-insensitive)
  String _calculateNemesis(List<GameModel> games, String userId) {
    if (games.isEmpty) return 'N/A';
    final beatYouCounts = <String, int>{};
    final originalNames = <String, String>{};

    for (final game in games) {
      final winner = game.players.firstWhere(
        (p) => p.id == game.winnerId,
      );
      if (winner.firebaseId == userId) continue;
      final lowerName = winner.name.toLowerCase();
      beatYouCounts[lowerName] = (beatYouCounts[lowerName] ?? 0) + 1;
      originalNames[lowerName] = winner.name;
    }
    beatYouCounts.removeWhere((_, count) => count < 3);
    if (beatYouCounts.isEmpty) return 'Need 3+ games';
    final topKey = beatYouCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return '${originalNames[topKey]} (${beatYouCounts[topKey]})';
  }

  /// Calculate average commander damage taken per game
  String _calculateAvgCommanderDamageTaken(
    List<GameModel> games,
    String userId,
  ) {
    if (games.isEmpty) return '0';
    var totalDamage = 0;
    var gamesWithData = 0;

    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      if (player.opponents == null) continue;
      var gameDamage = 0;
      for (final opponent in player.opponents!) {
        for (final damage in opponent.damages) {
          gameDamage += damage.amount;
        }
      }
      totalDamage += gameDamage;
      gamesWithData++;
    }
    if (gamesWithData == 0) return '0';
    final avg = (totalDamage / gamesWithData).round();
    return avg.toString();
  }

  /// Calculate times killed by 21+ commander damage from a single opponent
  int _calculateTimesKilledByCommander(
    List<GameModel> games,
    String userId,
  ) {
    var count = 0;
    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      if (player.opponents == null) continue;
      for (final opponent in player.opponents!) {
        final totalFromOpponent =
            opponent.damages.fold<int>(0, (sum, d) => sum + d.amount);
        if (totalFromOpponent >= 21) {
          count++;
          break;
        }
      }
    }
    return count;
  }

  /// Calculate win rate by exact color identity combination
  String _calculateBestColorCombo(List<GameModel> games, String userId) {
    if (games.isEmpty) return 'N/A';
    final comboGames = <String, int>{};
    final comboWins = <String, int>{};

    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      final commander = player.commander;
      if (commander == null) continue;
      final identity =
          commander.colorIdentity ?? commander.colors;
      final colors = List<String>.from(identity)..sort();
      final combo = colors.isEmpty ? 'Colorless' : colors.join();
      comboGames[combo] = (comboGames[combo] ?? 0) + 1;
      final winner = game.players.firstWhere(
        (p) => p.id == game.winnerId,
      );
      if (winner.firebaseId == userId) {
        comboWins[combo] = (comboWins[combo] ?? 0) + 1;
      }
    }

    String? bestCombo;
    var bestRate = -1.0;
    for (final entry in comboGames.entries) {
      if (entry.value < 3) continue;
      final wins = comboWins[entry.key] ?? 0;
      final rate = wins / entry.value;
      final tiebreak =
          entry.value > (comboGames[bestCombo] ?? 0);
      if (rate > bestRate || (rate == bestRate && tiebreak)) {
        bestRate = rate;
        bestCombo = entry.key;
      }
    }
    if (bestCombo == null) return 'Need 3+ games';
    final winPct = (bestRate * 100).round();
    return '$bestCombo ($winPct%)';
  }

  /// Calculate win rate by individual color (contains this color)
  String _calculateBestSingleColor(List<GameModel> games, String userId) {
    if (games.isEmpty) return 'N/A';
    final colorGames = <String, int>{};
    final colorWins = <String, int>{};

    for (final game in games) {
      final player = _findPlayerInGame(game, userId);
      final commander = player.commander;
      if (commander == null) continue;
      final colors = commander.colorIdentity ?? commander.colors;
      final isWin = game.players
              .firstWhere((p) => p.id == game.winnerId)
              .firebaseId ==
          userId;
      if (colors.isEmpty) {
        colorGames['Colorless'] =
            (colorGames['Colorless'] ?? 0) + 1;
        if (isWin) {
          colorWins['Colorless'] =
              (colorWins['Colorless'] ?? 0) + 1;
        }
      } else {
        for (final color in colors) {
          colorGames[color] =
              (colorGames[color] ?? 0) + 1;
          if (isWin) {
            colorWins[color] =
                (colorWins[color] ?? 0) + 1;
          }
        }
      }
    }

    String? bestColor;
    var bestRate = -1.0;
    for (final entry in colorGames.entries) {
      if (entry.value < 3) continue;
      final wins = colorWins[entry.key] ?? 0;
      final rate = wins / entry.value;
      final tiebreak =
          entry.value > (colorGames[bestColor] ?? 0);
      if (rate > bestRate || (rate == bestRate && tiebreak)) {
        bestRate = rate;
        bestColor = entry.key;
      }
    }
    if (bestColor == null) return 'Need 3+ games';
    final winPct = (bestRate * 100).round();
    final colorName = _colorToName(bestColor);
    return '$colorName ($winPct%)';
  }

  String _colorToName(String color) {
    return switch (color) {
      'W' => 'White',
      'U' => 'Blue',
      'B' => 'Black',
      'R' => 'Red',
      'G' => 'Green',
      _ => color,
    };
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
