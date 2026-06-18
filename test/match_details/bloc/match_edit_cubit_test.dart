// test/match_details/bloc/match_edit_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

Player _player(String id, String name) => Player(
      id: id,
      name: name,
      playerNumber: 1,
      lifePoints: 40,
      color: 0xFF000000,
      opponents: const [],
      state: PlayerModelState.eliminated,
      placement: 1,
      timeOfDeath: 0,
    );

GameModel _game() => GameModel(
      id: 'game-1',
      players: [_player('p1', 'Alice'), _player('p2', 'Bob')],
      startTime: DateTime(2026, 1, 1),
      endTime: DateTime(2026, 1, 1, 1),
      winnerId: 'p1',
      durationInSeconds: 3600,
    );

const _commander = Commander(
  name: 'Atraxa',
  colors: ['W', 'U', 'B', 'G'],
  cardType: 'Legendary Creature',
  imageUrl: 'img',
  manaCost: '{G}{W}{U}{B}',
  oracleText: 'text',
  artist: 'artist',
);

void main() {
  late FirebaseDatabaseRepository repository;

  setUpAll(() => registerFallbackValue(_game()));

  setUp(() => repository = _MockDatabaseRepository());

  MatchEditCubit build() => MatchEditCubit(
        databaseRepository: repository,
        currentUserId: 'user-1',
      );

  blocTest<MatchEditCubit, MatchEditState>(
    'startEditing seeds the draft and enters editing',
    build: build,
    act: (cubit) => cubit.startEditing(_game()),
    expect: () => [
      isA<MatchEditState>()
          .having((s) => s.status, 'status', MatchEditStatus.editing)
          .having((s) => s.isEditing, 'isEditing', true)
          .having((s) => s.draftPlayers.length, 'draft', 2),
    ],
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'updateName changes only the targeted player',
    build: build,
    act: (cubit) {
      cubit
        ..startEditing(_game())
        ..updateName('p2', 'Bobby');
    },
    verify: (cubit) {
      expect(
        cubit.state.draftPlayers.firstWhere((p) => p.id == 'p2').name,
        'Bobby',
      );
      expect(
        cubit.state.draftPlayers.firstWhere((p) => p.id == 'p1').name,
        'Alice',
      );
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'setCommander updates the targeted player commander',
    build: build,
    act: (cubit) {
      cubit
        ..startEditing(_game())
        ..setCommander('p1', _commander);
    },
    verify: (cubit) {
      expect(
        cubit.state.draftPlayers.firstWhere((p) => p.id == 'p1').commander,
        _commander,
      );
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'setPartner(null) clears the partner',
    build: build,
    act: (cubit) {
      cubit
        ..startEditing(_game())
        ..setPartner('p1', _commander)
        ..setPartner('p1', null);
    },
    verify: (cubit) {
      expect(
        cubit.state.draftPlayers.firstWhere((p) => p.id == 'p1').partner,
        isNull,
      );
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'cancel returns to viewing with an empty draft',
    build: build,
    act: (cubit) {
      cubit
        ..startEditing(_game())
        ..cancel();
    },
    verify: (cubit) {
      expect(cubit.state.status, MatchEditStatus.viewing);
      expect(cubit.state.isEditing, false);
      expect(cubit.state.draftPlayers, isEmpty);
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'save persists the merged game and ends in success',
    setUp: () {
      when(
        () => repository.updateGameStats(
          game: any(named: 'game'),
          playerId: any(named: 'playerId'),
        ),
      ).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      cubit
        ..startEditing(_game())
        ..updateName('p1', 'Alicia');
      await cubit.save();
    },
    verify: (cubit) {
      expect(cubit.state.status, MatchEditStatus.success);
      final captured = verify(
        () => repository.updateGameStats(
          game: captureAny(named: 'game'),
          playerId: 'user-1',
        ),
      ).captured.single as GameModel;
      expect(
        captured.players.firstWhere((p) => p.id == 'p1').name,
        'Alicia',
      );
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'save emits error and preserves the draft when the repository throws',
    setUp: () {
      when(
        () => repository.updateGameStats(
          game: any(named: 'game'),
          playerId: any(named: 'playerId'),
        ),
      ).thenThrow(Exception('network'));
    },
    build: build,
    act: (cubit) async {
      cubit.startEditing(_game());
      await cubit.save();
    },
    verify: (cubit) {
      expect(cubit.state.status, MatchEditStatus.error);
      expect(cubit.state.isEditing, true);
      expect(cubit.state.draftPlayers.length, 2);
    },
  );
}
