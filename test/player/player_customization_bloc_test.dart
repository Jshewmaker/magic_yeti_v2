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

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'LibraryRequested loads recents and favorites into state',
    build: build,
    setUp: () {
      library.recents.add(cmdr(name: 'Rec', oracleId: 'r'));
      library.favorites.add(cmdr(name: 'Fav', oracleId: 'f'));
    },
    act: (b) => b.add(const LibraryRequested()),
    verify: (b) {
      expect(b.state.recents.single.name, 'Rec');
      expect(b.state.favorites.single.name, 'Fav');
      expect(b.state.favoriteIds.contains('f'), isTrue);
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'CommanderSelected clears a previously selected partner and background',
    build: build,
    seed: () => PlayerCustomizationState(
      commander: cmdr(name: 'Old', oracleId: 'old'),
      partner: cmdr(name: 'P', oracleId: 'p'),
      background: cmdr(name: 'B', oracleId: 'b'),
      availablePairing: CommanderPairing.partner,
    ),
    act: (b) => b.add(CommanderSelected(cmdr(name: 'New', oracleId: 'new'))),
    verify: (b) {
      expect(b.state.commander?.name, 'New');
      expect(b.state.partner, isNull);
      expect(b.state.background, isNull);
      expect(b.state.damageClocks, 1);
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'SecondCardSelected (background pairing) records the card as a recent',
    build: build,
    seed: () => PlayerCustomizationState(
      commander: cmdr(
        name: 'Cmd',
        oracleId: 'c',
        oracleText: 'Choose a Background',
      ),
      availablePairing: CommanderPairing.background,
    ),
    act: (b) => b.add(SecondCardSelected(cmdr(name: 'Cult', oracleId: 'cult'))),
    verify: (b) {
      expect(b.state.background?.name, 'Cult');
      expect(library.recents.first.name, 'Cult');
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'SecondCardCleared clears both partner and background',
    build: build,
    seed: () => PlayerCustomizationState(
      commander: cmdr(name: 'Cmd', oracleId: 'c'),
      partner: cmdr(name: 'P', oracleId: 'p'),
      availablePairing: CommanderPairing.partner,
    ),
    act: (b) => b.add(const SecondCardCleared()),
    verify: (b) {
      expect(b.state.partner, isNull);
      expect(b.state.background, isNull);
    },
  );

  group('ValidatePin', () {
    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits isPinValidating true, then pinValidated on PinValid',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '0742',
          ),
        ).thenAnswer((_) async => const PinValid());
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', true),
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having((s) => s.pinValidated, 'pinValidated', true)
            .having((s) => s.pinFlowError, 'pinFlowError', PinFlowError.none),
      ],
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits incorrect with attemptsRemaining on PinInvalid',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '9999',
          ),
        ).thenAnswer((_) async => const PinInvalid(attemptsRemaining: 2));
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '9999', friendUserId: 'friend1')),
      skip: 1,
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having((s) => s.pinValidated, 'pinValidated', false)
            .having(
              (s) => s.pinFlowError,
              'pinFlowError',
              PinFlowError.incorrect,
            )
            .having((s) => s.pinAttemptsRemaining, 'attempts', 2),
      ],
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits lockedOut with expiry on PinLockedOut',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '9999',
          ),
        ).thenAnswer(
          (_) async => PinLockedOut(lockedUntil: DateTime(2026, 7, 3, 12)),
        );
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '9999', friendUserId: 'friend1')),
      skip: 1,
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having(
              (s) => s.pinFlowError,
              'pinFlowError',
              PinFlowError.lockedOut,
            )
            .having(
              (s) => s.pinLockedUntil,
              'lockedUntil',
              DateTime(2026, 7, 3, 12),
            ),
      ],
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits unavailable on PinCheckUnavailable',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '0742',
          ),
        ).thenAnswer((_) async => const PinCheckUnavailable());
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
      skip: 1,
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having(
              (s) => s.pinFlowError,
              'pinFlowError',
              PinFlowError.unavailable,
            ),
      ],
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits notSet on PinNotSet',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '0742',
          ),
        ).thenAnswer((_) async => const PinNotSet());
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
      skip: 1,
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having(
              (s) => s.pinFlowError,
              'pinFlowError',
              PinFlowError.notSet,
            ),
      ],
    );
  });

  group('ResetPinFlow', () {
    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'clears error/attempts/lockout but preserves pinValidated',
      build: build,
      seed: () => PlayerCustomizationState(
        pinFlowError: PinFlowError.lockedOut,
        pinLockedUntil: DateTime(2026, 7, 3, 12),
        pinValidated: true,
      ),
      act: (bloc) => bloc.add(const ResetPinFlow()),
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.pinFlowError, 'pinFlowError', PinFlowError.none)
            .having(
              (s) => s.pinAttemptsRemaining,
              'pinAttemptsRemaining',
              0,
            )
            .having((s) => s.pinLockedUntil, 'pinLockedUntil', isNull)
            .having((s) => s.pinValidated, 'pinValidated', isTrue),
      ],
    );
  });

  group('OwnerSelected', () {
    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'confirms isAccountOwner and clears any existing friend selection',
      build: () {
        when(() => db.getUserProfileOnce('alice'))
            .thenAnswer((_) async => null);
        return build();
      },
      seed: () => PlayerCustomizationState(
        selectedFriend: const FriendModel(
          userId: 'bob',
          username: 'Bob',
          profilePictureUrl: '',
        ),
        pinValidated: true,
      ),
      act: (bloc) => bloc.add(const OwnerSelected(userId: 'alice')),
      verify: (bloc) {
        expect(bloc.state.isAccountOwner, isTrue);
        expect(bloc.state.selectedFriend, isNull);
        expect(bloc.state.pinValidated, isFalse);
      },
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'fetches and stores the owner username',
      build: () {
        when(() => db.getUserProfileOnce('alice')).thenAnswer(
          (_) async => const UserProfileModel(id: 'alice', username: 'Alice'),
        );
        return build();
      },
      act: (bloc) => bloc.add(const OwnerSelected(userId: 'alice')),
      verify: (bloc) {
        expect(bloc.state.ownerUsername, 'Alice');
      },
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'leaves ownerUsername unset if the profile fetch returns null',
      build: () {
        when(() => db.getUserProfileOnce('alice'))
            .thenAnswer((_) async => null);
        return build();
      },
      act: (bloc) => bloc.add(const OwnerSelected(userId: 'alice')),
      verify: (bloc) {
        expect(bloc.state.ownerUsername, isNull);
      },
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'still confirms isAccountOwner if the profile fetch throws',
      build: () {
        when(() => db.getUserProfileOnce('alice'))
            .thenThrow(Exception('offline'));
        return build();
      },
      act: (bloc) => bloc.add(const OwnerSelected(userId: 'alice')),
      verify: (bloc) {
        expect(bloc.state.isAccountOwner, isTrue);
        expect(bloc.state.ownerUsername, isNull);
      },
    );
  });

  group('SelectFriend', () {
    const bob = FriendModel(
      userId: 'bob',
      username: 'Bob',
      profilePictureUrl: '',
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'confirms the friend as validated and clears isAccountOwner',
      build: build,
      seed: () => const PlayerCustomizationState(isAccountOwner: true),
      act: (bloc) => bloc.add(const SelectFriend(friend: bob)),
      verify: (bloc) {
        expect(bloc.state.selectedFriend, bob);
        expect(bloc.state.pinValidated, isTrue);
        expect(bloc.state.isAccountOwner, isFalse);
      },
    );
  });

  group('LinkCleared', () {
    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'clears both a friend link and owner status',
      build: build,
      seed: () => const PlayerCustomizationState(isAccountOwner: true),
      act: (bloc) => bloc.add(const LinkCleared()),
      verify: (bloc) {
        expect(bloc.state.isAccountOwner, isFalse);
        expect(bloc.state.selectedFriend, isNull);
        expect(bloc.state.pinValidated, isFalse);
      },
    );
  });
}
