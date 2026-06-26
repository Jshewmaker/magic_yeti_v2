import 'dart:convert';

import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local [CommanderLibraryRepository] backed by [SharedPreferences].
class SharedPreferencesCommanderLibraryRepository
    implements CommanderLibraryRepository {
  SharedPreferencesCommanderLibraryRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _recentsKey = 'cmdr_lib_recents';
  static const _favoritesKey = 'cmdr_lib_favorites';
  static const _maxRecents = 20;

  String _identity(Commander c) => c.oracleId ?? c.name;

  List<Commander> _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Commander.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> _write(String key, List<Commander> commanders) async {
    final encoded =
        jsonEncode(commanders.map((c) => c.toJson()).toList());
    await _prefs.setString(key, encoded);
  }

  @override
  Future<List<Commander>> getRecents() async => _read(_recentsKey);

  @override
  Future<void> addRecent(Commander commander) async {
    final recents = _read(_recentsKey)
      ..removeWhere((c) => _identity(c) == _identity(commander))
      ..insert(0, commander);
    if (recents.length > _maxRecents) {
      recents.removeRange(_maxRecents, recents.length);
    }
    await _write(_recentsKey, recents);
  }

  @override
  Future<List<Commander>> getFavorites() async => _read(_favoritesKey);

  @override
  Future<bool> toggleFavorite(Commander commander) async {
    final favorites = _read(_favoritesKey);
    final existing =
        favorites.indexWhere((c) => _identity(c) == _identity(commander));
    if (existing >= 0) {
      favorites.removeAt(existing);
      await _write(_favoritesKey, favorites);
      return false;
    }
    favorites.insert(0, commander);
    await _write(_favoritesKey, favorites);
    return true;
  }

  @override
  Future<bool> isFavorite(Commander commander) async {
    return _read(_favoritesKey)
        .any((c) => _identity(c) == _identity(commander));
  }
}
