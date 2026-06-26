import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class _MockScryfall extends Mock implements ScryfallRepository {}

class _MockDb extends Mock implements FirebaseDatabaseRepository {}

class _FakeLibrary implements CommanderLibraryRepository {
  final List<Commander> recents = [];
  final List<Commander> favorites = [];
  String _id(Commander c) => c.oracleId ?? c.name;

  @override
  Future<void> addRecent(Commander c) async {
    recents
      ..removeWhere((e) => _id(e) == _id(c))
      ..insert(0, c);
  }

  @override
  Future<List<Commander>> getRecents() async => recents;

  @override
  Future<List<Commander>> getFavorites() async => favorites;

  @override
  Future<bool> isFavorite(Commander c) async =>
      favorites.any((e) => _id(e) == _id(c));

  @override
  Future<bool> toggleFavorite(Commander c) async {
    final i = favorites.indexWhere((e) => _id(e) == _id(c));
    if (i >= 0) {
      favorites.removeAt(i);
      return false;
    }
    favorites.insert(0, c);
    return true;
  }
}

Commander cmdr({
  String name = 'X',
  String? oracleId = 'x',
  List<String> keywords = const [],
  String oracleText = '',
}) =>
    Commander(
      oracleId: oracleId,
      name: name,
      colors: const ['U'],
      cardType: 'Legendary Creature',
      imageUrl: 'https://e/$name.jpg',
      manaCost: '{U}',
      oracleText: oracleText,
      artist: 'A',
      keywords: keywords,
    );

void main() {
  late _MockScryfall scryfall;
  late _MockDb db;
  late _FakeLibrary library;

  PlayerCustomizationBloc build() => PlayerCustomizationBloc(
        scryfallRepository: scryfall,
        firebaseDatabaseRepository: db,
        commanderLibraryRepository: library,
      );

  setUp(() {
    scryfall = _MockScryfall();
    db = _MockDb();
    library = _FakeLibrary();
  });

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'CommanderSelected sets commander, detects partner, records recent',
    build: build,
    act: (b) => b.add(CommanderSelected(cmdr(keywords: ['Partner']))),
    verify: (b) {
      expect(b.state.commander?.name, 'X');
      expect(b.state.availablePairing, CommanderPairing.partner);
      expect(library.recents.single.name, 'X');
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'SecondCardSelected with background pairing fills background, not partner',
    build: build,
    seed: () => PlayerCustomizationState(
      commander: cmdr(oracleText: 'Choose a Background'),
      availablePairing: CommanderPairing.background,
    ),
    act: (b) => b.add(SecondCardSelected(cmdr(name: 'Cult', oracleId: 'c'))),
    verify: (b) {
      expect(b.state.background?.name, 'Cult');
      expect(b.state.partner, isNull);
      expect(b.state.damageClocks, 1);
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'SecondCardSelected with partner pairing fills partner (two clocks)',
    build: build,
    seed: () => PlayerCustomizationState(
      commander: cmdr(keywords: ['Partner']),
      availablePairing: CommanderPairing.partner,
    ),
    act: (b) => b.add(SecondCardSelected(cmdr(name: 'Ally', oracleId: 'al'))),
    verify: (b) {
      expect(b.state.partner?.name, 'Ally');
      expect(b.state.background, isNull);
      expect(b.state.damageClocks, 2);
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'CommanderFavoriteToggled updates favorites + favoriteIds',
    build: build,
    act: (b) => b.add(CommanderFavoriteToggled(cmdr(oracleId: 'fav'))),
    verify: (b) {
      expect(b.state.favoriteIds.contains('fav'), isTrue);
      expect(b.state.favorites.single.oracleId, 'fav');
    },
  );
}
