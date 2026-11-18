import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  late PlayerRepository repo;

  const player = Player(
    id: 'p1',
    name: 'Sarah',
    playerNumber: 0,
    lifePoints: 40,
    color: 0xFF378ADD,
    opponents: [],
    state: PlayerModelState.active,
  );

  const background = Commander(
    name: 'Cult of Rakdos',
    colors: ['B', 'R'],
    cardType: 'Legendary Enchantment — Background',
    imageUrl: 'https://example.com/bg.jpg',
    manaCost: '',
    oracleText: '',
    artist: 'Artist',
  );

  setUpAll(() {
    registerFallbackValue(player);
  });

  setUp(() {
    repo = _MockPlayerRepository();
    when(() => repo.getPlayerById('p1')).thenReturn(player);
    when(() => repo.players).thenAnswer((_) => Stream.value([player]));
    when(() => repo.updatePlayer(any())).thenReturn(null);
  });

  blocTest<PlayerBloc, PlayerState>(
    'UpdatePlayerInfoEvent writes background onto the player',
    build: () => PlayerBloc(playerRepository: repo, playerId: 'p1'),
    act: (bloc) => bloc.add(
      const UpdatePlayerInfoEvent(
        playerId: 'p1',
        playerName: 'Sarah',
        background: background,
      ),
    ),
    verify: (_) {
      final captured =
          verify(() => repo.updatePlayer(captureAny())).captured.last as Player;
      expect(captured.background?.name, 'Cult of Rakdos');
    },
  );
}
