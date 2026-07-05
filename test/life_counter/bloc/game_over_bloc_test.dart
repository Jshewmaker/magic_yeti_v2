import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _FakeGameModel extends Fake implements GameModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeGameModel());
  });

  group('GameOverBloc', () {
    late FirebaseDatabaseRepository firebaseDatabaseRepository;

    const basePlayer = Player(
      id: 'p1',
      name: 'Player One',
      playerNumber: 1,
      lifePoints: 40,
      color: 0,
      opponents: [],
      placement: 1,
    );

    final hostLinkedSlot = basePlayer.copyWith(
      id: 'p1',
      firebaseId: () => 'host',
      placement: const Value(1),
    );

    final unlinkedSlot = basePlayer.copyWith(
      id: 'p2',
      firebaseId: () => null,
      placement: const Value(2),
    );

    final linkedFriendSlot = basePlayer.copyWith(
      id: 'p2',
      firebaseId: () => 'friend1',
      placement: const Value(2),
    );

    final gameModel = GameModel(
      players: const [],
      startTime: DateTime(2024),
      endTime: DateTime(2024),
      winnerId: 'p1',
      durationInSeconds: 60,
    );

    setUp(() {
      firebaseDatabaseRepository = _MockFirebaseDatabaseRepository();
      when(() => firebaseDatabaseRepository.saveGameStats(any()))
          .thenAnswer((_) async => 'saved-game-id');
    });

    GameOverBloc buildBloc({
      required List<Player> players,
      required String currentUserId,
    }) {
      return GameOverBloc(
        players: players,
        currentUserId: currentUserId,
        firebaseDatabaseRepository: firebaseDatabaseRepository,
      );
    }

    test('preselects the slot already linked to the current user', () {
      final bloc = buildBloc(
        players: [hostLinkedSlot, unlinkedSlot],
        currentUserId: 'host',
      );
      expect(bloc.state.selectedPlayerId, hostLinkedSlot.id);
    });

    blocTest<GameOverBloc, GameOverState>(
      'never clobbers a slot linked to another account',
      build: () => buildBloc(
        players: [linkedFriendSlot, unlinkedSlot],
        currentUserId: 'host',
      ),
      seed: () => GameOverState(
        standings: [linkedFriendSlot, unlinkedSlot],
        selectedPlayerId: linkedFriendSlot.id,
        firstPlayerId: null,
      ),
      act: (bloc) => bloc.add(
        SendGameOverStatsEvent(gameModel: gameModel, userId: 'host'),
      ),
      verify: (_) {
        final saved = verify(
          () => firebaseDatabaseRepository.saveGameStats(captureAny()),
        ).captured.single as GameModel;
        final slot = saved.players.firstWhere(
          (p) => p.id == linkedFriendSlot.id,
        );
        expect(slot.firebaseId, 'friend1'); // NOT 'host'
      },
    );

    blocTest<GameOverBloc, GameOverState>(
      'notPlayingId assigns the host uid to no slot',
      build: () => buildBloc(
        players: [linkedFriendSlot, unlinkedSlot],
        currentUserId: 'host',
      ),
      seed: () => GameOverState(
        standings: [linkedFriendSlot, unlinkedSlot],
        selectedPlayerId: GameOverBloc.notPlayingId,
        firstPlayerId: null,
      ),
      act: (bloc) => bloc.add(
        SendGameOverStatsEvent(gameModel: gameModel, userId: 'host'),
      ),
      verify: (_) {
        final saved = verify(
          () => firebaseDatabaseRepository.saveGameStats(captureAny()),
        ).captured.single as GameModel;
        expect(saved.players.every((p) => p.firebaseId != 'host'), isTrue);
      },
    );

    blocTest<GameOverBloc, GameOverState>(
      'does not call client-side fan-out',
      build: () => buildBloc(
        players: [unlinkedSlot],
        currentUserId: 'host',
      ),
      seed: () => GameOverState(
        standings: [unlinkedSlot],
        selectedPlayerId: unlinkedSlot.id,
        firstPlayerId: null,
      ),
      act: (bloc) => bloc.add(
        SendGameOverStatsEvent(gameModel: gameModel, userId: 'host'),
      ),
      verify: (_) {
        // syncGameToPlayers no longer exists on the repository; this test
        // asserts the ONLY repository call is saveGameStats.
        verify(() => firebaseDatabaseRepository.saveGameStats(any()))
            .called(1);
        verifyNoMoreInteractions(firebaseDatabaseRepository);
      },
    );
  });
}
