import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('GameBloc', () {
    late PlayerRepository playerRepository;
    late GameBloc bloc;

    setUp(() {
      playerRepository = PlayerRepository();
      bloc = GameBloc(
        playerRepository: playerRepository,
        database: _MockFirebaseDatabaseRepository(),
      );
    });

    tearDown(() => bloc.close());

    Future<void> createGame(int players, int life) async {
      bloc.add(
        CreateGameEvent(numberOfPlayers: players, startingLifePoints: life),
      );
      await bloc.stream.firstWhere((s) => s.status == GameStatus.running);
    }

    test('a two-player game is not a Commander game', () async {
      await createGame(2, 20);

      expect(bloc.state.playerList, hasLength(2));
      expect(bloc.state.isCommanderGame, isFalse);
    });

    test('a four-player game is a Commander game', () async {
      await createGame(4, 40);

      expect(bloc.state.isCommanderGame, isTrue);
    });

    test('reset emits the reset status, then restores 20 life in a '
        'two-player game', () async {
      await createGame(2, 20);
      final player = playerRepository.getPlayers().first;
      playerRepository.updatePlayer(player.copyWith(lifePoints: 7));

      final reset = bloc.stream.firstWhere(
        (s) => s.status == GameStatus.reset,
      );
      bloc.add(const GameResetEvent());
      await expectLater(reset, completes);
      await bloc.stream.firstWhere((s) => s.status == GameStatus.running);

      expect(
        playerRepository.getPlayers().map((p) => p.lifePoints),
        everyElement(20),
      );
    });
  });
}
