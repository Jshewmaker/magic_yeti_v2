import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/commander_library/shared_preferences_commander_library_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Commander commander(String name, {String? oracleId}) => Commander(
      oracleId: oracleId,
      name: name,
      colors: const ['U'],
      cardType: 'Legendary Creature',
      imageUrl: 'https://example.com/$name.jpg',
      manaCost: '{U}',
      oracleText: '',
      artist: 'Artist',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesCommanderLibraryRepository repo;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SharedPreferencesCommanderLibraryRepository(prefs);
  }

  setUp(build);

  group('recents', () {
    test('starts empty', () async {
      expect(await repo.getRecents(), isEmpty);
    });

    test('addRecent puts newest first', () async {
      await repo.addRecent(commander('Atraxa', oracleId: 'a'));
      await repo.addRecent(commander('Yuriko', oracleId: 'y'));
      final recents = await repo.getRecents();
      expect(recents.map((c) => c.name), ['Yuriko', 'Atraxa']);
    });

    test('re-adding moves to front without duplicating (dedup by oracleId)',
        () async {
      await repo.addRecent(commander('Atraxa', oracleId: 'a'));
      await repo.addRecent(commander('Yuriko', oracleId: 'y'));
      await repo.addRecent(commander('Atraxa', oracleId: 'a'));
      final recents = await repo.getRecents();
      expect(recents.map((c) => c.name), ['Atraxa', 'Yuriko']);
    });

    test('caps at 20', () async {
      for (var i = 0; i < 25; i++) {
        await repo.addRecent(commander('C$i', oracleId: '$i'));
      }
      final recents = await repo.getRecents();
      expect(recents.length, 20);
      expect(recents.first.name, 'C24');
      expect(recents.last.name, 'C5');
    });

    test('corrupt stored JSON degrades to empty', () async {
      SharedPreferences.setMockInitialValues({'cmdr_lib_recents': 'not json'});
      final prefs = await SharedPreferences.getInstance();
      final r = SharedPreferencesCommanderLibraryRepository(prefs);
      expect(await r.getRecents(), isEmpty);
    });

    test('dedup falls back to name when oracleId is null', () async {
      await repo.addRecent(commander('Proxied Card'));
      await repo.addRecent(commander('Other', oracleId: 'x'));
      await repo.addRecent(commander('Proxied Card'));
      final recents = await repo.getRecents();
      expect(recents.map((c) => c.name), ['Proxied Card', 'Other']);
    });
  });

  group('favorites', () {
    test('toggle adds then removes, reporting new state', () async {
      final atraxa = commander('Atraxa', oracleId: 'a');
      expect(await repo.isFavorite(atraxa), isFalse);

      expect(await repo.toggleFavorite(atraxa), isTrue);
      expect(await repo.isFavorite(atraxa), isTrue);
      expect((await repo.getFavorites()).single.name, 'Atraxa');

      expect(await repo.toggleFavorite(atraxa), isFalse);
      expect(await repo.isFavorite(atraxa), isFalse);
      expect(await repo.getFavorites(), isEmpty);
    });

    test('favorites are independent of recents', () async {
      await repo.addRecent(commander('Yuriko', oracleId: 'y'));
      await repo.toggleFavorite(commander('Atraxa', oracleId: 'a'));
      expect((await repo.getRecents()).single.name, 'Yuriko');
      expect((await repo.getFavorites()).single.name, 'Atraxa');
    });
  });
}
