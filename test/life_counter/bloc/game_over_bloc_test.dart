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

    final hostSelfSlot = basePlayer.copyWith(
      id: 'p1',
      firebaseId: () => 'host',
      placement: const Value(1),
    );

    final otherSlot = basePlayer.copyWith(
      id: 'p2',
      firebaseId: () => null,
      placement: const Value(2),
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

    group('props', () {
      test('two states differing only in status are unequal', () {
        const standings = [basePlayer];
        const loading = GameOverState(
          standings: standings,
          selectedPlayerId: null,
          firstPlayerId: null,
          status: GameOverStatus.loading,
        );
        final failure = loading.copyWith(status: GameOverStatus.failure);

        expect(loading, isNot(equals(failure)));
      });

      test('two states differing only in gameModel are unequal', () {
        const standings = [basePlayer];
        const withoutModel = GameOverState(
          standings: standings,
          selectedPlayerId: null,
          firstPlayerId: null,
        );
        final withModel = withoutModel.copyWith(gameModel: gameModel);

        expect(withoutModel, isNot(equals(withModel)));
      });
    });

    group('failure surfacing', () {
      blocTest<GameOverBloc, GameOverState>(
        'emits failure status when saveGameStats throws, without '
        'resetting standings',
        setUp: () {
          when(() => firebaseDatabaseRepository.saveGameStats(any()))
              .thenThrow(Exception('network error'));
        },
        build: () => buildBloc(
          players: [hostSelfSlot, otherSlot],
          currentUserId: 'host',
        ),
        seed: () => GameOverState(
          standings: [hostSelfSlot, otherSlot],
          selectedPlayerId: hostSelfSlot.id,
          firstPlayerId: hostSelfSlot.id,
        ),
        act: (bloc) => bloc.add(
          SendGameOverStatsEvent(gameModel: gameModel, userId: 'host'),
        ),
        expect: () => [
          isA<GameOverState>().having(
            (s) => s.status,
            'status',
            GameOverStatus.loading,
          ),
          isA<GameOverState>()
              .having((s) => s.status, 'status', GameOverStatus.failure)
              .having(
                (s) => s.standings,
                'standings',
                [hostSelfSlot, otherSlot],
              ),
        ],
      );
    });

    group('self-slot unlink', () {
      blocTest<GameOverBloc, GameOverState>(
        'switching selected slot unlinks the old self slot and links '
        'the new one',
        build: () => buildBloc(
          players: [hostSelfSlot, otherSlot],
          currentUserId: 'host',
        ),
        seed: () => GameOverState(
          standings: [hostSelfSlot, otherSlot],
          // User re-selected otherSlot instead of hostSelfSlot.
          selectedPlayerId: otherSlot.id,
          firstPlayerId: otherSlot.id,
        ),
        act: (bloc) => bloc.add(
          SendGameOverStatsEvent(gameModel: gameModel, userId: 'host'),
        ),
        verify: (_) {
          final saved = verify(
            () => firebaseDatabaseRepository.saveGameStats(captureAny()),
          ).captured.single as GameModel;

          final oldSelfSlot = saved.players.firstWhere(
            (p) => p.id == hostSelfSlot.id,
          );
          final newSelfSlot = saved.players.firstWhere(
            (p) => p.id == otherSlot.id,
          );

          expect(oldSelfSlot.firebaseId, isNull);
          expect(newSelfSlot.firebaseId, 'host');
        },
      );

      blocTest<GameOverBloc, GameOverState>(
        'selecting notPlaying unlinks the self slot and no slot has '
        'the uid',
        build: () => buildBloc(
          players: [hostSelfSlot, otherSlot],
          currentUserId: 'host',
        ),
        seed: () => GameOverState(
          standings: [hostSelfSlot, otherSlot],
          selectedPlayerId: GameOverBloc.notPlayingId,
          firstPlayerId: otherSlot.id,
        ),
        act: (bloc) => bloc.add(
          SendGameOverStatsEvent(gameModel: gameModel, userId: 'host'),
        ),
        verify: (_) {
          final saved = verify(
            () => firebaseDatabaseRepository.saveGameStats(captureAny()),
          ).captured.single as GameModel;

          expect(saved.players.every((p) => p.firebaseId != 'host'), isTrue);
          final oldSelfSlot = saved.players.firstWhere(
            (p) => p.id == hostSelfSlot.id,
          );
          expect(oldSelfSlot.firebaseId, isNull);
        },
      );

      blocTest<GameOverBloc, GameOverState>(
        'a foreign-linked slot is never unlinked by this logic',
        build: () => buildBloc(
          players: [linkedFriendSlot, unlinkedSlot],
          currentUserId: 'host',
        ),
        seed: () => GameOverState(
          standings: [linkedFriendSlot, unlinkedSlot],
          selectedPlayerId: unlinkedSlot.id,
          firstPlayerId: unlinkedSlot.id,
        ),
        act: (bloc) => bloc.add(
          SendGameOverStatsEvent(gameModel: gameModel, userId: 'host'),
        ),
        verify: (_) {
          final saved = verify(
            () => firebaseDatabaseRepository.saveGameStats(captureAny()),
          ).captured.single as GameModel;

          final friendSlot = saved.players.firstWhere(
            (p) => p.id == linkedFriendSlot.id,
          );
          expect(friendSlot.firebaseId, 'friend1');
        },
      );

      blocTest<GameOverBloc, GameOverState>(
        'concurrent submit events save exactly once',
        build: () {
          when(() => firebaseDatabaseRepository.saveGameStats(any()))
              .thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return 'doc1';
          });
          return buildBloc(
            players: [hostSelfSlot, otherSlot],
            currentUserId: 'host',
          );
        },
        seed: () => GameOverState(
          standings: [hostSelfSlot, otherSlot],
          selectedPlayerId: hostSelfSlot.id,
          firstPlayerId: hostSelfSlot.id,
        ),
        act: (bloc) => bloc
          ..add(
            SendGameOverStatsEvent(
              gameModel: gameModel,
              userId: 'host',
              exitIntent: GameOverExitIntent.home,
            ),
          )
          ..add(
            SendGameOverStatsEvent(
              gameModel: gameModel,
              userId: 'host',
              exitIntent: GameOverExitIntent.playAgain,
            ),
          ),
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(() => firebaseDatabaseRepository.saveGameStats(any()))
              .called(1);
        },
      );
    });
  });
}
