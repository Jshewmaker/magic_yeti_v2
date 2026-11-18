import 'package:player_repository/player_repository.dart';

/// Stores commanders picked and favorited on this device, so the player
/// customization picker can offer reuse before any search.
///
/// Device-scoped and shared across everyone who uses this device. When the
/// future friends/auto-sync feature lands, a Firebase-backed implementation can
/// replace or augment this one behind the same interface.
abstract interface class CommanderLibraryRepository {
  /// Most-recently-picked commanders first (max 20).
  Future<List<Commander>> getRecents();

  /// Records [commander] as the most recent pick (dedup + cap applied).
  Future<void> addRecent(Commander commander);

  /// Favorited commanders, most-recently-favorited first.
  Future<List<Commander>> getFavorites();

  /// Adds or removes [commander] from favorites. Returns the resulting
  /// favorite state (`true` if now a favorite).
  Future<bool> toggleFavorite(Commander commander);

  /// Whether [commander] is currently a favorite.
  Future<bool> isFavorite(Commander commander);
}
